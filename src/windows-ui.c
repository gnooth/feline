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

#include <windows.h>

#include "forth.h"
#include "windows-ui.h"

extern Cell editor_line_vector_data;
extern Cell editor_top_line_data;

#define APP_NAME        "Forth"
#define CLASS_NAME      "Forth"

static char * screen = 0;               // address of screen buffer
static int screen_line, screen_col;     // current position in screen buffer
static int top = 0;                     // line number of top line in window
static const int MAXLINES = 500;        // number of lines in the screen buffer
static const int MAXCOLS = 128;         // number of columns in the screen buffer

static const int LEFTMARGIN = 4;

#define SCREEN(row, col) *(screen + (row * MAXCOLS) + col)

HWND hWndMain;

static HINSTANCE hInst;
static HFONT hConsoleFont;
static int num_rows;
static int num_cols;
static int char_height;
static int char_width;

VOID WINAPI set_console_font(HWND hWnd)
{
  char * font_name = "Liberation Mono" ;
  LOGFONT lf;
  int size = 10;

  lf.lfHeight = - (size * 4 / 3);
  lf.lfWidth = 0;
  lf.lfEscapement = 0;
  lf.lfOrientation = 0;

  lf.lfWeight = FW_NORMAL;

  lf.lfItalic = lf.lfUnderline = lf.lfStrikeOut = 0;
  lf.lfCharSet = DEFAULT_CHARSET;
  lf.lfOutPrecision = 0;
  lf.lfClipPrecision = 0;
  lf.lfQuality = 0;
  lf.lfPitchAndFamily = 0;
  lstrcpy(lf.lfFaceName, font_name);

  hConsoleFont = CreateFontIndirect(&lf);

  if (hConsoleFont)
    {
      HDC hDC = GetDC(hWnd);
      HFONT hOldFont = (HFONT)SelectObject(hDC, hConsoleFont);
      char temp[64];
      GetTextFace(hDC, sizeof(temp), temp);
      if (lstrcmpi(temp, font_name))
        {
          SelectObject(hDC, hOldFont);
          DeleteObject(hConsoleFont);
          hConsoleFont = (HFONT)GetStockObject(SYSTEM_FIXED_FONT);
          SelectObject(hDC, hConsoleFont);
        }
      TEXTMETRIC tm;
      GetTextMetrics(hDC, &tm);
      char_width = (int)tm.tmAveCharWidth;
      char_height = (int)tm.tmHeight;
      ReleaseDC(hWnd, hDC);
    }
  else
    hConsoleFont = (HFONT)GetStockObject(SYSTEM_FIXED_FONT);
}

void update_caret_pos()
{
  if (GetFocus() == hWndMain)
    SetCaretPos(LEFTMARGIN + screen_col * char_width, (screen_line - top) * char_height);
}

void c_at_xy(int col, int row)
{
  if (GetFocus() == hWndMain)
    SetCaretPos(LEFTMARGIN + col * char_width, row * char_height);
}

void paint_terminal(HWND hwnd)
{
  PAINTSTRUCT ps;
  HDC hdc = BeginPaint(hwnd, &ps);
  SelectObject(hdc, hConsoleFont);
  for (int i = 0; i < num_rows + 1; i++)
    {
      int y = i * char_height;
      if (y + char_height >= ps.rcPaint.top && y <= ps.rcPaint.bottom)
        {
          if (i + top < MAXLINES)
            TextOut(hdc,
                    LEFTMARGIN,
                    y,
                    screen + (i + top) * MAXCOLS,
                    num_cols);
          else
            {
              char temp[MAXCOLS];
              memset(temp, ' ', MAXCOLS);
              TextOut(hdc,
                      LEFTMARGIN,
                      y,
                      temp,
                      num_cols);
            }
        }
    }
  EndPaint(hwnd, &ps);
}

typedef struct vector
{
  Cell object_header;
  Cell length;
  Cell * data_address;
  Cell capacity;
} VECTOR;

typedef struct string
{
  Cell object_header;
  Cell length;
  char * data_address;
  Cell capacity;
} STRING;

