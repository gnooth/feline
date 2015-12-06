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
void c_save_backtrace(void *rip, Cell *rsp);

extern Cell start_time_ticks_data;

#define LF      '\n'
#define CR      '\r'
#define BS      '\b'
#define BL      ' '
#define ESC     0x1b

#endif // FORTH_H
