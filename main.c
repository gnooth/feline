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

#ifdef WIN64
LONG CALLBACK windows_exception_handler(EXCEPTION_POINTERS *exception_pointers)
{
  CONTEXT *context = exception_pointers->ContextRecord;
  c_save_backtrace((void *)context->Rip, (Cell *)context->Rsp);
  EXCEPTION_RECORD *exception_record = exception_pointers->ExceptionRecord;
  DWORD exception_code = exception_record->ExceptionCode;
  PVOID exception_address = exception_record->ExceptionAddress;
  switch (exception_code)
    {
    case EXCEPTION_ACCESS_VIOLATION:
      printf("Invalid memory access at 0x%p", exception_address);
      break;
    case EXCEPTION_INT_DIVIDE_BY_ZERO:
      printf("Division by zero at 0x%p", exception_address);
      break;
    default:
      printf("Exception 0x%lx at 0x%p", exception_code, exception_address);
      break;
    }
  reset();
  // not reached
  return EXCEPTION_CONTINUE_SEARCH;
}
#endif

#ifndef WIN64
static void signal_handler(int sig, siginfo_t *si, void * context)
{
  saved_signal_data = sig;
  saved_signal_address_data = (Cell) si->si_addr;

  // see /usr/include/x86_64-linux-gnu/sys/ucontext.h
  ucontext_t * uc = (ucontext_t *) context;
  saved_rax_data = (Cell) uc->uc_mcontext.gregs[REG_RAX];
  saved_rbx_data = (Cell) uc->uc_mcontext.gregs[REG_RBX];
  saved_rcx_data = (Cell) uc->uc_mcontext.gregs[REG_RCX];
  saved_rdx_data = (Cell) uc->uc_mcontext.gregs[REG_RDX];
  saved_rsi_data = (Cell) uc->uc_mcontext.gregs[REG_RSI];
  saved_rdi_data = (Cell) uc->uc_mcontext.gregs[REG_RDI];
  saved_rbp_data = (Cell) uc->uc_mcontext.gregs[REG_RBP];
  saved_rsp_data = (Cell) uc->uc_mcontext.gregs[REG_RSP];
  saved_r8_data =  (Cell) uc->uc_mcontext.gregs[REG_R8];
  saved_r9_data =  (Cell) uc->uc_mcontext.gregs[REG_R9];
  saved_r10_data = (Cell) uc->uc_mcontext.gregs[REG_R10];
  saved_r11_data = (Cell) uc->uc_mcontext.gregs[REG_R11];
  saved_r12_data = (Cell) uc->uc_mcontext.gregs[REG_R12];
  saved_r13_data = (Cell) uc->uc_mcontext.gregs[REG_R13];
  saved_r14_data = (Cell) uc->uc_mcontext.gregs[REG_R14];
  saved_r15_data = (Cell) uc->uc_mcontext.gregs[REG_R15];
  saved_rip_data = (Cell) uc->uc_mcontext.gregs[REG_RIP];
  saved_efl_data = (Cell) uc->uc_mcontext.gregs[REG_EFL];

  c_save_backtrace(saved_rip_data, saved_rsp_data);

//   LONGJMP(main_jmp_buf, (unsigned long) si->si_addr);
  extern void handle_signal();
  handle_signal();
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

#if defined WIN64 && defined WINDOWS_UI

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR pCmdLine, int nCmdShow)
{
  start_time_ticks_data = os_ticks();
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

  args(argc, argv);

  prep_terminal();

  initialize_forth();

#ifdef WIN64
  AddVectoredExceptionHandler(1, windows_exception_handler);
#else
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
