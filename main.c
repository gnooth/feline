// Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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
#include <string.h>             // strlen
#include <setjmp.h>
#ifdef WIN64
#include <windows.h>
#else
#include <signal.h>
#include <sys/mman.h>
#endif

#include "forth.h"
#include "version.h"

#ifdef WINDOWS_UI
#include "windows-ui.h"
#endif

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
extern void reset();

JMP_BUF main_jmp_buf;

#ifndef WIN64

static void signal_handler(int sig, siginfo_t *si, void * context)
{
  ucontext_t * uc;
  char * name;
  switch (sig)
    {
    case SIGSEGV:
      name = "SIGSEGV";
      break;
    case SIGABRT:
      name = "SIGABRT";
      break;
    case SIGFPE:
      name = "SIGFPE";
      break;
    default:
      name = "Error";
      break;
    }
  printf("\n%s at $%lX\n", name, (unsigned long) si->si_addr);
  uc = (ucontext_t *) context;
  void * rip = (void *) uc->uc_mcontext.gregs[REG_RIP];
  printf("RIP = $%lX\n", (unsigned long) rip);
  Cell rbx = (Cell) uc->uc_mcontext.gregs[REG_RBX];
  printf("RBX = $%lX\n", (unsigned long) rbx);
  Cell * rsp = (Cell *) uc->uc_mcontext.gregs[REG_RSP];
  c_save_backtrace(rip, rsp);
  LONGJMP(main_jmp_buf, (unsigned long) si->si_addr);
}
#endif

static void args(int argc, char **argv)
{
  extern Cell argc_data;
  extern Cell argv_data;
  argc_data = argc;
  argv_data = (Cell) argv;
}

static void initialize_forth()
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
  extern Cell stack_cells_data;
  extern Cell word_buffer_data;
  Cell data_space_size = 8 * 1024 * 1024;
  Cell code_space_size = 1024 * 1024;
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
  dp_data = (Cell) data_space;
  cp_data = (Cell) code_space;
  limit_data = (Cell) data_space + data_space_size;
  limit_c_data = (Cell) code_space + code_space_size;

  stringbuf_data = stringbuf_start_data = (Cell) malloc(stringbuf_size);
  stringbuf_end_data = stringbuf_start_data + stringbuf_size;

  tick_tib_data = (Cell) malloc(256);

  // data stack
  stack_cells_data = 4096;
  size_t data_stack_size = stack_cells_data * sizeof(Cell);
  sp0_data = (Cell) malloc(data_stack_size + 64) + data_stack_size;

  word_buffer_data = (Cell) malloc(260);
}

static void print_version()
{
  char * version = VERSION;     // from the generated file version.h (see Makefile)
  if (!strlen(version))
    // the string might be empty (if git is not installed, for example)
    version = "0.0.0.1";
  printf("Feline %s\n", version);
}

#if defined WIN64 && defined WINDOWS_UI

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR pCmdLine, int nCmdShow)
{
  start_time_ticks_data = os_ticks();
  print_version();
  initialize_forth();
  InitApplication(hInstance);
  InitInstance(hInstance, nCmdShow);
  cold();
  return 0;
}

#else

int main(int argc, char **argv, char **env)
{
  start_time_ticks_data = os_ticks();

  print_version();

  args(argc, argv);

  prep_terminal();

  initialize_forth();

#ifndef WIN64
  struct sigaction sa;
  sa.sa_flags = SA_SIGINFO;
  sigemptyset(&sa.sa_mask);
  sa.sa_sigaction = signal_handler;
  sigaction(SIGSEGV, &sa, NULL);
  sigaction(SIGABRT, &sa, NULL);
  sigaction(SIGFPE,  &sa, NULL);
#endif

  if (SETJMP(main_jmp_buf) == 0)
    cold();
  else
    reset();

  return 0;
}

#endif
