// Copyright (C) 2015 Peter Graves <gnooth@gmail.com>

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

#ifndef __WINDOWS_UI_H
#define __WINDOWS_UI_H

#ifdef WINDOWS_UI

extern HWND hWndMain;

BOOL InitApplication(HINSTANCE hInstance);
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow);

void CDECL debug_log(LPCSTR lpFormat, ...);

void pushkey(WPARAM theKey);
void pushfunctionkey(WPARAM wParam);

void c_emit(char c);

int c_key();
int c_key_avail();

int c_accept(char *buffer, int bufsize);

#endif // WINDOWS_UI

#endif // __WINDOWS_UI_H
