// Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <setjmp.h>
#include <sys/stat.h>
#include <fcntl.h>      // _O_BINARY, O_CREAT
#ifdef WIN64
#include <windows.h>
#else
#include <limits.h>     // PATH_MAX
#include <signal.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sys/resource.h>       // getrusage
#endif

#include "forth.h"

#ifdef WIN64
#define JMP_BUF                 jmp_buf
#define SETJMP(env)             setjmp(env)
#define LONGJMP(env, val)       longjmp(env, val)
#else
#define JMP_BUF                 sigjmp_buf
#define SETJMP(env)             sigsetjmp(env, 1)
#define LONGJMP(env, val)       siglongjmp(env, val)
#endif

extern void cold();

JMP_BUF main_jmp_buf;

#ifndef WIN64
static void sigsegv_handler(int sig, siginfo_t *si, void * context)
{
  ucontext_t * uc;
  void * rip;
  void * rbx;
  printf("SIGSEGV at $%lX\n", (unsigned long) si->si_addr);
  uc = (ucontext_t *) context;
  rip = (void *) uc->uc_mcontext.gregs[REG_RIP];
  printf("RIP = $%lX\n", (unsigned long) rip);
  rbx = (void *) uc->uc_mcontext.gregs[REG_RBX];
  printf("RBX = $%lX\n", (unsigned long) rbx);
  LONGJMP(main_jmp_buf, (unsigned long) si->si_addr);
}
#endif

void args(int argc, char **argv)
{
  extern Cell argc_data;
  extern Cell argv_data;
  argc_data = argc;
  argv_data = (Cell) argv;
}

int main(int argc, char **argv, char **env)
{
  extern Cell dp_data;
  extern Cell cp_data;
  extern Cell limit_data;
  extern Cell limit_c_data;
  const size_t stringbuf_size = 16384;
  extern Cell stringbuf_start_data;
  extern Cell stringbuf_end_data;
  extern Cell stringbuf_data;
  extern Cell tick_tib_data;
  extern Cell sp0_data;
  extern Cell word_buffer_data;
  Cell data_space_size = 8 * 1024 * 1024;
  Cell code_space_size = 1024 * 1024;
  void * data_space;
  void * code_space;

  args(argc, argv);

  prep_terminal();

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
  dp_data = (Cell) data_space;
  cp_data = (Cell) code_space;
  limit_data = (Cell) data_space + data_space_size;
  limit_c_data = (Cell) code_space + code_space_size;

  stringbuf_data = stringbuf_start_data = (Cell) malloc(stringbuf_size);
  stringbuf_end_data = stringbuf_start_data + stringbuf_size;

  tick_tib_data = (Cell) malloc(256);
  sp0_data = (Cell) malloc(1024) + (1024 - 64);
  word_buffer_data = (Cell) malloc(260);

#ifndef WIN64
  struct sigaction sa;
  sa.sa_flags = SA_SIGINFO;
  sigemptyset(&sa.sa_mask);
  sa.sa_sigaction = sigsegv_handler;
  sigaction(SIGSEGV, &sa, NULL);
  sigaction(SIGABRT, &sa, NULL);
#endif

  if (SETJMP(main_jmp_buf) == 0)
    cold();
  else
    abort();
}

void * os_allocate(size_t size)
{
  return malloc(size);
}

void os_free(void *ptr)
{
  free(ptr);
}

int os_file_status(char *path)
{
  struct stat buf;
  return stat(path, &buf);
}

int os_file_is_directory(char *path)
{
#ifdef WIN64
  const DWORD attributes = GetFileAttributes(path);
  if (attributes != INVALID_FILE_ATTRIBUTES)
    {
      if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0)
        return 1;
    }
  return 0;
#else
  struct stat buf;
  // stat() follows symlinks; lstat() does not
  return (stat(path, &buf) == 0
          && S_ISDIR(buf.st_mode)) ? 1 : 0;
#endif
}

