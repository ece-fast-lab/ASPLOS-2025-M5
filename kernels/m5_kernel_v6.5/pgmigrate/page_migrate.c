/*
 * (C) Copyright 2024 Jiyuan Zhang
 *
 * Author: Jiyuan Zhang <jiyuanz3@illinois.edu>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; version 2
 * of the License.
 */

#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt

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
#include <linux/cxl_migrate.h>

//
// Globals
//

static int node = 0;

ssize_t proc_write_node(struct file *file, const char __user *buf, size_t count, loff_t *ppos)
{
	char mybuf[65] = { 0 };
	char *myptr = mybuf;
	size_t mylen = sizeof(mybuf) - 1;

	if (!count)
		return 0;

	if (count > mylen)
		return -EINVAL;

	if (copy_from_user(myptr, buf, count))
		return -EFAULT;

	if (kstrtoint(myptr, 10, &node)) {
		pr_warn("Unable to parse Node ID %s, current value is %d\n", myptr, node);
		return -EINVAL;
	}

	pr_warn("Node ID set to %d\n", node);

	reset_cxl_stats();

	return count;
}

static ssize_t proc_read_node(struct file *file, char __user *buf, size_t count, loff_t *ppos)
{
	char mybuf[65];

	print_cxl_stats();

	sprintf(mybuf, "%d\n", node);
	return simple_read_from_buffer(buf, count, ppos, mybuf, strlen(mybuf));
}

static struct proc_ops node_file_ops = {
	.proc_read	= proc_read_node,
	.proc_write	= proc_write_node,
	.proc_lseek	= noop_llseek,
};

ssize_t proc_write_pfn(struct file *file, const char __user *buf, size_t count, loff_t *ppos)
{
	char mybuf[65] = { 0 };
	char *myptr = mybuf;
	size_t mylen = sizeof(mybuf) - 1;
	u64 pfn = 0;
	int ret = 0;

	if (!count)
		return 0;

	if (count > mylen)
		return -EINVAL;

	if (copy_from_user(myptr, buf, count))
		return -EFAULT;

	if (kstrtoull(myptr, 16, &pfn)) {
		pr_warn("Unable to parse PFN value %s\n", myptr);
		return -EINVAL;
	}

	pr_warn("Migrating PFN %llx to node %d\n", pfn, node);
	ret = cxl_numa_migrate(pfn, node);

	return count;
}

static struct proc_ops pfn_file_ops = {
	.proc_write	= proc_write_pfn,
	.proc_lseek	= noop_llseek,
};

//
// Module Manager
//

int init_module_migrater(void)
{
	struct proc_dir_entry *node_file;
	struct proc_dir_entry *pfn_file;

	node_file = proc_create("cxl_migrate_node", 0666, NULL, &node_file_ops);
	if (!node_file)
		return -ENOMEM;

	pfn_file = proc_create("cxl_migrate_pfn", 0666, NULL, &pfn_file_ops);
	if (!pfn_file) {
		remove_proc_entry("cxl_migrate_node", NULL);
		return -ENOMEM;
	}

	return 0;
}

void cleanup_module_migrater(void)
{
	remove_proc_entry("cxl_migrate_pfn", NULL);
	remove_proc_entry("cxl_migrate_node", NULL);
}

late_initcall(init_module_migrater)
module_exit(cleanup_module_migrater)

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Jiyuan Zhang <jiyuanz3@illinois.edu>");
