// Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#ifndef WIN64
#include <unistd.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/stat.h>
#ifdef WIN64
#include <windows.h>
#else
#include <sys/mman.h>
#include <sys/time.h>
#endif

extern void cold();

int main(int argc, char **argv, char **env)
{
  extern uint64_t dp_data;
  extern uint64_t cp_data;
  extern uint64_t limit_data;
  extern uint64_t tick_syspad_data;
  extern uint64_t tick_tib_data;
  extern uint64_t s0_data;
  extern uint64_t tick_tick_word_data;
  uint64_t data_space_size = 1024 * 1024;
  uint64_t code_space_size = 1024 * 1024;
  void * data_space;
  void * code_space;
#ifdef WIN64
  data_space =
    VirtualAlloc(0, data_space_size, MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE);
  code_space =
    VirtualAlloc(0, code_space_size, MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE);
#else
  data_space =
    mmap((void *)0x1000000, data_space_size, PROT_EXEC|PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE|MAP_NORESERVE, -1, 0);
  code_space =
    mmap((void *)0x2000000, code_space_size, PROT_EXEC|PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE|MAP_NORESERVE, -1, 0);
#endif
  dp_data = (uint64_t) data_space;
  cp_data = (uint64_t) code_space;
  limit_data = (uint64_t) data_space + data_space_size;
  tick_syspad_data = (uint64_t) malloc(1024);
  tick_tib_data = (uint64_t) malloc(256);
  s0_data = (uint64_t) malloc(1024) + (1024 - 64);
  tick_tick_word_data = (uint64_t) malloc(256);
  cold();
}

void c_emit(int c)
{
  fputc(c, stdout);
  fflush(stdout);
}

int c_key()
{
  return fgetc(stdin);
}

void * c_allocate(size_t size)
{
  return malloc(size);
}

void c_free(void *ptr)
{
  free(ptr);
}

int c_file_status(char *path)
{
  struct stat buf;
  return stat(path, &buf);
}

int64_t c_open_file(const char *filename, int flags)
{
  int ret = open(filename, flags);
  if (ret < 0)
    return (int64_t) -1;
  else
    return ret;
}

int64_t c_read_file(int fd, void *buf, size_t count)
{
  int ret = read(fd, buf, count);
  if (ret < 0)
    return (int64_t) -1;
  else
    return ret;
}

int64_t c_read_char(int fd)
{
  char c;
  int ret = read(fd, &c, 1);
  if (ret <= 0)
    return -1;
  return (int64_t) c;
}

int64_t c_write_file(int fd, void *buf, size_t count)
{
  int ret = write(fd, buf, count);
  if (ret < 0)
    return (int64_t) -1;
  else
    return ret;
}

int64_t c_close_file(int fd)
{
  int ret = close(fd);
  if (ret < 0)
    return (int64_t) -1;
  else
    return ret;
}

int64_t c_file_size(int fd)
{
  off_t current, end;
  current = lseek(fd, 0, SEEK_CUR);
  end = lseek(fd, 0, SEEK_END);
  lseek(fd, current, SEEK_SET);
  if (end = (off_t) -1)
    return (int64_t) -1;
  else
    return (int64_t) end;
}

int64_t c_file_position(int fd)
{
  return (int64_t) lseek(fd, 0, SEEK_CUR);
}

int64_t c_reposition_file(int fd, off_t offset)
{
  return (int64_t) lseek(fd, offset, SEEK_SET);
}

uint64_t c_ticks()
{
#ifdef WIN32
  return GetTickCount64();
#else
  struct timeval tv;
  if(gettimeofday(&tv, NULL) != 0)
    return 0;
  return (tv.tv_sec * 1000) + (tv.tv_usec / 1000);
#endif
}

void c_bye()
{
  exit(0);
}
