// Copyright (C) 2012-2020 Peter Graves <gnooth@gmail.com>

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

#ifdef WIN64
#include <windows.h>
#include <io.h>                 // _chsize
#else
#include <limits.h>             // PATH_MAX
#include <unistd.h>
#include <sys/time.h>
#include <sys/resource.h>       // getrusage
#include <sys/mman.h>
#include <pthread.h>
#include <sys/types.h>
#include <dirent.h>
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

void * os_realloc(void *ptr, size_t size)
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

int os_file_is_regular_file(char *path)
{
#ifdef WIN64
  const DWORD attributes = GetFileAttributes(path);
  if (attributes != INVALID_FILE_ATTRIBUTES)
    {
      // file exists
      if ((attributes & FILE_ATTRIBUTE_DIRECTORY) == 0)
        return 1;
    }
  return 0;
#else
  struct stat buf;
  // stat() follows symlinks; lstat() does not
  return (stat(path, &buf) == 0
          && S_ISREG(buf.st_mode)) ? 1 : 0;
#endif
}

#ifdef WIN64

typedef struct
{
  char *filename;
  HANDLE handle;
  WIN32_FIND_DATA ffd;
} FindFileData ;

cell os_find_first_file (const char *filename)
{
  FindFileData * p = malloc (sizeof (FindFileData));
  HANDLE h = FindFirstFile (filename, &(p->ffd));
  if (h == INVALID_HANDLE_VALUE)
    {
      free (p);
      return 0;
    }
  p->handle = h;
  p->filename = &(p->ffd.cFileName[0]);
  return (cell) p;
}

cell os_find_next_file (FindFileData *p)
{
  return FindNextFile (p->handle, &(p->ffd));
}

cell os_find_close (FindFileData *p)
{
  BOOL b = FindClose (p->handle);
  free (p);
  return b;
}

cell os_find_file_filename (FindFileData *p)
{
  return (p != NULL) ? (cell) p->filename : (cell) NULL;
}

#else

cell os_opendir (const char *name)
{
  return (cell) opendir (name);
}

cell os_readdir (DIR *p)
{
  struct dirent *entry = readdir (p);
  return (entry != NULL) ? (cell) entry->d_name : (cell) NULL;
}

cell os_closedir (DIR *p)
{
  return closedir (p);
}

#endif

cell os_open_file (const char *filename, int flags)
{
#ifdef WIN64
  HANDLE h = CreateFile (filename,
                         flags,
                         FILE_SHARE_READ,
                         NULL, // default security descriptor
                         OPEN_EXISTING,
                         FILE_ATTRIBUTE_NORMAL,
                         NULL // template file (ignored for existing file)
                         );
  if (h == INVALID_HANDLE_VALUE)
    os_errno_data = GetLastError ();
  return (cell) h;
#else
  int ret = open (filename, flags);
  if (ret < 0)
    {
      os_errno_data = errno;
      return (cell) -1;
    }
  else
    return ret;
#endif
}

cell os_file_open_read (const char *filename)
{
#ifdef WIN64
  HANDLE h = CreateFile (filename,
                         GENERIC_READ,
                         FILE_SHARE_READ | FILE_SHARE_WRITE,
                         NULL, // default security descriptor
                         OPEN_EXISTING,
                         FILE_ATTRIBUTE_NORMAL,
                         NULL // template file (ignored for existing file)
                         );
  if (h == INVALID_HANDLE_VALUE)
    {
      os_errno_data = GetLastError ();
      return (cell) -1;
    }
  return (cell) h;
#else
  int ret = open (filename, O_RDONLY);
  if (ret < 0)
    {
      os_errno_data = errno;
      return (cell) -1;
    }
  else
    return ret;
#endif
}

cell os_file_open_append (const char *filename)
{
#ifdef WIN64
  HANDLE h = CreateFile (filename,
                         GENERIC_WRITE,
                         FILE_SHARE_WRITE,
                         NULL, // default security descriptor
                         OPEN_ALWAYS,
                         FILE_ATTRIBUTE_NORMAL,
                         NULL // template file (ignored for existing file)
                         );
  if (h == INVALID_HANDLE_VALUE)
    {
      os_errno_data = GetLastError ();
      return (cell) -1;
    }
  SetFilePointer (h, 0, 0, FILE_END);
  return (cell) h;
#else
  int flags = O_WRONLY|O_APPEND;
  int ret = open (filename, flags);
  if (ret >= 0)
    // file already exists
    return ret;
  flags |= O_CREAT;
  ret = open (filename, flags, 0644);
  if (ret < 0)
    {
      os_errno_data = errno;
      return (cell) -1;
    }
  else
    return ret;
#endif
}

