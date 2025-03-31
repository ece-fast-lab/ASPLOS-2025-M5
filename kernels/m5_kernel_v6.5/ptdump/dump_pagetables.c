/*
 * Debug helper to dump the current kernel nested EPT pagetables of the system
 * so that we can see what the various memory ranges are set to.
 *
 * (C) Copyright 2024 Jiyuan Zhang
 *
 * Author: Jiyuan Zhang <jiyuanz3@illinois.edu>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; version 2
 * of the License.
 */

#include <linux/proc_fs.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/seq_file.h>
#include <linux/sort.h>
#include <linux/slab.h>
#include <linux/sched.h>
#include <linux/sched/mm.h>
#include <linux/security.h>
#include <linux/kvm_host.h>
#include <linux/ptrace.h>
#include <linux/kprobes.h>

#include <asm/pgtable.h>
#include <asm/pgtable_64.h>

//
// Globals
//

#define is_default_mode() (selected_mode == '0')
#define is_userspace_mode() (selected_mode == 'U')

// For all modes
static pid_t selected_pid = 1;
static char selected_mode = '0';

enum {
	PGD_LVL,
	P4D_LVL,
	PUD_LVL,
	PMD_LVL,
	PTE_LVL,
};

static inline int pgd_young(pgd_t pgd)
{
	return pgd_flags(pgd) & _PAGE_ACCESSED;
}

static inline int p4d_young(p4d_t p4d)
{
	return p4d_flags(p4d) & _PAGE_ACCESSED;
}

static inline pgd_t pgd_clear_flags(pgd_t pgd, pgdval_t clear)
{
	pgdval_t v = native_pgd_val(pgd);

	return native_make_pgd(v & ~clear);
}

static inline pgd_t pgd_mkold(pgd_t pgd)
{
	return pgd_clear_flags(pgd, _PAGE_ACCESSED);
}

static inline p4d_t p4d_clear_flags(p4d_t p4d, p4dval_t clear)
{
	p4dval_t v = native_p4d_val(p4d);

	return native_make_p4d(v & ~clear);
}

static inline p4d_t p4d_mkold(p4d_t p4d)
{
	return p4d_clear_flags(p4d, _PAGE_ACCESSED);
}

static void print_entry(struct seq_file *s, pgd_t *root, ulong va, pgd_t *pgd, p4d_t *p4d, pud_t *pud, pmd_t *pmd, pte_t *pte, int level)
{
	bool pgda = 0, p4da = 0, puda = 0, pmda = 0, ptea = 0;
	ulong pa;
	char *desc;

	if (pgd) {
		pgda = pgd_young(*pgd);
		if (level == PGD_LVL)
			*pgd = pgd_mkold(*pgd);
		pa = pgd_pfn(*pgd);
	}
	if (p4d) {
		p4da = p4d_young(*p4d);
		if (level == P4D_LVL)
			*p4d = p4d_mkold(*p4d);
		pa = p4d_pfn(*p4d);
	}
	if (pud) {
		puda = pud_young(*pud);
		if (level >= PUD_LVL)
			*pud = pud_mkold(*pud);
		pa = pud_pfn(*pud);
	}
	if (pmd) {
		pmda = pmd_young(*pmd);
		if (level >= PMD_LVL)
			*pmd = pmd_mkold(*pmd);
		pa = pmd_pfn(*pmd);
	}
	if (pte) {
		ptea = pte_young(*pte);
		if (level >= PTE_LVL)
			*pte = pte_mkold(*pte);
		pa = pte_pfn(*pte);
	}

	// Do not print unmapped pages
	if (!pa)
		return;

	switch(level) {
		case PGD_LVL: desc = "PGD"; break;
		case P4D_LVL: desc = "P4D"; break;
		case PUD_LVL: desc = "PUD"; break;
		case PMD_LVL: desc = "PMD"; break;
		case PTE_LVL: desc = "PTE"; break;
		default: desc = "BAD"; break;
	}

	seq_printf(s, "%016lx,%d,%d,%d,%d,%d,%lx,%s\n", va, pgda, p4da, puda, pmda, ptea, pa, desc);
}

//
// Process Table Walker
//

