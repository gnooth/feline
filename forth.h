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

#ifndef __FORTH_H
#define __FORTH_H

#include <stdint.h>

typedef int64_t Cell;

Cell os_ticks();

void prep_terminal();
void deprep_terminal();

extern Cell start_time_ticks_data;

#define LF      '\n'
#define CR      '\r'
#define BS      '\b'
#define BL      ' '
#define ESC     0x1b

#endif
