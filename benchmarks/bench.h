#include <stdint.h>
#include <stdio.h>
#include <sys/time.h>

uint64_t ticks()
{
  struct timeval tv;
  if(gettimeofday(&tv, NULL) != 0)
    return 0;
  return (tv.tv_sec * 1000) + (tv.tv_usec / 1000);
}