static void handle_normal_page(struct seq_file *s, pgd_t *root, ulong *paddr, pgd_t *pgd, p4d_t *p4d, pud_t *pud, pmd_t *pmd, pte_t *pte, int level)
{
	ulong addr = *paddr;

	switch(level) {
	case PGD_LVL: {
		print_entry(s, root, addr, pgd, p4d, pud, pmd, pte, level);
		*paddr += PGDIR_SIZE;
		return;
	}

	case P4D_LVL: {
		print_entry(s, root, addr, pgd, p4d, pud, pmd, pte, level);
		*paddr += P4D_SIZE;
		return;
	}

	case PUD_LVL: {
		print_entry(s, root, addr, pgd, p4d, pud, pmd, pte, level);
		*paddr += PUD_SIZE;
		return;
	}

	case PMD_LVL: {
		print_entry(s, root, addr, pgd, p4d, pud, pmd, pte, level);
		*paddr += PMD_SIZE;
		return;
	}

	default: {
		WARN_ONCE(1, "Invalid huge level\n");
		return;
	}
	}
}

static pte_t *__pte_offset_map2(pmd_t *pmd, unsigned long addr, pmd_t *pmdvalp)
{
	pmd_t pmdval;

	/* rcu_read_lock() to be added later */
	pmdval = pmdp_get_lockless(pmd);
	if (pmdvalp)
		*pmdvalp = pmdval;
	if (unlikely(pmd_none(pmdval)))
		goto nomap;
	if (unlikely(pmd_trans_huge(pmdval) || pmd_devmap(pmdval)))
		goto nomap;
	if (unlikely(pmd_bad(pmdval))) {
		goto nomap;
	}
	return __pte_map(&pmdval, addr);
nomap:
	/* rcu_read_unlock() to be added later */
	return NULL;
}

static inline pte_t *pte_offset_map2(pmd_t *pmd, unsigned long addr)
{
	return __pte_offset_map2(pmd, addr, NULL);
}

static void normal_table_walker(struct seq_file *s, unsigned long *paddr, pgd_t *root)
{
	unsigned long addr = *paddr;
	unsigned long step = PAGE_SIZE;
	unsigned long pgdp = 0, p4dp = 0, pudp = 0, pmdp = 0, ptep = 0;

	pgd_t *pgd = NULL;
	p4d_t *p4d = NULL;
	pud_t *pud = NULL;
	pmd_t *pmd = NULL;
	pte_t *pte = NULL;

	pgd = pgd_offset_pgd(root, addr);

	if (pgd && !pgd_none(*pgd)) {
		pgdp = pgd_pfn(*pgd);

		if (pgd_leaf(*pgd))
			return handle_normal_page(s, root, paddr, pgd, p4d, pud, pmd, pte, PGD_LVL);

		if (!pgd_bad(*pgd))
			p4d = p4d_offset(pgd, addr);
	}
	if (p4d && !p4d_none(*p4d)) {
		p4dp = p4d_pfn(*p4d);

		if (p4d_leaf(*p4d))
			return handle_normal_page(s, root, paddr, pgd, p4d, pud, pmd, pte, P4D_LVL);

		if (!p4d_bad(*p4d))
			pud = pud_offset(p4d, addr);
	}
	if (pud && !pud_none(*pud)) {
		pudp = pud_pfn(*pud);

		if (pud_leaf(*pud))
			return handle_normal_page(s, root, paddr, pgd, p4d, pud, pmd, pte, PUD_LVL);

		if (!pud_bad(*pud))
			pmd = pmd_offset(pud, addr);
	}
	if (pmd && !pmd_none(*pmd)) {
		pmdp = pmd_pfn(*pmd);

		if (pmd_leaf(*pmd))
			return handle_normal_page(s, root, paddr, pgd, p4d, pud, pmd, pte, PMD_LVL);

		if (!pmd_bad(*pmd))
			pte = pte_offset_map2(pmd, addr);
	}
	if (pte && !pte_none(*pte)) {
		if (pte_present(*pte))
			ptep = pte_pfn(*pte);
		pte_unmap(pte);
	}

	if (!ptep) { step = PAGE_SIZE; }
	if (!pmdp) { step = PMD_SIZE; }
	if (!pudp) { step = PUD_SIZE; }
	if (!p4dp) { step = P4D_SIZE; }
	if (!pgdp) { step = PGDIR_SIZE; }

	if (pte)
		print_entry(s, root, addr, pgd, p4d, pud, pmd, pte, PTE_LVL);

	*paddr += step;
}

//
// Proc File
//

