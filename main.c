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
#include <stdlib.h>
#include <setjmp.h>
#ifdef WIN64
#include <windows.h>
#else
#include <signal.h>
#include <sys/mman.h>
#endif

#include "forth.h"

#ifdef WIN64
#define JMP_BUF                 jmp_buf
#define SETJMP(env)             setjmp(env)
#define LONGJMP(env, val)       longjmp(env, val)
#else
#define JMP_BUF                 sigjmp_buf
#define SETJMP(env)             sigsetjmp(env, 1)
#define LONGJMP(env, val)       siglongjmp(env, val)
#endif

extern void cold();

JMP_BUF main_jmp_buf;

#ifndef WIN64
static void sigsegv_handler(int sig, siginfo_t *si, void * context)
{
  ucontext_t * uc;
  void * rip;
  void * rbx;
  printf("SIGSEGV at $%lX\n", (unsigned long) si->si_addr);
  uc = (ucontext_t *) context;
  rip = (void *) uc->uc_mcontext.gregs[REG_RIP];
  printf("RIP = $%lX\n", (unsigned long) rip);
  rbx = (void *) uc->uc_mcontext.gregs[REG_RBX];
  printf("RBX = $%lX\n", (unsigned long) rbx);
  LONGJMP(main_jmp_buf, (unsigned long) si->si_addr);
}
#endif

void args(int argc, char **argv)
{
  extern Cell argc_data;
  extern Cell argv_data;
  argc_data = argc;
  argv_data = (Cell) argv;
}

void initialize_forth()
{
  extern Cell dp_data;
  extern Cell cp_data;
  extern Cell limit_data;
  extern Cell limit_c_data;
  const size_t stringbuf_size = 16384;
  extern Cell stringbuf_start_data;
  extern Cell stringbuf_end_data;
  extern Cell stringbuf_data;
  extern Cell tick_tib_data;
  extern Cell sp0_data;
  extern Cell word_buffer_data;
  Cell data_space_size = 8 * 1024 * 1024;
  Cell code_space_size = 1024 * 1024;
  void * data_space;
  void * code_space;

#ifdef WIN64
  data_space =
    VirtualAlloc(0, data_space_size, MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE);
  code_space =
    VirtualAlloc(0, code_space_size, MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE);
#else
  data_space =
    mmap((void *)0x1000000, data_space_size, PROT_EXEC|PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE|MAP_NORESERVE, -1, 0);
  code_space =
    mmap((void *)0x2000000, code_space_size, PROT_EXEC|PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE|MAP_NORESERVE, -1, 0);
#endif
  dp_data = (Cell) data_space;
  cp_data = (Cell) code_space;
  limit_data = (Cell) data_space + data_space_size;
  limit_c_data = (Cell) code_space + code_space_size;

  stringbuf_data = stringbuf_start_data = (Cell) malloc(stringbuf_size);
  stringbuf_end_data = stringbuf_start_data + stringbuf_size;

  tick_tib_data = (Cell) malloc(256);
  sp0_data = (Cell) malloc(1024) + (1024 - 64);
  word_buffer_data = (Cell) malloc(260);
}

#if defined WIN64 && defined WINDOWS_UI

#define CLASS_NAME "F64"

LPSTR screen = 0;                       // address of screen buffer
int x, y;                               // current cursor position ABSOLUTE FROM BUFFER TOP
int rowoff = 0;
const int MAXROWS = 500;                // number of lines in the screen save buffer
const int MAXCOLS = 128;                // number of columns in the screen save buffer

const int LEFTMARGIN = 4;

#define SCREEN(x,y) *(screen + (y * MAXCOLS) + x)

HANDLE g_hLogFile;

void CDECL debug_log(LPCSTR lpFormat, ...)
{
  char szT[1024];
  LPSTR lpArgs = (LPSTR)&lpFormat + sizeof(lpFormat);
  wvsprintf(szT, lpFormat, lpArgs);
  DWORD bytes_written;
  WriteFile(g_hLogFile, szT, lstrlen(szT), &bytes_written, NULL);
}

HINSTANCE g_hInst;
HWND g_hWndMain;
HFONT g_hConsoleFont;
int g_iNumRows;
int g_iNumCols;
int g_iCharHeight;
int g_iCharWidth;

void update_caret_pos()
{
  if (GetFocus() == g_hWndMain)
    SetCaretPos(LEFTMARGIN + x * g_iCharWidth, (y - rowoff) * g_iCharHeight);
}

