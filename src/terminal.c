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
#ifdef WIN64
#include <windows.h>
#include <conio.h>
#else
#include <unistd.h>     // isatty
#include <string.h>     // strcmp
#include <signal.h>
#include <termios.h>
#include <sys/ioctl.h>
#endif

#include "feline.h"

#ifdef WINDOWS_UI
#include "windows-ui.h"
#endif

extern Cell line_input_data;

#ifdef WIN64
static HANDLE console_input_handle = INVALID_HANDLE_VALUE;
#else
static int tty;
static struct termios otio;
static int terminal_prepped = 0;
#endif

static void get_terminal_size()
{
  extern Cell nrows_data;
  extern Cell ncols_data;
#ifdef WIN64
  CONSOLE_SCREEN_BUFFER_INFO info;
  if (GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &info))
    {
      ncols_data = info.srWindow.Right - info.srWindow.Left;
      nrows_data = info.srWindow.Bottom - info.srWindow.Top;
    }
#else
  struct winsize size;
  if (ioctl(tty, TIOCGWINSZ, (char *) &size) < 0)
    nrows_data = ncols_data = 0;
  else
    {
      nrows_data = size.ws_row;
      ncols_data = size.ws_col;
    }
#endif
}

#ifndef WIN64
static void sig_winch(int signo)
{
  get_terminal_size();
}
#endif

void prep_terminal()
{
#ifdef WIN64
  extern Cell forth_stdout_data;
  extern Cell nrows_data;
  extern Cell ncols_data;
  DWORD mode;
  console_input_handle = GetStdHandle(STD_INPUT_HANDLE);
#ifdef WIN64_NATIVE
  forth_stdout_data = (Cell) GetStdHandle(STD_OUTPUT_HANDLE);
#endif
  if (GetConsoleMode(console_input_handle, &mode))
    {
      mode = (mode & ~ENABLE_ECHO_INPUT & ~ENABLE_LINE_INPUT & ~ENABLE_PROCESSED_INPUT);
      SetConsoleMode(console_input_handle, mode);
      get_terminal_size();
      COORD size;
      size.X = ncols_data;
      size.Y = nrows_data;
      SetConsoleScreenBufferSize(console_input_handle, size);
      line_input_data = 0;
    }
  else
    {
      console_input_handle = INVALID_HANDLE_VALUE;
      line_input_data = -1;
    }
#else
  // Linux.
  tty = fileno(stdin);
  struct termios tio;
  char *term;
  struct winsize size;
  if (!isatty(tty))
    return;
  term = getenv("TERM");
  if (term == NULL || !strcmp(term, "dumb"))
    return;
  tcgetattr(tty, &tio);
  otio = tio;
  tio.c_iflag &= ~(IXON | IXOFF);       // we want to see C-s and C-q
  tio.c_lflag &= ~(ICANON | ECHO);
  tcsetattr(tty, TCSADRAIN, &tio);
  setvbuf(stdin, NULL, _IONBF, 0);
  signal(SIGWINCH, sig_winch);
  get_terminal_size();
  line_input_data = 0;
  terminal_prepped = 1;
#endif
}

void deprep_terminal()
{
#ifndef WIN64
  if (terminal_prepped)
    tcsetattr(tty, TCSANOW, &otio);
#endif
}

Cell os_key_avail()
{
#ifdef WIN64
#ifdef WINDOWS_UI
  return c_key_avail();
#else
  return _kbhit() ? (Cell) -1 : 0;
#endif
#else
  // Linux
  int chars_avail = 0;
  int tty = fileno(stdin);
  if (ioctl(tty, FIONREAD, &chars_avail) == 0)
    return chars_avail ? (Cell) -1 : 0;
  return 0;
#endif
}

int os_key()
{
#ifdef WIN64
#ifdef WINDOWS_UI
  return c_key();
#else
  if (console_input_handle != INVALID_HANDLE_VALUE)
    return _getch();
  else
    return fgetc(stdin);
#endif
#else
  // Linux
  return fgetc(stdin);
#endif
}