Cell os_open_file(const char *filename, int flags)
{
#ifdef WIN64_NATIVE
  HANDLE h = CreateFile(filename,
                        flags,
                        FILE_SHARE_READ,
                        NULL, // default security descriptor
                        OPEN_EXISTING,
                        FILE_ATTRIBUTE_NORMAL,
                        NULL // template file (ignored for existing file)
                        );
  return (Cell) h;
#else
  int ret;
#ifdef WIN64
  flags |= _O_BINARY;
#endif
  ret = open(filename, flags);
  if (ret < 0)
    return (Cell) -1;
  else
    return ret;
#endif
}

Cell os_create_file(const char *filename, int flags)
{
#ifdef WIN64_NATIVE
  HANDLE h = CreateFile(filename,
                        flags,
                        FILE_SHARE_READ,
                        NULL, // default security descriptor
                        CREATE_ALWAYS,
                        FILE_ATTRIBUTE_NORMAL,
                        NULL // template file (ignored for existing file)
                        );
  return (Cell) h;
#else
  int ret;
#ifdef WIN64
  flags |= _O_CREAT|_O_TRUNC|_O_BINARY;
#else
  flags |= O_CREAT|O_TRUNC;
#endif
  ret = open(filename, flags, 0644);
  if (ret < 0)
    return (Cell) -1;
  else
    return ret;
#endif
}

Cell os_read_file(Cell fd, void *buf, size_t count)
{
#ifdef WIN64_NATIVE
  DWORD bytes_read;
  BOOL ret = ReadFile((HANDLE)fd, buf, count, &bytes_read, NULL);
  if (ret)
    return (Cell) bytes_read;
  else
    return (Cell) -1;
#else
  int ret = read(fd, buf, count);
  if (ret < 0)
    return (Cell) -1;
  else
    return ret;
#endif
}

Cell os_read_char(Cell fd)
{
#ifdef WIN64_NATIVE
  DWORD bytes_read;
  char c;
  BOOL ret = ReadFile((HANDLE)fd, &c, 1, &bytes_read, NULL);
  // "When a synchronous read operation reaches the end of a file, ReadFile
  // returns TRUE and sets *lpNumberOfBytesRead to zero."
  if (ret && bytes_read == 1)
    return (Cell) c;
  else
    return (Cell) -1;
#else
  char c;
  int ret = read(fd, &c, 1);
  if (ret <= 0)
    return -1;
  return (Cell) c;
#endif
}

Cell os_write_file(Cell fd, void *buf, size_t count)
{
#ifdef WIN64_NATIVE
  DWORD bytes_written;
  BOOL ret;
  ret = WriteFile((HANDLE)fd, buf, count, &bytes_written, NULL);
  if (ret)
    return 0;
  else
    return -1;
#else
  int ret = write(fd, buf, count);
  if (ret < 0)
    return (Cell) -1;
  else
    return ret;
#endif
}

Cell os_close_file(Cell fd)
{
#ifdef WIN64_NATIVE
  Cell ret = (Cell) CloseHandle((HANDLE)fd);
  if (ret)
    return 0;
  else
    return (Cell) -1;
#else
  int ret = close(fd);
  if (ret < 0)
    return (Cell) -1;
  else
    return ret;
#endif
}

Cell os_file_size(Cell fd)
{
#ifdef WIN64_NATIVE
  DWORD current, end;
  current = SetFilePointer((HANDLE)fd, 0, NULL, FILE_CURRENT);
  if (current == INVALID_SET_FILE_POINTER)
    return -1;
  end = SetFilePointer((HANDLE)fd, 0, NULL, FILE_END);
  if (end == INVALID_SET_FILE_POINTER)
    return -1;
  SetFilePointer((HANDLE)fd, current, NULL, FILE_BEGIN);
  return end;
#else
  off_t current, end;
  current = lseek(fd, 0, SEEK_CUR);
  end = lseek(fd, 0, SEEK_END);
  lseek(fd, current, SEEK_SET);
  if (end == (off_t) -1)
    return (Cell) -1;
  else
    return (Cell) end;
#endif
}

Cell os_file_position(Cell fd)
{
#ifdef WIN64_NATIVE
  DWORD pos = SetFilePointer((HANDLE)fd, 0, NULL, FILE_CURRENT);
  if (pos == INVALID_SET_FILE_POINTER)
    return -1;
  else
    return pos;
#else
  return (Cell) lseek(fd, 0, SEEK_CUR);
#endif
}

