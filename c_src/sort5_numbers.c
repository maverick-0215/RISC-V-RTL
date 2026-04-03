// Sort five numbers in ascending order and write output to 0x100..0x110.

int main(void) {
    asm volatile("li sp, 1024");

    int a[5] = {23, 7, 31, 4, 18};
    int i;
    int j;

    for (i = 0; i < 4; i++) {
        for (j = 0; j < 4 - i; j++) {
            if (a[j] > a[j + 1]) {
                int t = a[j];
                a[j] = a[j + 1];
                a[j + 1] = t;
            }
        }
    }

    // For integration testing: write sorted outputs to data memory.
    *((volatile int *)0x100) = a[0];
    *((volatile int *)0x104) = a[1];
    *((volatile int *)0x108) = a[2];
    *((volatile int *)0x10C) = a[3];
    *((volatile int *)0x110) = a[4];

    while (1) {
        // Hold for simple bare-metal simulation.
    }

    return 0;
}