void paint_editor(HWND hwnd)
{
  PAINTSTRUCT ps;
  HDC hdc = BeginPaint(hwnd, &ps);
  SelectObject(hdc, hConsoleFont);
  char temp[MAXCOLS];
  memset(temp, ' ', MAXCOLS);
  VECTOR * v = (VECTOR *) editor_line_vector_data;
  if (v)
    {
      int top_line_num = editor_top_line_data;
      for (int i = 0; i < num_rows + 1; i++)
        {
          int y = i * char_height;
          if (y + char_height >= ps.rcPaint.top && y <= ps.rcPaint.bottom)
            {
              //           if (i + top < MAXLINES)
              //             TextOut(hdc,
              //                     LEFTMARGIN,
              //                     y,
              //                     screen + (i + top) * MAXCOLS,
              //                     num_cols);
              //           else
              //             {
              //               char temp[MAXCOLS];
              //               memset(temp, ' ', MAXCOLS);
              //               TextOut(hdc,
              //                       LEFTMARGIN,
              //                       y,
              //                       temp,
              //                       num_cols);
              //             }
              int line_num = top_line_num + i;
              if (line_num >= 0 && line_num < v->length)
                {
                  STRING * s = (STRING *) v->data_address[line_num];
                  char * text = s->data_address;
                  int len = s->length;
                  TextOut(hdc,
                          LEFTMARGIN,
                          y,
                          text,
                          len);
                  if (len < num_cols)
                    TextOut(hdc,
                            LEFTMARGIN + len * char_width,
                            y,
                            temp,
                            num_cols - len);
                }
              else
                {
//                   char temp[MAXCOLS];
//                   memset(temp, ' ', MAXCOLS);
                  TextOut(hdc,
                          LEFTMARGIN,
                          y,
                          temp,
                          num_cols);
                }
            }
        }
    }
  EndPaint(hwnd, &ps);
}

void c_repaint(Cell erase)
{
  InvalidateRect(hWndMain, NULL, erase);
}

LRESULT CALLBACK MainWndProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
  switch (uMsg)
    {
    case WM_CREATE:
      set_console_font(hwnd);
      return 0;

    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;

    case WM_SETFOCUS:
      InvalidateRect(hwnd, NULL, FALSE);
      CreateCaret(hwnd, NULL, char_width, char_height);
      update_caret_pos();
      break;

    case WM_KILLFOCUS:
      DestroyCaret();
      break;

    case WM_SIZE:
      {
        num_rows = HIWORD(lParam) / char_height;
        num_cols = LOWORD(lParam) / char_width;
        extern Cell nrows_data;
        extern Cell ncols_data;
        nrows_data = num_rows;
        ncols_data = num_cols;
        InvalidateRect(hwnd, NULL, FALSE);
      }
      break;

    case WM_PAINT:
      {
        if (editor_line_vector_data)
          paint_editor(hwnd);
        else
          paint_terminal(hwnd);
        break;
      }
      return 0;

    case WM_CHAR:
      pushkey(wParam);
      return 0;

    case WM_KEYDOWN:
      pushfunctionkey(wParam);
      return 0;
    }
  return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

void scroll_window_up()
{
  if (screen)
    {
      if (top < MAXLINES - num_rows)
        ++top;
      else
        {
          memmove(screen, screen + MAXCOLS, (MAXLINES - 1) * MAXCOLS);
          memset(screen + (MAXLINES - 1) * MAXCOLS, BL, MAXCOLS);
        }
    }

  ScrollWindow(hWndMain, 0, -char_height, NULL, NULL);
  UpdateWindow(hWndMain);
}

void maybe_reframe()
{
  if (screen_line > MAXLINES - 1)
    {
      memmove(screen, screen + MAXCOLS, (MAXLINES - 1) * MAXCOLS);
      memset(screen + (MAXLINES - 1) * MAXCOLS, BL, MAXCOLS);
      --top;
      --screen_line;
    }
  if (screen_line - top > num_rows - 1)
    {
      scroll_window_up();
      screen_line = top + num_rows - 1;
      if (screen_line > MAXLINES - 1)
        MessageBox(NULL, "screen_line > MAXLINES - 1", "wrap", MB_OK);
      update_caret_pos();
    }
}

