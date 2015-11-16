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

// Adapted from Win32Forth

#include <windows.h>
#include "forth.h"
#include "windows-ui.h"

#define SPECIAL_MASK    0x20000
#define CONTROL_MASK    0x40000

#define kblength 256
UINT keybuf[kblength];  // circular buffer
int head = 0, tail = 0;

#define next(x) ((x + 1) % kblength)

void beep()
{
}

void yield()
{
  MSG msg;

  while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE))
  {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
}

int c_key()
{
  ShowCaret(g_hWndMain);
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
  HideCaret(g_hWndMain);
  return c;
}

int c_key_avail()
{
  return head == tail ? 0 : -1;
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
  UpdateWindow(g_hWndMain);
  return i;
}

// push a character into the keyboard typeahead buffer
void pushkey(UINT theKey)
{
  UINT keytemp;

  if (next(head) == tail)
    beep();                            // buffer full
  else
    {
      keytemp = theKey;                   // a copy of the theKey
      //    if ((GetKeyState (VK_SHIFT) & 0x8000) && (thekey < 32)) // if shift is down
      //      keytemp |= shift_mask;                // then include the shift bit
      keybuf[head] = keytemp;
      head = next(head);
    }
}

void pushfunctionkey(WPARAM wParam)
{
  switch (wParam)
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
        wParam |= CONTROL_MASK;
      pushkey(SPECIAL_MASK | wParam);
      break;

    default:
      break;
    }
}
