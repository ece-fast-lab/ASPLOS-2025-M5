#ifndef CXL_MIGRATE_H
#define CXL_MIGRATE_H

#include <linux/mm.h>
#include <linux/percpu.h>
#include <linux/timekeeping.h>

#define cxl_stat_items \
	_CXL(cxl_precheck_time) \
	_CXL(cxl_find_target_time) \
	_CXL(cxl_locking_time) \
	_CXL(cxl_get_pte_time) \
	_CXL(cxl_check_pte_time) \
	_CXL(cxl_migrate_done_time) \
	\
	_CXL(cxl_invoke_cnt) \
	_CXL(cxl_inval_pfn_cnt) \
	_CXL(cxl_same_node_cnt) \
	_CXL(cxl_rmap_fail_cnt) \
	_CXL(cxl_follow_retry_cnt) \
	_CXL(cxl_follow_fail_cnt) \
	_CXL(cxl_abnormal_page_cnt) \
	_CXL(cxl_compound_page_cnt) \
	_CXL(cxl_bad_policy_cnt) \
	_CXL(cxl_policy_skip_cnt) \
	_CXL(cxl_migrate_fail_cnt) \
	_CXL(cxl_success_cnt) \
	\
	_CXL(migrate_isolate_time) \
	_CXL(migrate_return_time) \
	_CXL(migrate_succ_cnt) \
	_CXL(migrate_fail_cnt) \


#define _CXL(x) u64 x;
struct cxl_stat
{
	u64 start;
	cxl_stat_items
};
#undef _CXL

DECLARE_PER_CPU(struct cxl_stat, cxl_stats);

#define cxl_start_stat() \
	do { \
		struct cxl_stat *p = this_cpu_ptr(&cxl_stats); \
		p->start = ktime_get_ns(); \
	} while (0)

#define cxl_do_timing(item) \
	do { \
		struct cxl_stat *p = this_cpu_ptr(&cxl_stats); \
		u64 cur_time = ktime_get_ns(); \
		p->item += cur_time - p->start; \
	} while (0)

#define cxl_do_counting(item) \
	do { \
		struct cxl_stat *p = this_cpu_ptr(&cxl_stats); \
		p->item++; \
	} while (0)

static inline void print_cxl_stats_cpu(int cpu)
{
	struct cxl_stat *p = per_cpu_ptr(&cxl_stats, cpu);

#define _CXL(x) #x ": %llu, "
	const char fmt[] = KERN_WARNING cxl_stat_items "(on CPU %d)";
#undef _CXL

#define _CXL(x) p->x,
	printk(fmt, cxl_stat_items smp_processor_id());
#undef _CXL
}

static inline void print_cxl_stats(void)
{
	int cpu = 0;

	for_each_online_cpu(cpu) {
		print_cxl_stats_cpu(cpu);
	}
}

static inline void reset_cxl_stats(void)
{
	int cpu = 0;

	print_cxl_stats();

	for_each_online_cpu(cpu) {
		struct cxl_stat *p = per_cpu_ptr(&cxl_stats, cpu);

		memset(p, 0, sizeof(struct cxl_stat));
	}
}

#endif // CXL_MIGRATE_H
