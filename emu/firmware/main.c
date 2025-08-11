
#include "soc.h"

void fail(void)
{
  uint16_t i;

  while(1)
  {
    GPIO = 0x01;
    for (i=0; i<10; i++)
      asm volatile ("addi x0, x0, 1");

    GPIO = 0x00;
    for (i=0; i<1000; i++)
      asm volatile ("addi x0, x0, 1");
  }
}

void pass(void)
{
  uint32_t i;

  while(1)
  {
    GPIO = 0x01;
    for (i=0; i<100000; i++)
      asm volatile ("addi x0, x0, 1");

    GPIO = 0x00;
    for (i=0; i<100000; i++)
      asm volatile ("addi x0, x0, 1");
  }
}


uint8_t ones(uint32_t n) {
  uint8_t count = 0;
  while (n) {
      count += n & 1;
      n >>= 1;
  }
  return count;
}


void gpio(void)
{
  uint32_t i;

  uint32_t g;
  uint32_t dly;
  uint32_t masked;
  uint32_t temp_gpi;
  
  while(1)
  {
    temp_gpi = GPI;
    
    // force AND instruction to smoke-test CCX
    // with modifed decoder (defined SMOKETEST_CCX).
    register unsigned int mask asm("t1") = 0x00FF;
    asm volatile (
      "and %0, %1, %2\n"
      : "=r" (masked)
      : "r" (temp_gpi), "r" (mask)
    );

    g = ones(masked);
    dly = 10000 * (uint32_t)g;

    g = ones(GPI & 0x00FF);
    dly = 10000 * (uint32_t)g;

    GPIO = 0x01;
    for (i=0; i<dly; i++)
      asm volatile ("addi x0, x0, 1");

    GPIO = 0x00;
    for (i=0; i<dly; i++)
      asm volatile ("addi x0, x0, 1");
  }
}



void main(void)
{
  //while(1);
  gpio();
  //pass();
}
