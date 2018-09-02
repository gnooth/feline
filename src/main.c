// Copyright (C) 2012-2018 Peter Graves <gnooth@gmail.com>

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
#ifdef WIN64
#include <windows.h>
#else
#include <unistd.h>             // sysconf
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <pthread.h>
#endif

#include "feline.h"

extern void cold();
extern void reset();

#ifdef WIN64
LONG CALLBACK windows_exception_handler(EXCEPTION_POINTERS *exception_pointers)
{
  EXCEPTION_RECORD *exception_record = exception_pointers->ExceptionRecord;
  saved_exception_code_data = exception_record->ExceptionCode;
  saved_exception_address_data = (cell) exception_record->ExceptionAddress;

  CONTEXT *context = exception_pointers->ContextRecord;

  saved_rax_data = (cell) context->Rax;
  saved_rbx_data = (cell) context->Rbx;
  saved_rcx_data = (cell) context->Rcx;
  saved_rdx_data = (cell) context->Rdx;
  saved_rsi_data = (cell) context->Rsi;
  saved_rdi_data = (cell) context->Rdi;
  saved_rbp_data = (cell) context->Rbp;
  saved_rsp_data = (cell) context->Rsp;
  saved_r8_data =  (cell) context->R8;
  saved_r9_data =  (cell) context->R9;
  saved_r10_data = (cell) context->R10;
  saved_r11_data = (cell) context->R11;
  saved_r12_data = (cell) context->R12;
  saved_r13_data = (cell) context->R13;
  saved_r14_data = (cell) context->R14;
  saved_r15_data = (cell) context->R15;
  saved_rip_data = (cell) context->Rip;
  saved_efl_data = (cell) context->EFlags;

  c_save_backtrace(context->Rip, context->Rsp);

  extern void handle_signal();
  handle_signal();

  // not reached
  return EXCEPTION_CONTINUE_SEARCH;
}
#endif

#ifndef WIN64
static void signal_handler(int sig, siginfo_t *si, void * context)
{
  saved_signal_data = sig;
  saved_signal_address_data = (cell) si->si_addr;

  // see /usr/include/x86_64-linux-gnu/sys/ucontext.h
  ucontext_t * uc = (ucontext_t *) context;
  saved_rax_data = (cell) uc->uc_mcontext.gregs[REG_RAX];
  saved_rbx_data = (cell) uc->uc_mcontext.gregs[REG_RBX];
  saved_rcx_data = (cell) uc->uc_mcontext.gregs[REG_RCX];
  saved_rdx_data = (cell) uc->uc_mcontext.gregs[REG_RDX];
  saved_rsi_data = (cell) uc->uc_mcontext.gregs[REG_RSI];
  saved_rdi_data = (cell) uc->uc_mcontext.gregs[REG_RDI];
  saved_rbp_data = (cell) uc->uc_mcontext.gregs[REG_RBP];
  saved_rsp_data = (cell) uc->uc_mcontext.gregs[REG_RSP];
  saved_r8_data =  (cell) uc->uc_mcontext.gregs[REG_R8];
  saved_r9_data =  (cell) uc->uc_mcontext.gregs[REG_R9];
  saved_r10_data = (cell) uc->uc_mcontext.gregs[REG_R10];
  saved_r11_data = (cell) uc->uc_mcontext.gregs[REG_R11];
  saved_r12_data = (cell) uc->uc_mcontext.gregs[REG_R12];
  saved_r13_data = (cell) uc->uc_mcontext.gregs[REG_R13];
  saved_r14_data = (cell) uc->uc_mcontext.gregs[REG_R14];
  saved_r15_data = (cell) uc->uc_mcontext.gregs[REG_R15];
  saved_rip_data = (cell) uc->uc_mcontext.gregs[REG_RIP];
  saved_efl_data = (cell) uc->uc_mcontext.gregs[REG_EFL];

  c_save_backtrace(saved_rip_data, saved_rsp_data);

  extern void handle_signal();
  uc->uc_mcontext.gregs[REG_RIP] = (cell) handle_signal;
}
#endif