cell os_file_create_write (const char *filename)
{
#ifdef WIN64
  HANDLE h = CreateFile (filename,
                         GENERIC_WRITE,
                         FILE_SHARE_READ,
                         NULL, // default security descriptor
                         CREATE_ALWAYS,
                         FILE_ATTRIBUTE_NORMAL,
                         NULL // template file (ignored for existing file)
                         );
  return (cell) h;
#else
  int ret = open (filename, O_WRONLY|O_CREAT|O_TRUNC, 0644);
  if (ret < 0)
    return (cell) -1;
  else
    return ret;
#endif
}

cell os_read_file (cell fd, void *buf, size_t count)
{
#ifdef WIN64
  DWORD bytes_read;
  BOOL ret = ReadFile ((HANDLE) fd, buf, count, &bytes_read, NULL);
  if (ret)
    return (cell) bytes_read;
  else
    return (cell) -1;
#else
  int ret = read (fd, buf, count);
  if (ret < 0)
    {
      os_errno_data = errno;
      return (cell) -1;
    }
  else
    return ret;
#endif
}

cell os_read_char (cell fd)
{
#ifdef WIN64
  DWORD bytes_read;
  unsigned char c;
  BOOL ret = ReadFile ((HANDLE) fd, &c, 1, &bytes_read, NULL);
  // "When a synchronous read operation reaches the end of a file, ReadFile
  // returns TRUE and sets *lpNumberOfBytesRead to zero."
  if (ret && bytes_read == 1)
    return (cell) c;
  else
    return (cell) -1;
#else
  unsigned char c;
  int ret = read (fd, &c, 1);
  if (ret <= 0)
    return -1;
  return (cell) c;
#endif
}

cell os_write_file (cell fd, void *buf, size_t count)
{
#ifdef WIN64
  DWORD bytes_written = 0;
  if (WriteFile ((HANDLE) fd, buf, count, &bytes_written, NULL))
    return bytes_written;
  else
    return -1;
#else
  return write (fd, buf, count);
#endif
}

cell os_close_file(cell fd)
{
#ifdef WIN64
  cell ret = (cell) CloseHandle ((HANDLE) fd);
  if (ret)
    return 0;
  else
    return (cell) -1;
#else
  int ret = close (fd);
  if (ret < 0)
    return (cell) -1;
  else
    return ret;
#endif
}

cell os_file_size (cell fd)
{
#ifdef WIN64
  DWORD current, end;
  current = SetFilePointer ((HANDLE) fd, 0, NULL, FILE_CURRENT);
  if (current == INVALID_SET_FILE_POINTER)
    return -1;
  end = SetFilePointer ((HANDLE) fd, 0, NULL, FILE_END);
  if (end == INVALID_SET_FILE_POINTER)
    return -1;
  SetFilePointer ((HANDLE) fd, current, NULL, FILE_BEGIN);
  return end;
#else
  off_t current, end;
  current = lseek (fd, 0, SEEK_CUR);
  end = lseek (fd, 0, SEEK_END);
  lseek (fd, current, SEEK_SET);
  if (end == (off_t) -1)
    return (cell) -1;
  else
    return (cell) end;
#endif
}

cell os_file_write_time (const char *path)
{
  struct stat statbuf;
  // stat() follows symlinks; lstat() does not
  if (stat (path, &statbuf) == 0)
    return statbuf.st_mtime;
  else
    return 0;
}

cell os_file_position (cell fd)
{
#ifdef WIN64
  DWORD pos = SetFilePointer ((HANDLE) fd, 0, NULL, FILE_CURRENT);
  if (pos == INVALID_SET_FILE_POINTER)
    return -1;
  else
    return pos;
#else
  return (cell) lseek (fd, 0, SEEK_CUR);
#endif
}

cell os_reposition_file (cell fd, off_t offset)
{
#ifdef WIN64
  DWORD pos = SetFilePointer ((HANDLE) fd, offset, NULL, FILE_BEGIN);
  if (pos == INVALID_SET_FILE_POINTER)
    return -1;
  else
    return pos;
#else
  return (cell) lseek (fd, offset, SEEK_SET);
#endif
}

