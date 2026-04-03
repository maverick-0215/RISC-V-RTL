// Writes final result to memory-mapped location 0x100.

#if defined(__GNUC__)
#define NOINLINE __attribute__((noinline))
#else
#define NOINLINE
#endif

static NOINLINE int max(int a, int b) {
    return (a > b) ? a : b;
}

//declaring as volatile prevents the compiler to apply optimizations

int main(void) {
    asm volatile("li sp, 1024");

    volatile int v1 = 14;
    volatile int v2 = 27;
    volatile int v3 = 9;
    volatile int v4 = 31;
    volatile int v5 = 18;

    int cur = max(v1, v2);
    cur = max(cur, v3);
    cur = max(cur, v4);
    cur = max(cur, v5);

    // For integration testing: data memory byte address 0x100 (word index 64)
    *((volatile int *)0x100) = cur;

    while (1) {
        //as we don't have an OS on top of our processor, this loop prevents returning to OS
    }

    return 0;
}