static void args(int argc, char **argv)
{
  extern cell main_argc;
  extern cell main_argv;
  main_argc = argc;
  main_argv = (cell) argv;
}

static void initialize_datastack()
{
  extern cell primordial_sp0_;
  primordial_sp0_ = os_thread_initialize_datastack();
}

static void initialize_dynamic_code_space()
{
  extern cell code_space_;
  extern cell code_space_free_;
  extern cell code_space_limit_;

#define DYNAMIC_CODE_SPACE_RESERVED_SIZE 1024*1024*8    // 8 mb

#ifdef WIN64
  void *address = (void *)0x80000000;

  for (int i = 0; i < 3; i++)
    {
      code_space_ =
        (cell) VirtualAlloc(address,                            // starting address
                            DYNAMIC_CODE_SPACE_RESERVED_SIZE,   // size
                            MEM_COMMIT|MEM_RESERVE,             // allocation type
                            PAGE_EXECUTE_READWRITE);            // protection
      if (code_space_)
        break;
      address += 0x100000;
    }

  if (!code_space_)
    {
      // give up
      code_space_ =
        (cell) VirtualAlloc(NULL,                               // starting address
                            DYNAMIC_CODE_SPACE_RESERVED_SIZE,   // size
                            MEM_COMMIT|MEM_RESERVE,             // allocation type
                            PAGE_EXECUTE_READWRITE);            // protection

    }

  if (code_space_ == (cell) NULL)
    exit(EXIT_FAILURE);
#else
  // Linux
  code_space_ =
    (cell) mmap((void *)0x1000000,                              // starting address
                DYNAMIC_CODE_SPACE_RESERVED_SIZE,               // size
                PROT_READ|PROT_WRITE|PROT_EXEC,                 // protection
                MAP_ANONYMOUS|MAP_PRIVATE|MAP_NORESERVE,        // flags
                -1,                                             // fd
                0);                                             // offset

  if (code_space_ == (cell) MAP_FAILED)
    exit(EXIT_FAILURE);
#endif

  code_space_free_  = code_space_;
  code_space_limit_ = code_space_ + DYNAMIC_CODE_SPACE_RESERVED_SIZE;
}

static void reserve_handle_space()
{
  extern cell handle_space_;

#define HANDLE_SPACE_RESERVED_SIZE 1024*1024*100        // 100 mb

#ifdef WIN64
  handle_space_ =
    (cell) VirtualAlloc(0,                                      // starting address
                        HANDLE_SPACE_RESERVED_SIZE,             // size
                        MEM_COMMIT|MEM_RESERVE,                 // allocation type
                        PAGE_READWRITE);                        // protection
#else
  handle_space_ =
    (cell) mmap((void *)0x2000000,                              // address
                HANDLE_SPACE_RESERVED_SIZE,                     // size
                PROT_READ|PROT_WRITE,                           // protection
                MAP_ANONYMOUS|MAP_PRIVATE|MAP_NORESERVE,        // flags
                -1,                                             // fd
                0);                                             // offset
#endif
}

#ifdef WIN64
DWORD tls_index;
#else
pthread_key_t tls_key;
#endif

static void initialize_threads()
{
#ifdef WIN64
  tls_index = TlsAlloc();
  if (tls_index == TLS_OUT_OF_INDEXES)
    printf("TlsAlloc failed\n");
#else
  int status = pthread_key_create(&tls_key, NULL);
  if (status != 0)
    printf("pthread_key_create failed\n");
#endif
}

int main(int argc, char **argv, char **env)
{
  start_time_raw_nano_count_ = os_nano_count();

  args(argc, argv);

  prep_terminal();

  initialize_dynamic_code_space();

  reserve_handle_space();

  initialize_datastack();

  initialize_threads();

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
  sigaction(SIGTRAP, &sa, NULL);
#endif

  cold();

  return 0;
}