cell os_resize_file (cell fd, off_t offset)
{
#ifdef WIN64
  DWORD pos = SetFilePointer ((HANDLE) fd, offset, NULL, FILE_BEGIN);
  if (pos == INVALID_SET_FILE_POINTER)
    return -1;
  if (SetEndOfFile ((HANDLE) fd))
    return 0;
  else
    return -1;
#else
  return (cell) ftruncate (fd, offset);
#endif
}

cell os_delete_file (const char *filename)
{
#ifdef WIN64
  return DeleteFile (filename) ? 0 : -1;
#else
  return unlink (filename);
#endif
}

cell os_rename_file (const char *oldpath, const char *newpath)
{
#ifdef WIN64
  return MoveFileEx (oldpath, newpath, MOVEFILE_REPLACE_EXISTING) ? 0 : -1;
#else
  return rename (oldpath, newpath);
#endif
}

cell os_flush_file (cell fd)
{
#ifdef WIN64
  BOOL ret = FlushFileBuffers ((HANDLE) fd);
  if (ret)
    return 0;
  else
    return -1;
#else
  // Linux
  return fsync (fd);
#endif
}

cell os_emit_file (int c, int fd)
{
#ifdef WIN64
  return os_write_file (fd, &c, 1);
#else
  return write (fd, &c, 1);
#endif
}

cell os_ticks (void)
{
#ifdef WIN64
  ULONGLONG WINAPI GetTickCount64 (void);
  return GetTickCount64 ();
#else
  struct timeval tv;
  if(gettimeofday (&tv, NULL) != 0)
    return 0;
  return (tv.tv_sec * 1000) + (tv.tv_usec / 1000);
#endif
}

void os_date_time (void * buf)
{
#ifdef WIN64
  SYSTEMTIME lt;
  char * months[] = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
  GetLocalTime (&lt);
  sprintf (buf, "%s %02d %02d:%02d:%02d.%03d",
           months[lt.wMonth - 1], lt.wDay, lt.wHour, lt.wMinute, lt.wSecond, lt.wMilliseconds);
#else
  struct timespec ts;
  timespec_get (&ts, TIME_UTC);
  char buf2[100];
  struct tm local;
  strftime (buf2, sizeof buf2, "%b %d %T", localtime_r (&ts.tv_sec, &local));
  sprintf (buf, "%s.%03ld", buf2, ts.tv_nsec / 1000000);
#endif
}

cell os_nano_count()
{
#ifdef WIN64
  static int64_t frequency;
  if (frequency == 0)
    {
      LARGE_INTEGER freq;
      QueryPerformanceFrequency (&freq);
      frequency = freq.QuadPart;
    }
  LARGE_INTEGER count;
  QueryPerformanceCounter (&count);
  return (count.QuadPart * 1000000000) / frequency;
#else
  struct timespec t;
  clock_gettime (CLOCK_MONOTONIC, &t);
  return (uint64_t)t.tv_sec * 1000000000 + t.tv_nsec;
#endif
}

char *os_getenv (const char *name)
{
  return getenv (name);
}

char *os_getcwd (char *buf, size_t size)
{
  // REVIEW error handling
#ifdef WIN64
  int ret = GetCurrentDirectory (size, buf);
  if (ret)
    {
      // "If the function succeeds, the return value specifies the number of
      // characters that are written to the buffer, not including the terminating
      // null character."
       return buf;
    }
  else
    {
      // "If the function fails, the return value is zero."
      return NULL;
    }
#else
  return getcwd (buf, size);
#endif
}

cell os_chdir (const char *path)
{
  // Returns 1 if successful, otherwise 0.
#ifdef WIN64
  return SetCurrentDirectory (path);
#else
  return chdir(path) ? 0 : 1;
#endif
}

#ifdef WIN64
char *os_get_full_path_name (const char *path)
{
  char *buf = malloc (MAX_PATH);
  DWORD ret = GetFullPathName (path, MAX_PATH, buf, NULL);
  if (ret > 0 && ret <= MAX_PATH)
    return buf;
  else
    {
      free (buf);
      return NULL;
    }
}
#endif

char *os_strerror (int errnum)
{
  return strerror (errnum);
}