LRESULT CALLBACK MainWndProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
  switch (uMsg)
    {
    case WM_CREATE:
      {
        TEXTMETRIC tm;
        HDC hdc = GetDC(hwnd);
        SelectObject(hdc, (HFONT)GetStockObject(SYSTEM_FIXED_FONT));
        GetTextMetrics(hdc, &tm);
        ReleaseDC(hwnd, hdc);

        g_iCharWidth = (int)tm.tmAveCharWidth;
        debug_log("g_iCharWidth = %d\n", g_iCharWidth);
        g_iCharHeight = (int)tm.tmHeight;
      }
      return 0;

    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;

    case WM_SIZE:
      g_iNumRows = HIWORD(lParam) / g_iCharHeight;
      g_iNumCols = LOWORD(lParam) / g_iCharWidth;
      InvalidateRect(hwnd, NULL, FALSE);
      break;

    case WM_PAINT:
      {
        PAINTSTRUCT ps;
        HDC hDC = BeginPaint(hwnd, &ps);
        SelectObject(hDC, g_hConsoleFont);

        for (int i = 0; i < g_iNumRows + 1; i++)
          {
            int yOut = i * g_iCharHeight;

            if (yOut + g_iCharHeight >= ps.rcPaint.top && yOut <= ps.rcPaint.bottom)
              {
                if (i + rowoff < MAXROWS)
                  TextOut(hDC,
                          LEFTMARGIN,
                          yOut,
                          screen + (i + rowoff) * MAXCOLS,
                          g_iNumCols);
                else
                  {
                    char szT[MAXCOLS];
                    memset(szT, ' ', MAXCOLS);
                    TextOut(hDC,
                            LEFTMARGIN,
                            yOut,
                            szT,
                            g_iNumCols);
                  }
              }
          }

        update_caret_pos();

        EndPaint(hwnd, &ps);
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

void c_emit(char c)
{
  if (!screen)
    return;

  //  scrollfix();
  switch (c)
    {
      //       case BS:
      //         if (x)
      //           --x;
      //         break;

    case 10:
      {
        char szT[ 256 ];
        ++y;
//         wrap();
//         if (y > maxrows - 1)
//           {
//             wsprintf(szT, "emit after wrap y = %d", y);
//             MessageBox(NULL, szT, "emit", MB_OK);
//           }
        UpdateWindow(g_hWndMain);
        break;
      }

    case 13:
      x = 0;
      break;

    default:
      if (y > MAXROWS - 1)
        {
          char szT[ 256 ];
          wsprintf(szT, "emit error y = %d", y);
          MessageBox(NULL, szT, "emit error", MB_OK);
          ExitProcess(0);
          memmove(screen, screen + MAXCOLS, (MAXROWS - 1) * MAXCOLS);
          memset(screen + (MAXROWS - 1) * MAXCOLS, ' ', MAXCOLS);
          InvalidateRect(g_hWndMain, NULL, FALSE);
          y = MAXROWS - 1;
        }

      SCREEN(x, y) = c;

      RECT r;
      r.top = (y - rowoff) * g_iCharHeight;
      r.bottom = r.top + g_iCharHeight;
      r.left = LEFTMARGIN + x * g_iCharWidth;
      r.right = r.left + g_iCharWidth;
      InvalidateRect(g_hWndMain, &r, FALSE);

      ++x;
      //         wrap();

    }
}

void c_type(LPSTR lpString, int iNumChars)
{
  if (!screen)
    return;

  debug_log("c_type iNumChars = %d\n", iNumChars);

//   BOOL bContainsControlChar = FALSE;

//   for (int i = 0; i < iNumChars; i++)
//     {
//       if (lpString[ i ] < ' ')
//         {
//           bContainsControlChar = TRUE;
//           break;
//         }
//     }

//   if (!bContainsControlChar && x + iNumChars < MAXCOLS)
//     {
//       memcpy(screen + y * MAXCOLS + x, lpString, iNumChars);
//       RECT r;
//       r.top = (y - rowoff) * g_iCharHeight;
//       r.bottom = r.top + g_iCharHeight;
//       r.left = LEFTMARGIN + x * g_iCharWidth;
//       r.right = r.left + iNumChars * g_iCharWidth;
//       InvalidateRect(g_hWndMain, &r, FALSE);
//       x += iNumChars;
//     }
//   else
    {
      for (int i = 0; i < iNumChars; i++)
        c_emit(lpString[i]);
    }

  UpdateWindow(g_hWndMain);
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
  wc.hbrBackground = 0;
  wc.lpszMenuName = NULL;
  wc.lpszClassName = CLASS_NAME;

  return RegisterClass(&wc);
}

BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
  g_hInst = hInstance;

  screen = (LPSTR)HeapAlloc(GetProcessHeap(), 0, MAXROWS * MAXCOLS);
  memset(screen, ' ', MAXROWS * MAXCOLS);

  HWND hwnd = CreateWindowEx(
    0,                                  // optional window styles
    CLASS_NAME,                         // window class
    "F64",                              // window name
    WS_OVERLAPPEDWINDOW,                // Window style

    // size and position
    CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,

    NULL,                               // parent window
    NULL,                               // menu
    hInstance,                          // instance handle
    NULL                                // additional application data
   );

  if (!hwnd)
    return FALSE;

  g_hWndMain = hwnd;

  g_hConsoleFont = (HFONT)GetStockObject(SYSTEM_FIXED_FONT);

  ShowWindow(hwnd, nCmdShow);
  UpdateWindow(hwnd);
  return TRUE;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR pCmdLine, int nCmdShow)
{
  g_hLogFile = CreateFile("forth.log",
                          GENERIC_WRITE,
                          FILE_SHARE_READ,
                          NULL, // default security descriptor
                          CREATE_ALWAYS,
                          FILE_ATTRIBUTE_NORMAL,
                          NULL // template file (ignored for existing file)
                         );
  debug_log("WinMain\n");

  initialize_forth();

  InitApplication(hInstance);
  InitInstance(hInstance, nCmdShow);

//   c_type("this is a test of the emergency broadcasting system", 51);

#if 0
  MSG msg;
  while (GetMessage(&msg, NULL, 0, 0))
    {
      TranslateMessage(&msg);
      DispatchMessage(&msg);
    }
#endif
//   while (1)
//     {
//       char buf[256];
//       c_accept(buf, 256);
//     }
  extern void cold();
  cold();
  return 0;
}

#else

int main(int argc, char **argv, char **env)
{
  args(argc, argv);

  prep_terminal();

  initialize_forth();

#ifndef WIN64
  struct sigaction sa;
  sa.sa_flags = SA_SIGINFO;
  sigemptyset(&sa.sa_mask);
  sa.sa_sigaction = sigsegv_handler;
  sigaction(SIGSEGV, &sa, NULL);
  sigaction(SIGABRT, &sa, NULL);
#endif

  if (SETJMP(main_jmp_buf) == 0)
    cold();
  else
    abort();
}

#endif