static struct mm_struct *get_mm_from_pid(pid_t pid)
{
	struct task_struct *task;
	struct mm_struct *mm;

	task = pid_task(find_vpid(pid), PIDTYPE_PID);
	if (!task) {
		return NULL;
	}

	mm = get_task_mm(task);

	if (!mm) {
		return NULL;
	}

	return mm;
}

static int pt_seq_show(struct seq_file *s, void *v)
{
	ulong *spos = v;
	struct mm_struct *mm = NULL;

	if (!*spos) {
		pr_warn(
			"Dumping %s page table for process %d\n", 
			is_userspace_mode() ? "user" : "all",
			selected_pid
		);

		seq_printf(s, "%16d\n", selected_pid);
		seq_printf(s, "VA,PGD_ACC,P4D_ACC,PUD_ACC,PMD_ACC,PTE_ACC,PA,ENT_TYPE\n");
	}

	mm = get_mm_from_pid(selected_pid);

	if (!mm) {
		seq_printf(s, "Cannot access mm_struct for %d\n", selected_pid);
		return -EINVAL;
	}

	normal_table_walker(s, spos, mm->pgd);

	mmput(mm);

	return 0;
}

static void *pt_seq_start(struct seq_file *s, loff_t *pos)
{
	loff_t *spos;

	// Do not restart terminated sequence
	if (*pos == -1UL)
		return NULL;

	spos = kmalloc(sizeof(loff_t), GFP_KERNEL);
	if (!spos)
		return NULL;

	*spos = *pos;
	return spos;
}

static void *pt_seq_next(struct seq_file *s, void *v, loff_t *pos)
{
	loff_t *spos = v;
	ulong sposv = *spos;
	ulong posv = *pos;

	// Stall or overflow
	if (sposv <= posv)
		goto terminate;

	// No need to go beyond
	// if (is_vmroot_mode() && sposv >= EPT_PHYS_MAX)
	// 	goto terminate;

	// Go past user space
	if (sposv >= TASK_SIZE_MAX) {
		if (is_userspace_mode())
			goto terminate;

		// Jump to kernel space
		if (sposv < PAGE_OFFSET)
			*spos = PAGE_OFFSET;
	}

	*pos = *spos;

	return spos;

terminate:
	*spos = -1UL;
	*pos = -1UL;
	return NULL;
}

static void pt_seq_stop(struct seq_file *s, void *v)
{
	kfree(v);
}

ssize_t pt_write(struct file *file, const char __user *buf, size_t count, loff_t *ppos)
{
	char mybuf[65];
	char *myptr = mybuf;
	size_t mylen = sizeof(mybuf) - 1;

	if (count < mylen) {
		mylen = count;
	}

	if (!mylen)
		return count;

	if (copy_from_user(myptr, buf, mylen))
		return -1;

	myptr[mylen] = '\0';

	selected_mode = myptr[0];
	if (selected_mode < '0' || '9' < selected_mode) {
		myptr++;
		mylen--;

		if (!mylen)
			return count;
	}
	else {
		selected_mode = '0';
	}

	if (kstrtoint(myptr, 10, &selected_pid)) {
		pr_warn("Unable to parse PID %s\n", myptr);
		selected_pid = current->pid;
	}

	return count;
}

static struct seq_operations pt_seq_ops = {
	.start = pt_seq_start,
	.next  = pt_seq_next,
	.stop  = pt_seq_stop,
	.show  = pt_seq_show,
};

static int pt_open(struct inode *inode, struct file *file)
{
	return seq_open(file, &pt_seq_ops);
};

static struct proc_ops pt_file_ops = {
	.proc_open    = pt_open,
	.proc_read    = seq_read,
	.proc_write   = pt_write,
	.proc_lseek   = seq_lseek,
	.proc_release = seq_release
};

//
// Module Manager
//

int init_module_dumper(void)
{
	struct proc_dir_entry *pt_file = proc_create("page_tables", 0666, NULL, &pt_file_ops);
	if (!pt_file)
		return -ENOMEM;

	return 0;
}

void cleanup_module_dumper(void)
{
	remove_proc_entry("page_tables", NULL);
}

late_initcall(init_module_dumper)
module_exit(cleanup_module_dumper)

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Jiyuan Zhang <jiyuanz3@illinois.edu>");
MODULE_DESCRIPTION("Kernel debugging helper that dumps nested EPT pagetables");
