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

void prep_terminal ();
void deprep_terminal ();

typedef int64_t Cell;

#ifdef WINDOWS_UI
void CDECL debug_log(LPCSTR lpFormat, ...);
void pushkey(UINT theKey);
void pushfunctionkey(WPARAM wParam);
int c_key();
int c_accept(LPSTR pBuffer, int iBufSize);
#endif

#endif