void redisplay_current_line()
{
  RECT r;
  r.top = (screen_line - top) * char_height;
  r.bottom = r.top + char_height;
  r.left = LEFTMARGIN;
  r.right = LEFTMARGIN + num_cols * char_width;
  InvalidateRect(hWndMain, &r, FALSE);
}

void c_emit(char c)
{
  extern Cell nout_data;

  if (!screen)
    return;

  switch (c)
    {
    case BS:
      if (screen_col)
        {
          --screen_col;
          --nout_data;
          redisplay_current_line();
        }
      break;

    case LF:
      {
        nout_data = 0;
        screen_col = 0;
        ++screen_line;
        maybe_reframe();
        if (screen_line > MAXLINES - 1)
          {
            char szT[256];
            wsprintf(szT, "c_emit after maybe_reframe screen_line = %d", screen_line);
            MessageBox(NULL, szT, "c_emit", MB_OK);
          }
        UpdateWindow(hWndMain);
      }
      break;

    case CR:
      break;

    default:
      if (screen_line > MAXLINES - 1)
        {
          char szT[256];
          wsprintf(szT, "c_emit error screen_line = %d", screen_line);
          MessageBox(NULL, szT, "c_emit error", MB_OK);
          ExitProcess(0);
          memmove(screen, screen + MAXCOLS, (MAXLINES - 1) * MAXCOLS);
          memset(screen + (MAXLINES - 1) * MAXCOLS, ' ', MAXCOLS);
          InvalidateRect(hWndMain, NULL, FALSE);
          screen_line = MAXLINES - 1;
        }

      if (screen_col < MAXCOLS)
        {
          SCREEN(screen_line, screen_col) = c;

          RECT r;
          r.top = (screen_line - top) * char_height;
          r.bottom = r.top + char_height;
          r.left = LEFTMARGIN + screen_col * char_width;
          r.right = r.left + char_width;
          InvalidateRect(hWndMain, &r, FALSE);

          ++screen_col;
          ++nout_data;
          maybe_reframe();
        }
    }

  update_caret_pos();
}

void c_type(char * chars, int num_chars)
{
  if (!screen)
    return;

  for (int i = 0; i < num_chars; i++)
    c_emit(chars[i]);

  UpdateWindow(hWndMain);
}

BOOL InitApplication(HINSTANCE hInstance)
{
  WNDCLASS  wc;

  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc = MainWndProc;
  wc.cbClsExtra = 0;
  wc.cbWndExtra = 0;
  wc.hInstance = hInstance;
  wc.hIcon = 0;
  wc.hCursor = LoadCursor(NULL, IDC_ARROW);
  wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
  wc.lpszMenuName = NULL;
  wc.lpszClassName = CLASS_NAME;

  return RegisterClass(&wc);
}

BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
  hInst = hInstance;

  screen = (char *)HeapAlloc(GetProcessHeap(), 0, MAXLINES * MAXCOLS);
  memset(screen, ' ', MAXLINES * MAXCOLS);

  HWND hwnd = CreateWindowEx(
    0,                                  // optional window styles
    CLASS_NAME,                         // window class
    APP_NAME,                           // window name
    WS_OVERLAPPEDWINDOW,                // window style

    // size and position
    CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,

    NULL,                               // parent window
    NULL,                               // menu
    hInstance,                          // instance handle
    NULL                                // additional application data
 );

  if (!hwnd)
    return FALSE;

  hWndMain = hwnd;

  ShowWindow(hwnd, nCmdShow);
  UpdateWindow(hwnd);
  return TRUE;
}

void CDECL debug_log(LPCSTR lpFormat, ...)
{
  static HANDLE hLogFile;
  if (!hLogFile)
    hLogFile = CreateFile("forth.log",
                          GENERIC_WRITE,
                          FILE_SHARE_READ,
                          NULL, // default security descriptor
                          CREATE_ALWAYS,
                          FILE_ATTRIBUTE_NORMAL,
                          NULL // template file (ignored for existing file)
                          );

  char szT[1024];
  LPSTR lpArgs = (LPSTR)&lpFormat + sizeof(lpFormat);
  wvsprintf(szT, lpFormat, lpArgs);
  DWORD bytes_written;
  WriteFile(hLogFile, szT, lstrlen(szT), &bytes_written, NULL);
  FlushFileBuffers(hLogFile);
}
