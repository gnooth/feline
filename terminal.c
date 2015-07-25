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

#include <stdio.h>
#ifdef WIN64
#include <windows.h>
#else
#include <termios.h>
#endif

#include "forth.h"

extern Cell echo_data;
extern Cell line_input_data;

static int terminal_prepped = 0;

#ifdef WIN64
static HANDLE console_input_handle = INVALID_HANDLE_VALUE;
#else
static int tty;
static struct termios otio;
#endif

void prep_terminal ()
{
#ifdef WIN64
  DWORD mode;
  console_input_handle = GetStdHandle (STD_INPUT_HANDLE);
  if (GetConsoleMode (console_input_handle, &mode))
    {
      mode = (mode & ~ENABLE_ECHO_INPUT & ~ENABLE_LINE_INPUT & ~ENABLE_PROCESSED_INPUT);
      SetConsoleMode(console_input_handle, mode);
      line_input_data = 0;
    }
  else
    {
      console_input_handle = INVALID_HANDLE_VALUE;
      line_input_data = -1;
    }
#else
  // Linux.
  tty = fileno (stdin);
  struct termios tio;
  if (terminal_prepped)
    return;
  if (!isatty (tty))
    {
      terminal_prepped = 1;
      return;
    }
  tcgetattr (tty, &tio);
  otio = tio;
  tio.c_lflag &= ~(ICANON | ECHO);
  tcsetattr (tty, TCSADRAIN, &tio);
  line_input_data = 0;
  terminal_prepped = 1;
#endif
}

void deprep_terminal ()
{
#ifndef WIN64
  if (terminal_prepped)
    tcsetattr (tty, TCSANOW, &otio);
#endif
}

int os_key()
{
#ifdef WIN64_NATIVE
  if (console_input_handle != INVALID_HANDLE_VALUE)
    return _getch();
  else
    return fgetc(stdin);
#else
  return fgetc(stdin);
#endif
}
