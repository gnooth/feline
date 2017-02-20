// Copyright (C) 2012-2017 Peter Graves <gnooth@gmail.com>

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
#include <sys/stat.h>
#include <fcntl.h>              // _O_BINARY, O_CREAT
#include <time.h>               // time, localtime_r
#include <errno.h>
#include <string.h>             // strerror
#include <inttypes.h>           // PRId64
#ifdef WIN64
#include <windows.h>
#include <io.h>                 // _chsize
#else
#include <limits.h>             // PATH_MAX
#include <unistd.h>
#include <sys/time.h>
#include <sys/resource.h>       // getrusage
#endif

#include "feline.h"

void * os_malloc(size_t size)
{
  return malloc(size);
}

void os_free(void *ptr)
{
  free(ptr);
}

void * os_resize(void *ptr, size_t size)
{
  return realloc(ptr, size);
}

#ifdef WIN64
static HANDLE executable_heap;

void * os_allocate_executable(size_t size)
{
  if (executable_heap == 0)
    {
      executable_heap = HeapCreate(HEAP_CREATE_ENABLE_EXECUTE, 0, 0);
      if (executable_heap == NULL)
        {
          os_errno_data = GetLastError();
          return NULL;
        }
    }
  return HeapAlloc(executable_heap, 0, size);
}

void os_free_executable(void *ptr)
{
  HeapFree(executable_heap, 0, ptr);
}
#endif

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

cell os_open_file(const char *filename, int flags)
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
  if (h == INVALID_HANDLE_VALUE)
    os_errno_data = GetLastError();
  return (cell) h;
#else
  int ret;
#ifdef WIN64
  flags |= _O_BINARY;
#endif
  ret = open(filename, flags);
  if (ret < 0)
    {
      os_errno_data = errno;
      return (cell) -1;
    }
  else
    return ret;
#endif
}

cell os_create_file(const char *filename, int flags)
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
  return (cell) h;
#else
  int ret;
#ifdef WIN64
  flags |= _O_CREAT|_O_TRUNC|_O_BINARY;
#else
  flags |= O_CREAT|O_TRUNC;
#endif
  ret = open(filename, flags, 0644);
  if (ret < 0)
    return (cell) -1;
  else
    return ret;
#endif
}

cell os_read_file(cell fd, void *buf, size_t count)
{
#ifdef WIN64_NATIVE
  DWORD bytes_read;
  BOOL ret = ReadFile((HANDLE)fd, buf, count, &bytes_read, NULL);
  if (ret)
    return (cell) bytes_read;
  else
    return (cell) -1;
#else
  int ret = read(fd, buf, count);
  if (ret < 0)
    {
      os_errno_data = errno;
      return (cell) -1;
    }
  else
    return ret;
#endif
}

cell os_read_char(cell fd)
{
#ifdef WIN64_NATIVE
  DWORD bytes_read;
  unsigned char c;
  BOOL ret = ReadFile((HANDLE)fd, &c, 1, &bytes_read, NULL);
  // "When a synchronous read operation reaches the end of a file, ReadFile
  // returns TRUE and sets *lpNumberOfBytesRead to zero."
  if (ret && bytes_read == 1)
    return (cell) c;
  else
    return (cell) -1;
#else
  unsigned char c;
  int ret = read(fd, &c, 1);
  if (ret <= 0)
    return -1;
  return (cell) c;
#endif
}

cell os_write_file(cell fd, void *buf, size_t count)
{
#ifdef WIN64_NATIVE
  DWORD bytes_written = 0;
  BOOL ret;
  ret = WriteFile((HANDLE)fd, buf, count, &bytes_written, NULL);
  if (ret)
    return (cell) bytes_written;
  else
    return -1;
#else
  int ret = write(fd, buf, count);
  if (ret < 0)
    return (cell) -1;
  else
    return ret;
#endif
}

cell os_close_file(cell fd)
{
#ifdef WIN64_NATIVE
  cell ret = (cell) CloseHandle((HANDLE)fd);
  if (ret)
    return 0;
  else
    return (cell) -1;
#else
  int ret = close(fd);
  if (ret < 0)
    return (cell) -1;
  else
    return ret;
#endif
}

cell os_file_size(cell fd)
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
    return (cell) -1;
  else
    return (cell) end;
#endif
}

cell os_file_position(cell fd)
{
#ifdef WIN64_NATIVE
  DWORD pos = SetFilePointer((HANDLE)fd, 0, NULL, FILE_CURRENT);
  if (pos == INVALID_SET_FILE_POINTER)
    return -1;
  else
    return pos;
#else
  return (cell) lseek(fd, 0, SEEK_CUR);
#endif
}

cell os_reposition_file(cell fd, off_t offset)
{
#ifdef WIN64_NATIVE
  DWORD pos = SetFilePointer((HANDLE)fd, offset, NULL, FILE_BEGIN);
  if (pos == INVALID_SET_FILE_POINTER)
    return -1;
  else
    return pos;
#else
  return (cell) lseek(fd, offset, SEEK_SET);
#endif
}

cell os_resize_file(cell fd, off_t offset)
{
#ifdef WIN64_NATIVE
  DWORD pos = SetFilePointer((HANDLE)fd, offset, NULL, FILE_BEGIN);
  if (pos == INVALID_SET_FILE_POINTER)
    return -1;
  if (SetEndOfFile((HANDLE)fd))
    return 0;
  else
    return -1;
#elif defined(WIN64)
  return (cell) _chsize(fd, offset);
#else
  return (cell) ftruncate(fd, offset);
#endif
}

cell os_delete_file(const char *filename)
{
#ifdef WIN64_NATIVE
  return DeleteFile(filename) ? 0 : -1;
#else
  return unlink(filename);
#endif
}

cell os_rename_file(const char *oldpath, const char *newpath)
{
#ifdef WIN64_NATIVE
  return MoveFile(oldpath, newpath) ? 0 : -1;
#else
  return rename(oldpath, newpath);
#endif
}

cell os_flush_file(cell fd)
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

cell os_ticks()
{
#ifdef WIN64
  ULONGLONG WINAPI GetTickCount64(void);
  return GetTickCount64();
#else
  struct timeval tv;
  if(gettimeofday(&tv, NULL) != 0)
    return 0;
  return (tv.tv_sec * 1000) + (tv.tv_usec / 1000);
#endif
}

void os_time_and_date(void * buf)
{
  time_t now;
#ifdef WIN64
  struct tm * ltime;
  time(&now);
  ltime = localtime(&now);
  if (ltime)
    memcpy(buf, ltime, sizeof(struct tm));
#else
  time(&now);
  localtime_r(&now, buf);
#endif
}

#ifndef WIN64
extern cell user_microseconds;
extern cell system_microseconds;

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

cell os_chdir(const char *path)
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
#ifdef WIN64
  char *buf = malloc(MAX_PATH);
  GetFullPathName(path, MAX_PATH, buf, NULL);
#else
  char *buf = malloc(PATH_MAX);
  realpath(path, buf);
#endif
  return buf;
}

char *os_strerror(int errnum)
{
  return strerror(errnum);
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
  extern void * data_stack_base;

  deprep_terminal();
  free(data_stack_base);
  exit(0);
}

int c_fixnum_to_base(cell n, cell base, char * buf, size_t size)
{
  // arguments are all untagged
  if (base == 16)
    // PRIX64 is defined in inttypes.h
    return snprintf(buf, size, "%" PRIx64, n);
  else
    // FIXME it's an error if base is not 10 here
    // PRId64 is defined in inttypes.h
    return snprintf(buf, size, "%" PRId64, n);
}