#ifdef WIN64
void os_set_console_cursor_position (SHORT x, SHORT y)
{
  HANDLE h = GetStdHandle (STD_OUTPUT_HANDLE);
  COORD coord;
  coord.X = x;
  coord.Y = y;
  SetConsoleCursorPosition (h, coord);
}

cell os_get_console_character_attributes (void)
{
  HANDLE h = GetStdHandle (STD_OUTPUT_HANDLE);
  CONSOLE_SCREEN_BUFFER_INFO info;
  GetConsoleScreenBufferInfo (h, &info);
  return info.wAttributes;
}
#endif

void os_bye()
{
#ifdef WIN64
  extern int winsock_initialized;
  if (winsock_initialized)
    WSACleanup ();
#endif

  deprep_terminal ();
  exit (0);
}


#define DATASTACK_SIZE 4096 * sizeof(cell)

cell os_thread_initialize_datastack (void)
{
#ifdef WIN64
  SYSTEM_INFO info;
  GetSystemInfo (&info);

  cell datastack_base = (cell) VirtualAlloc (NULL,
                                             DATASTACK_SIZE + info.dwPageSize,
                                             MEM_COMMIT|MEM_RESERVE,
                                             PAGE_READWRITE);
  DWORD old_protect;
  BOOL ret = VirtualProtect ((LPVOID) (datastack_base + DATASTACK_SIZE),
                             info.dwPageSize,
                             PAGE_NOACCESS,
                             &old_protect);

  // "If the function succeeds, the return value is nonzero."
  if (!ret)
    printf ("VirtualProtect error\n");

  return datastack_base + DATASTACK_SIZE;
#else
  long pagesize = sysconf (_SC_PAGESIZE);

  cell datastack_base =
    (cell) mmap (NULL,                                          // starting address
                 DATASTACK_SIZE + pagesize,                     // size
                 PROT_READ|PROT_WRITE,                          // protection
                 MAP_ANONYMOUS|MAP_PRIVATE|MAP_NORESERVE,       // flags
                 -1,                                            // fd
                 0);                                            // offset

  int ret = mprotect ((void *) (datastack_base + DATASTACK_SIZE),
                      pagesize,
                      PROT_NONE);

  // mprotect() returns zero on success
  if (ret != 0)
    printf ("mprotect error\n");

  return datastack_base + DATASTACK_SIZE;
#endif
}

#ifdef WIN64

DWORD WINAPI thread_run(LPVOID arg)
{
  // arg is the handle of the Feline thread object

  TlsSetValue(tls_index, arg);

  extern void thread_run_internal(cell);
  thread_run_internal((cell)arg);

  TlsSetValue(tls_index, 0);

  return 0;
}

#else

void* thread_run(void *arg)
{
  // arg is the handle of the Feline thread object

  pthread_setspecific(tls_key, arg);

  extern void thread_run_internal(cell);
  thread_run_internal((cell)arg);

  // clean up
  pthread_detach(pthread_self());
}

#endif

void os_initialize_primordial_thread (void *arg)
{
#ifdef WIN64
  TlsSetValue(tls_index, arg);
#else
  pthread_setspecific(tls_key, arg);
#endif
}

cell os_current_thread()
{
#ifdef WIN64
  return (cell) TlsGetValue(tls_index);
#else
  return (cell) pthread_getspecific(tls_key);
#endif
}

cell os_current_thread_raw_thread_id()
{
#ifdef WIN64
  return (cell) GetCurrentThreadId();
#else
  return (cell) pthread_self();
#endif
}

#ifdef WIN64
cell os_current_thread_raw_thread_handle()
{
  HANDLE h;

  BOOL status = DuplicateHandle(
    GetCurrentProcess(),
    GetCurrentThread(),
    GetCurrentProcess(),
    &h,
    0,          // desired access (ignored if DUPLICATE_SAME_ACCESS is specified)
    FALSE,      // not inheritable
    DUPLICATE_SAME_ACCESS);

  if (!status)
    printf("DuplicateHandle failed\n");

  return (cell) h;
}
#endif

