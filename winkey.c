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

// Adapted from Win32Forth

#include <windows.h>

#include "forth.h"
#include "windows-ui.h"

#define SPECIAL_MASK    0x20000
#define CONTROL_MASK    0x40000

#define kblength 256

static UINT keybuf[kblength];

static int head = 0, tail = 0;

#define next(x) ((x + 1) % kblength)

void beep()
{
}

int c_key()
{
  ShowCaret(hWndMain);
  while (head == tail)
  {
    MSG msg;
    if (!GetMessage(&msg, NULL, 0, 0))
      ExitProcess(0);
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  int c = keybuf[tail];
  tail = next(tail);
  HideCaret(hWndMain);
  return c;
}

int c_key_avail()
{
  return head == tail ? 0 : -1;
}

void pushkey(WPARAM wparam)
{
  if (next(head) == tail)
    beep();
  else
    {
      keybuf[head] = wparam;
      head = next(head);
    }
}

void pushfunctionkey(WPARAM wparam)
{
  switch (wparam)
    {
    case VK_NEXT:
    case VK_PRIOR:
    case VK_LEFT:
    case VK_RIGHT:
    case VK_UP:
    case VK_DOWN:
    case VK_HOME:
    case VK_END:
    case VK_DELETE:
      if (GetKeyState(VK_CONTROL) & 0x8000)
        wparam |= CONTROL_MASK;
      pushkey(SPECIAL_MASK | wparam);
      break;
    default:
      break;
    }
}

int c_accept(char *buffer, int bufsize)
{
  memset(buffer, 0, bufsize);
  int i = 0;
  while (1)
    {
      int c = c_key();
      if (i < bufsize && c >= ' ')
        {
          buffer[i++] = c;
          c_emit(c);
        }
      else if (c == BS)
        {
          if (i > 0)
            {
              if (i == lstrlen(buffer))
                buffer[--i] = '\0';
              else
                buffer[--i] = BL;
              c_emit(BS);
              c_emit(BL);
              c_emit(BS);
            }
        }
      else if (c == CR)
        break;
      else
        beep();
    }
  c_emit(BL);
  UpdateWindow(hWndMain);
  return i;
}