Cell os_reposition_file(Cell fd, off_t offset)
{
#ifdef WIN64_NATIVE
  DWORD pos = SetFilePointer((HANDLE)fd, offset, NULL, FILE_BEGIN);
  if (pos == INVALID_SET_FILE_POINTER)
    return -1;
  else
    return pos;
#else
  return (Cell) lseek(fd, offset, SEEK_SET);
#endif
}

Cell os_resize_file(Cell fd, off_t offset)
{
#ifdef WIN64_NATIVE
  DWORD pos = SetFilePointer((HANDLE)fd, offset, NULL, FILE_BEGIN);
  if (pos == INVALID_SET_FILE_POINTER)
    return -1;
  if (SetEndOfFile((HANDLE)fd))
    return 0;
  else
    return -1;
#else
  return (Cell) ftruncate(fd, offset);
#endif
}

Cell os_delete_file(const char *filename)
{
#ifdef WIN64_NATIVE
  return DeleteFile(filename) ? 0 : -1;
#else
  return unlink(filename);
#endif
}

Cell os_rename_file(const char *oldpath, const char *newpath)
{
#ifdef WIN64_NATIVE
  return MoveFile(oldpath, newpath) ? 0 : -1;
#else
  return rename(oldpath, newpath);
#endif
}

Cell os_flush_file(Cell fd)
{
#ifdef WIN64
#ifdef WIN64_NATIVE
  BOOL ret = FlushFileBuffers((HANDLE)fd);
  if (ret)
    return 0;
  else
    return -1;
#else
  return 0;     // REVIEW
#endif
#else
  // Linux
  return fsync(fd);
#endif
}

void os_emit_file(int c, int fd)
{
#ifdef WIN64
  os_write_file (fd, &c, 1);
#else
  write(fd, &c, 1);
#endif
}

Cell os_ticks()
{
#ifdef WIN64
  return GetTickCount64();
#else
  struct timeval tv;
  if(gettimeofday(&tv, NULL) != 0)
    return 0;
  return (tv.tv_sec * 1000) + (tv.tv_usec / 1000);
#endif
}

#ifndef WIN64
extern Cell user_microseconds;
extern Cell system_microseconds;

void os_cputime()
{
  struct rusage rusage;
  getrusage(RUSAGE_SELF, &rusage);
  user_microseconds = rusage.ru_utime.tv_sec * 1000000 + rusage.ru_utime.tv_usec;
  system_microseconds = rusage.ru_stime.tv_sec * 1000000 + rusage.ru_stime.tv_usec;
}
#endif

#ifdef WIN64
void os_ms(DWORD ms)
{
  Sleep(ms);
}
#else
void os_ms(unsigned int ms)
{
  usleep(ms * 1000);
}
#endif

void os_system(const char *filename)
{
  system(filename);
}

char *os_getenv(const char *name)
{
  return getenv(name);
}

char *os_getcwd(char *buf, size_t size)
{
  // REVIEW error handling
#ifdef WIN64
  GetCurrentDirectory(size, buf);
#else
  getcwd(buf, size);
#endif
  return buf;
}

Cell os_chdir(const char *path)
{
  // REVIEW error handling
#ifdef WIN64
  BOOL ret = SetCurrentDirectory(path);
  return ret ? -1 : 0;
#else
  return chdir(path) ? 0 : -1;
#endif
}

char *os_realpath(const char *path)
{
  char *buf = malloc(PATH_MAX);
#ifdef WIN64_NATIVE
  GetFullPathName(path, PATH_MAX, buf, NULL);
#else
  realpath(path, buf);
#endif
  return buf;
}

#ifdef WIN64
void os_set_console_cursor_position(SHORT x, SHORT y)
{
  HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
  COORD coord;
  coord.X = x;
  coord.Y = y;
  SetConsoleCursorPosition(h, coord);
}
#endif

void os_bye()
{
  deprep_terminal();
  exit(0);
}
