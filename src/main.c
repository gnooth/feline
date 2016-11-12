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
#ifdef WIN64
#include <windows.h>
#else
#include <signal.h>
#include <sys/mman.h>
#endif

#include "feline.h"

extern void cold();
extern void reset();

#ifdef WIN64
LONG CALLBACK windows_exception_handler(EXCEPTION_POINTERS *exception_pointers)
{
  EXCEPTION_RECORD *exception_record = exception_pointers->ExceptionRecord;
  saved_exception_code_data = exception_record->ExceptionCode;
  saved_exception_address_data = (Cell) exception_record->ExceptionAddress;

  CONTEXT *context = exception_pointers->ContextRecord;

  saved_rax_data = (Cell) context->Rax;
  saved_rbx_data = (Cell) context->Rbx;
  saved_rcx_data = (Cell) context->Rcx;
  saved_rdx_data = (Cell) context->Rdx;
  saved_rsi_data = (Cell) context->Rsi;
  saved_rdi_data = (Cell) context->Rdi;
  saved_rbp_data = (Cell) context->Rbp;
  saved_rsp_data = (Cell) context->Rsp;
  saved_r8_data =  (Cell) context->R8;
  saved_r9_data =  (Cell) context->R9;
  saved_r10_data = (Cell) context->R10;
  saved_r11_data = (Cell) context->R11;
  saved_r12_data = (Cell) context->R12;
  saved_r13_data = (Cell) context->R13;
  saved_r14_data = (Cell) context->R14;
  saved_r15_data = (Cell) context->R15;
  saved_rip_data = (Cell) context->Rip;
  saved_efl_data = (Cell) context->EFlags;

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

void * data_stack_base;

static void initialize_forth()
{
  extern Cell sp0_data;
  extern Cell stack_cells_data;

  stack_cells_data = 4096;
  size_t data_stack_size = stack_cells_data * sizeof(Cell);
  data_stack_base = malloc(data_stack_size + 64);
  sp0_data = (Cell) data_stack_base + data_stack_size;
}

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
  sigaction(SIGTRAP, &sa, NULL);
#endif

  cold();

  return 0;
}
