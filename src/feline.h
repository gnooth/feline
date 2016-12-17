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

#ifndef FELINE_H
#define FELINE_H

#include <stdint.h>             // int64_t

typedef int64_t cell;

// os.c
cell os_ticks();

// terminal.c
void prep_terminal();
void deprep_terminal();

// backtrace.c
void c_save_backtrace(cell rip, cell rsp);

extern cell os_errno_data;

extern cell start_time_ticks_data;

#ifdef WIN64
extern cell saved_exception_code_data;
extern cell saved_exception_address_data;
#else
extern cell saved_signal_data;
extern cell saved_signal_address_data;
#endif
extern cell saved_rax_data;
extern cell saved_rbx_data;
extern cell saved_rcx_data;
extern cell saved_rdx_data;
extern cell saved_rsi_data;
extern cell saved_rdi_data;
extern cell saved_rbp_data;
extern cell saved_rsp_data;
extern cell saved_r8_data;
extern cell saved_r9_data;
extern cell saved_r10_data;
extern cell saved_r11_data;
extern cell saved_r12_data;
extern cell saved_r13_data;
extern cell saved_r14_data;
extern cell saved_r15_data;
extern cell saved_rip_data;
extern cell saved_efl_data;

#endif // FELINE_H
