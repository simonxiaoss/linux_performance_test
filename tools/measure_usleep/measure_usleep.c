#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/delay.h>
#include <linux/kthread.h>

#define SLEEP_TIME_MS		500
#define DEFAULT_ITERATIONS	1000
#define ONE_MINUTE		60000000

int iterations = 1000;
module_param(iterations, int, S_IRUGO);
MODULE_PARM_DESC(iterations, "Number of test iterations (Default: 1000).");

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Simon Xiao");
MODULE_DESCRIPTION("A usleep test module for Linux");

#if defined(__i386__)
static __inline__ unsigned long long get_cc_rdtsc(void)
{
	unsigned long long int c;
	__asm__ volatile (".byte 0x0f, 0x31" : "=A" (c));
	return c;
}

#elif defined(__x86_64__)
static __inline__ unsigned long long get_cc_rdtsc(void)
{
	unsigned hi, lo;
	__asm__ __volatile__ ("rdtsc" : "=a"(lo), "=d"(hi));
	return ( (unsigned long long)lo)|( ((unsigned long long)hi)<<32 );
}
#endif

static struct task_struct *kthread;
static int work_func(void *data)
{
	int i;
	uint64_t init_cycle, final_cycle;
	uint64_t cur_value, max_value = 0, min_value = ONE_MINUTE;
	uint64_t total_value = 0, avg_value = 0;

	if (iterations < 1) {
		iterations = DEFAULT_ITERATIONS;
		printk(KERN_INFO "TEST USLEEP: Set iterations = %d\n", DEFAULT_ITERATIONS);
	}

	for(i = 0; i < iterations; i++) {
		init_cycle = get_cc_rdtsc();
		usleep_range(SLEEP_TIME_MS, SLEEP_TIME_MS + 1);
		//udelay(SLEEP_TIME_MS);
		final_cycle = get_cc_rdtsc();

		cur_value = final_cycle - init_cycle;
		if (cur_value > max_value)
			max_value = cur_value;
		if (cur_value < min_value)
			min_value = cur_value;
		total_value += cur_value;

		printk(KERN_INFO "TEST USLEEP [%d]: %llu\n", i, cur_value);
	}

	if (i > 0)
		avg_value = total_value / i; 
	else
		avg_value = 0;

	printk(KERN_INFO "TEST USLEEP SUMMARY: [max]: %llu; [min]: %llu; [avg]: %llu\n",
		max_value, min_value, avg_value);	
	return 0;
}


static int __init hello_init(void)
{
	printk(KERN_INFO "TEST USLEEP: Initilize module.\n");

	kthread = kthread_create(work_func, NULL, "the test thread");
	wake_up_process(kthread);

	return 0;
}

static void __exit hello_cleanup(void)
{
	printk(KERN_INFO "TEST USLEEP: Cleaning up module.\n");
}

module_init(hello_init);
module_exit(hello_cleanup);
