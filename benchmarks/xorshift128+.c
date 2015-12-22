#include "bench.h"

uint64_t state0 = 1;
uint64_t state1 = 2;

uint64_t xorshift128plus()
{
  uint64_t s1 = state0;
  uint64_t s0 = state1;
  state0 = s0;
  s1 ^= s1 << 23;
  s1 ^= s1 >> 17;
  s1 ^= s0;
  s1 ^= s0 >> 26;
  state1 = s1;
  return state0 + state1;
}

int main(int argc, char** argv)
{
  uint64_t t1, t2;
  t1 = ticks();
  for (int i = 0; i < 10000000; i++)
    xorshift128plus();
  t2 = ticks();
  printf("%ld ms\n", t2 - t1);
  printf("state0 = %lu\n", state0);
  printf("state1 = %lu\n", state1);
}

// gcc xorshift128+.c -o xorshift128+
