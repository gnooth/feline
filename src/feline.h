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

#ifndef FORTH_H
#define FORTH_H

#include <stdint.h>             // int64_t

typedef int64_t Cell;

// os.c
Cell os_ticks();

// terminal.c
void prep_terminal();
void deprep_terminal();

// backtrace.c
void c_save_backtrace(Cell rip, Cell rsp);

extern Cell os_errno_data;

extern Cell start_time_ticks_data;

#ifdef WIN64
extern Cell saved_exception_code_data;
extern Cell saved_exception_address_data;
#else
extern Cell saved_signal_data;
extern Cell saved_signal_address_data;
#endif
extern Cell saved_rax_data;
extern Cell saved_rbx_data;
extern Cell saved_rcx_data;
extern Cell saved_rdx_data;
extern Cell saved_rsi_data;
extern Cell saved_rdi_data;
extern Cell saved_rbp_data;
extern Cell saved_rsp_data;
extern Cell saved_r8_data;
extern Cell saved_r9_data;
extern Cell saved_r10_data;
extern Cell saved_r11_data;
extern Cell saved_r12_data;
extern Cell saved_r13_data;
extern Cell saved_r14_data;
extern Cell saved_r15_data;
extern Cell saved_rip_data;
extern Cell saved_efl_data;

#define LF      '\n'
#define CR      '\r'
#define BS      '\b'
#define BL      ' '
#define ESC     0x1b

#endif // FORTH_H