// returns native thread handle (Windows) or native thread id (Linux)
cell os_thread_create(cell arg)
{
#ifdef WIN64
  HANDLE h = CreateThread(
    NULL,                       // use default security attributes
    0,                          // use default stack size
    thread_run,                 // thread function
    (void *)arg,                // argument to thread function
    CREATE_SUSPENDED,           // creation flags
    NULL);                      // variable to receive thread identifier

  if (h == NULL)
    printf("CreateThread failed\n");

  ResumeThread(h);

  return (cell) h;
#else
  pthread_t thread_id;
  int status = pthread_create(&thread_id, NULL, thread_run, (void *)arg);
  if (status != 0)
    printf("pthread_create failed\n");
  return (cell) thread_id;
#endif
}

void os_thread_join(cell arg)
{
#ifdef WIN64
  HANDLE h = (HANDLE) arg;
  WaitForSingleObject(h, INFINITE);
#else
  pthread_t thread_id = (pthread_t) arg;
  int status = pthread_join(thread_id, NULL);
  if (status != 0)
    printf("pthread_join failed\n");
#endif
}

#define USE_CRITICAL_SECTION

cell os_mutex_init()
{
#ifdef WIN64

#ifdef USE_CRITICAL_SECTION
  CRITICAL_SECTION *cs = (CRITICAL_SECTION *) malloc(sizeof(CRITICAL_SECTION));
  if (cs != NULL)
      InitializeCriticalSection(cs);
  else
    printf("os_mutex_init allocation failed\n");
  return (cell) cs;
#else
  HANDLE h = CreateMutex(NULL, FALSE, NULL);
  if (h == NULL)
    printf("CreateMutex failed\n");
  return (cell) h;
#endif

#else
  // Linux
  pthread_mutex_t *mutex = (pthread_mutex_t *) malloc(sizeof(pthread_mutex_t));
  if (mutex != NULL)
    {
      int status = pthread_mutex_init(mutex, NULL);
      if (status != 0)
        printf("pthread_mutex_init failed\n");
    }
  else
    printf("os_initialize_mutex allocation failed\n");
  return (cell) mutex;
#endif
}

cell os_mutex_lock(cell arg)
{
#ifdef WIN64

#ifdef USE_CRITICAL_SECTION
  CRITICAL_SECTION *cs = (CRITICAL_SECTION *) arg;
  EnterCriticalSection(cs);
  // EnterCriticalSection does not return a value.
  return T_VALUE;
#else
  HANDLE h = (HANDLE) arg;
  return (WaitForSingleObject(h, INFINITE) == WAIT_OBJECT_0) ? T_VALUE : F_VALUE;
#endif

#else
  // Linux
  pthread_mutex_t *mutex = (pthread_mutex_t *) arg;
  return (pthread_mutex_lock(mutex) == 0) ? T_VALUE : F_VALUE;
#endif
}

cell os_mutex_trylock(cell arg)
{
#ifdef WIN64

#ifdef USE_CRITICAL_SECTION
  CRITICAL_SECTION *cs = (CRITICAL_SECTION *) arg;
  return (TryEnterCriticalSection(cs) != 0) ? T_VALUE : F_VALUE;
#else
  HANDLE h = (HANDLE) arg;
  return (WaitForSingleObject(h, 0) == WAIT_OBJECT_0) ? T_VALUE : F_VALUE;
#endif

#else
  // Linux
  pthread_mutex_t *mutex = (pthread_mutex_t *) arg;
  return (pthread_mutex_trylock(mutex) == 0) ? T_VALUE : F_VALUE;
#endif
}

cell os_mutex_unlock(cell arg)
{
#ifdef WIN64

#ifdef USE_CRITICAL_SECTION
  CRITICAL_SECTION *cs = (CRITICAL_SECTION *) arg;
  LeaveCriticalSection(cs);
  // LeaveCriticalSection does not return a value.
  return T_VALUE;
#else
  HANDLE h = (HANDLE) arg;
  return (ReleaseMutex(h) != 0) ? T_VALUE : F_VALUE;
#endif

#else
  // Linux
  pthread_mutex_t *mutex = (pthread_mutex_t *) arg;
  return (pthread_mutex_unlock(mutex) == 0) ? T_VALUE : F_VALUE;
#endif
}

void os_sleep(cell arg)
{
#ifdef WIN64
  DWORD millis = (DWORD) arg;
  Sleep(millis);
#else
  int64_t millis = arg;
  struct timespec tv;
  tv.tv_sec = millis / 1000;
  tv.tv_nsec = (millis - tv.tv_sec * 1000) * 1000000;
  while (nanosleep(&tv, &tv) && errno == EINTR)
    ;
#endif
}
