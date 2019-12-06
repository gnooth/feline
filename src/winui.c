// Copyright (C) 2019 Peter Graves <gnooth@gmail.com>

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

#include "feline.h"

#define FERAL_FRAME             "Feral Frame"
#define FERAL_TEXT              "Feral Text"
#define FERAL_MINIBUFFER        "Feral Minibuffer"

// globals
static HINSTANCE hinst;

static HFONT hfont_normal;

static int char_width;
static int char_height;

static int textview_rows;
static int textview_columns;

static HWND hwnd_frame;

static HWND hwnd_textview;
static HDC hdc_textview;

static HWND hwnd_modeline;

static HWND hwnd_minibuffer;
static HDC hdc_minibuffer;

static COLORREF rgb_textview_fg = RGB (192, 192, 192);
static COLORREF rgb_textview_bg = 0;

static COLORREF rgb_modeline_fg = 0;
static COLORREF rgb_modeline_bg = RGB (192, 192, 192);

static COLORREF rgb_minibuffer_fg = RGB (192, 192, 192);
static COLORREF rgb_minibuffer_bg = 0;

static LRESULT CALLBACK winui__frame_wnd_proc (HWND hwnd, UINT msg,
                                               WPARAM wparam, LPARAM lparam);

static LRESULT CALLBACK winui__textview_wnd_proc (HWND hwnd, UINT msg,
                                                  WPARAM wparam, LPARAM lparam);

static LRESULT CALLBACK winui__minibuffer_wnd_proc (HWND hwnd, UINT msg,
                                                    WPARAM wparam, LPARAM lparam);

void winui__initialize (void)
{
  static BOOL initialized = FALSE;

  if (initialized)
    return;

  hinst = GetModuleHandle (NULL);

  WNDCLASSEX wcx;

  // frame
  wcx.cbSize = sizeof (wcx);
  wcx.style = CS_HREDRAW | CS_VREDRAW;
  wcx.lpfnWndProc = winui__frame_wnd_proc;
  wcx.cbClsExtra = 0;
  wcx.cbWndExtra = 0;
  wcx.hInstance = hinst;
  wcx.hIcon = NULL;
  wcx.hCursor = LoadCursor (NULL, IDC_ARROW);
  wcx.hbrBackground = (HBRUSH) (COLOR_WINDOW + 1);
  wcx.lpszMenuName =  NULL;
  wcx.lpszClassName = FERAL_FRAME;
  wcx.hIconSm = NULL;

  if (!RegisterClassEx (&wcx))
    {
      fprintf (stderr, "Unable to register frame window class.\n");
      return;
    }

  // text view
  wcx.cbSize = sizeof (wcx);
  wcx.style = CS_DBLCLKS;
  wcx.lpfnWndProc = winui__textview_wnd_proc;
  wcx.cbClsExtra = 0;
  wcx.cbWndExtra = 0;
  wcx.hInstance = hinst;
  wcx.hIcon = NULL;
  wcx.hCursor = LoadCursor (NULL, IDC_IBEAM);
  wcx.hbrBackground = CreateSolidBrush (rgb_textview_bg);
  wcx.lpszMenuName = NULL;
  wcx.lpszClassName = FERAL_TEXT;
  wcx.hIconSm = NULL;

  if (!RegisterClassEx (&wcx))
    {
      fprintf (stderr, "Unable to register text view window class.\n");
      return;
    }

  // minibuffer
  wcx.cbSize = sizeof (wcx);
  wcx.style = CS_DBLCLKS;
  wcx.lpfnWndProc = winui__minibuffer_wnd_proc;
  wcx.cbClsExtra = 0;
  wcx.cbWndExtra = 0;
  wcx.hInstance = hinst;
  wcx.hIcon = NULL;
  wcx.hCursor = LoadCursor (NULL, IDC_IBEAM);
  wcx.hbrBackground = CreateSolidBrush (rgb_textview_bg);
  wcx.lpszMenuName = NULL;
  wcx.lpszClassName = FERAL_MINIBUFFER;
  wcx.hIconSm = NULL;

  if (!RegisterClassEx (&wcx))
    fprintf (stderr, "Unable to register minibuffer window class.\n");

  initialized = TRUE;
}

void winui__create_frame (void)
{
  HWND hwnd_desktop = GetDesktopWindow ();
  RECT rect;
  GetWindowRect (hwnd_desktop, &rect);

  // frame
  hwnd_frame = CreateWindowEx (
    0,                                  // extended window style
    FERAL_FRAME,                        // name of window class
    "Feral",                            // title-bar string
    WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,     // top-level window
    (rect.right - rect.left) / 2,       // left
    0,                                  // top
    (rect.right - rect.left) / 2,       // width
    768,                                // height
    NULL,                               // no owner window
    NULL,                               // no menu
    hinst,                              // handle to application instance
    NULL);                              // no window-creation data

  if (hwnd_frame == NULL)
    {
      fprintf (stderr, "Unable to create window for frame.\n");
      return;
    }

  GetClientRect (hwnd_frame, &rect);

  // text view
  hwnd_textview = CreateWindow (
    FERAL_TEXT,                         // window class
    NULL,                               // title
    WS_CHILD | WS_VISIBLE,              // child window
    0,                                  // left
    0,                                  // top
    rect.right - rect.left,             // width
    rect.bottom - rect.top - 2 * char_height,   // height
    hwnd_frame,                         // owner window
    NULL,                               // use class menu
    hinst,                              // handle to application instance
    NULL);                              // no window-creation data

  if (!hwnd_textview)
    {
      fprintf (stderr, "Unable to create window for text view.\n");
      return;
    }

  // modeline
  hwnd_modeline = CreateWindow (
    "Static",                           // name of window class
    NULL,                               // no title
    WS_CHILD | WS_VISIBLE,              // child window
    0,                                  // left
    rect.bottom - 2 * char_height,      // top
    rect.right,                         // width
    char_height,                        // height
    hwnd_frame,                         // owner window
    NULL,                               // use class menu
    hinst,                              // handle to application instance
    NULL);                              // no window-creation data

  if (!hwnd_modeline)
    {
      fprintf (stderr, "Unable to create window for modeline.\n");
      return;
    }

  // minibuffer
  hwnd_minibuffer = CreateWindow (
    FERAL_MINIBUFFER,                   // window class
    NULL,                               // title
    WS_CHILD | WS_VISIBLE,              // child window
    0,                                  // left
    rect.bottom - char_height,          // top
    rect.right,                         // width
    char_height,                        // height
    hwnd_frame,                         // owner window
    NULL,                               // no menu
    hinst,                              // handle to application instance
    NULL);                              // no window-creation data

  if (!hwnd_minibuffer)
    {
      fprintf (stderr, "Unable to create window for minibuffer.\n");
      return;
    }

  if (hwnd_modeline)
    SendMessage (hwnd_modeline, WM_SETFONT, (WPARAM) hfont_normal, FALSE);

  SendMessage (hwnd_minibuffer, WM_SETFONT, (WPARAM) hfont_normal, FALSE);

  ShowWindow (hwnd_frame, SW_SHOW);
  UpdateWindow (hwnd_frame);
  SetForegroundWindow (hwnd_frame);
}

// winui.asm
extern void winui_safepoint (void);

void winui__main (void)
{
  while (1)
    {
      winui_safepoint ();

      MSG msg;
      while (PeekMessage (&msg, NULL, 0, 0, PM_REMOVE) != 0)
        {
          TranslateMessage (&msg);
          DispatchMessage (&msg);
        }

      Sleep (1);
    }
}

static void winui__create_font (HWND hwnd)
{
  char * font_name = "Consolas";
  LOGFONT lf;

  lf.lfHeight = 16;
  lf.lfWidth = 0;
  lf.lfEscapement = 0;
  lf.lfOrientation = 0;

  lf.lfWeight = FW_NORMAL;

  lf.lfItalic = lf.lfUnderline = lf.lfStrikeOut = 0;
  lf.lfCharSet = DEFAULT_CHARSET;
  lf.lfOutPrecision = 0;
  lf.lfClipPrecision = 0;
  lf.lfQuality = CLEARTYPE_QUALITY;
  lf.lfPitchAndFamily = 0;
  lstrcpy (lf.lfFaceName, font_name);

  hfont_normal = CreateFontIndirect (&lf);

  if (hfont_normal)
    {
      HDC hdc = GetDC (hwnd);
      HFONT hOldFont = (HFONT) SelectObject (hdc, hfont_normal);
      char temp[64];
      GetTextFace (hdc, sizeof (temp), temp);
      if (lstrcmpi (temp, font_name))
        {
          SelectObject (hdc, hOldFont);
          DeleteObject (hfont_normal);
          hfont_normal = (HFONT) GetStockObject (SYSTEM_FIXED_FONT);
          SelectObject (hdc, hfont_normal);
        }
      TEXTMETRIC tm;
      GetTextMetrics (hdc, &tm);
      char_width = (int) tm.tmAveCharWidth;
      char_height = (int) tm.tmHeight;
      ReleaseDC (hwnd, hdc);
    }
  else
    hfont_normal = (HFONT) GetStockObject (SYSTEM_FIXED_FONT);
}

void winui__resize (void)
{
  RECT rect;
  GetClientRect (hwnd_frame, &rect);

  MoveWindow (hwnd_textview,
              0,                                // left
              0,                                // top
              rect.right - rect.left,           // width
              rect.bottom - rect.top - 32,      // height
              TRUE);

  MoveWindow (hwnd_modeline,
              0,                                // left
              rect.bottom - 2 * char_height,    // top
              rect.right,                       // width
              char_height,                      // height
              TRUE);

  MoveWindow (hwnd_minibuffer,
              0,                                // left
              rect.bottom - char_height,        // top
              rect.right,                       // width
              char_height,                      // height
              TRUE);
}

void winui__exit (void)
{
  DestroyWindow (hwnd_frame);
}

// winui.asm
extern void winui_close(void);

static LRESULT CALLBACK winui__frame_wnd_proc (HWND hwnd, UINT msg,
                                               WPARAM wparam, LPARAM lparam)
{
  switch (msg)
    {
    case WM_CREATE:
      winui__create_font (hwnd);
      return 0;

    case WM_CLOSE:
      winui_close ();
      return 0;

    case WM_DESTROY:
      PostQuitMessage (0);
      return 0;

    case WM_SETFOCUS:
      if (hwnd_textview)
        SetFocus (hwnd_textview);
      return 0;

    case WM_SIZE:
      winui__resize ();
      return 0;
    }

  return DefWindowProc (hwnd, msg, wparam, lparam);
}

// winui.asm
extern void winui_textview_paint (void);
extern void winui_textview_char (WPARAM);
extern void winui_textview_keydown (WPARAM);
extern void winui_textview_lbuttondown (WPARAM, LPARAM);
extern void winui_textview_mousemove (WPARAM, LPARAM);
extern void winui_textview_mousewheel (int);

#define ALT_MASK        0x01 << 16
#define CTRL_MASK       0x02 << 16
#define SHIFT_MASK      0x04 << 16

static void winui__textview_keydown (WPARAM wparam)
{
  if (GetKeyState (VK_MENU) & 0x8000)
    wparam |= ALT_MASK;
  if (GetKeyState (VK_CONTROL) & 0x8000)
    wparam |= CTRL_MASK;
  if (GetKeyState (VK_SHIFT) & 0x8000)
    wparam |= SHIFT_MASK;
  winui_textview_keydown (wparam);
}

static LRESULT CALLBACK winui__textview_wnd_proc (HWND hwnd, UINT msg,
                                                  WPARAM wparam, LPARAM lparam)
{
  switch (msg)
    {
    case WM_SETFOCUS:
      CreateCaret (hwnd, NULL, 1, char_height); // caret width is 1 pixel
      ShowCaret (hwnd);
      break;

    case WM_KILLFOCUS:
      DestroyCaret ();
      break;

    case WM_PAINT:
      {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint (hwnd, &ps);
        hdc_textview = hdc;
        SelectObject (hdc, hfont_normal);
        SetTextColor (hdc, rgb_textview_fg);
        SetBkColor (hdc, rgb_textview_bg);
        winui_textview_paint ();
        hdc_textview = 0;
        EndPaint (hwnd, &ps);
      }
      return 0;

    case WM_SIZE:
      textview_rows = HIWORD (lparam) / char_height;
      textview_columns = LOWORD (lparam) / char_width;
      break;

    case WM_CHAR:
      {
        if (GetKeyState (VK_CONTROL) & 0x8000)
          // control key is down
          return 0;
        // lparam bit 31 is the transition state
        // "The value is 1 if the key is being released, or it is 0 if the
        // key is being pressed."
        // ignore WM_CHAR events that are generated by a key being released
        if ((lparam & 0x80000000) == 0)
          winui_textview_char (wparam);
      }
      break;

    case WM_KEYDOWN:
      if (wparam != VK_SHIFT && wparam != VK_CONTROL && wparam != VK_MENU)
        winui__textview_keydown (wparam);
      break;

    case WM_SYSKEYDOWN:
      // lparam bit 29 is the context code
      // "The value is 1 if the ALT key is down while the key is pressed;
      // it is 0 if the WM_SYSKEYDOWN message is posted to the active
      // window because no window has the keyboard focus."
      // "The value is always 0 for a WM_KEYDOWN message."
      if (wparam != VK_CONTROL && wparam != VK_MENU && (lparam & (1 << 29)) != 0)
        winui__textview_keydown (wparam);
      break;

    case WM_LBUTTONDOWN:
      SetCapture (hwnd);
      winui_textview_lbuttondown (wparam, lparam);
      return 0;

    case WM_LBUTTONUP:
      ReleaseCapture ();
      return 0;

    case WM_LBUTTONDBLCLK:
      // pretend it's just a key...
      winui__textview_keydown (VK_LBUTTON);
      return 0;

    case WM_MOUSEMOVE:
      if ((wparam & MK_LBUTTON) == 0)
        return 0;
      winui_textview_mousemove (wparam, lparam);
      return 0;

    case WM_MOUSEWHEEL:
      winui_textview_mousewheel (GET_WHEEL_DELTA_WPARAM (wparam));
      return 0;
    }

  return DefWindowProc (hwnd, msg, wparam, lparam);
}

void winui__textview_text_out (int x, int y, LPCSTR lpString, int c)
{
  if (hdc_textview)
    {
      SetTextColor (hdc_textview, rgb_textview_fg);
      SetBkColor (hdc_textview, rgb_textview_bg);
      TextOut (hdc_textview, x, y, lpString, c);
    }
  else
    {
      HDC hdc = GetDC (hwnd_textview);
      SelectObject (hdc, hfont_normal);
      SetTextColor (hdc, rgb_textview_fg);
      SetBkColor (hdc, rgb_textview_bg);
      HideCaret (hwnd_textview);
      TextOut (hdc, x, y, lpString, c);
      ShowCaret (hwnd_textview);
      ReleaseDC (hwnd_textview, hdc);
    }
}

void winui__textview_clear_eol (int x, int y)
{
  HDC hdc = hdc_textview;
  if (!hdc)
    hdc = GetDC (hwnd_textview);
  RECT rect;
  rect.left = x * char_width;
  rect.top = y * char_height;
  rect.right = textview_columns * char_width;
  rect.bottom = (y + 1) * char_height;
  HBRUSH brush = CreateSolidBrush (rgb_textview_bg);
  FillRect (hdc, &rect, brush);
  if (hdc != hdc_textview)
    ReleaseDC (hwnd_textview, hdc);
  DeleteObject (brush);
}

int winui__textview_rows (void)
{
  return textview_rows;
}

int winui__textview_columns (void)
{
  return textview_columns;
}

void winui__textview_set_fg_color (COLORREF rgb)
{
  rgb_textview_fg = rgb;
}

void winui__textview_set_bg_color (COLORREF rgb)
{
  rgb_textview_bg = rgb;
}

int winui__char_height (void)
{
  return char_height;
}

int winui__char_width (void)
{
  return char_width;
}

void winui__modeline_set_text (LPCSTR lpString)
{
  if (hwnd_modeline)
    SetWindowText (hwnd_modeline, lpString);
}

static BOOL minibuffer_exit;

void winui__minibuffer_main (void)
{
  minibuffer_exit = FALSE;

  SetFocus (hwnd_minibuffer);

  BOOL ret;
  MSG msg;
  while ((ret = GetMessage (&msg, NULL, 0, 0)) != 0
         && ret != -1
         && minibuffer_exit == FALSE)
    {
      TranslateMessage (&msg);
      DispatchMessage (&msg);
    }

  SetFocus (hwnd_textview);
}

void winui__minibuffer_exit (void)
{
  minibuffer_exit = TRUE;
}

// winui.asm
extern void winui_minibuffer_keydown (WPARAM);
extern void winui_minibuffer_char (WPARAM);
extern void winui_minibuffer_paint (void);

static void winui__minibuffer_keydown (WPARAM wparam)
{
  if (GetKeyState (VK_MENU) & 0x8000)
    wparam |= ALT_MASK;
  if (GetKeyState (VK_CONTROL) & 0x8000)
    wparam |= CTRL_MASK;
  if (GetKeyState (VK_SHIFT) & 0x8000)
    wparam |= SHIFT_MASK;
  winui_minibuffer_keydown (wparam);
}

static LRESULT CALLBACK winui__minibuffer_wnd_proc (HWND hwnd, UINT msg,
                                                    WPARAM wparam, LPARAM lparam)
{
  switch (msg)
    {
    case WM_SETFOCUS:
      CreateCaret (hwnd, NULL, char_width, char_height);
      ShowCaret (hwnd);
      break;

    case WM_KILLFOCUS:
      DestroyCaret ();
      break;

    case WM_PAINT:
      {
        PAINTSTRUCT ps;
        hdc_minibuffer = BeginPaint (hwnd, &ps);
        SelectObject (hdc_minibuffer, hfont_normal);
        SetTextColor (hdc_minibuffer, rgb_minibuffer_fg);
        SetBkColor (hdc_minibuffer, rgb_minibuffer_bg);
        winui_minibuffer_paint ();
        hdc_minibuffer = 0;
        EndPaint (hwnd, &ps);
      }
      return 0;

    case WM_CHAR:
      winui_minibuffer_char (wparam);
      break;

    case WM_KEYDOWN:
      if (wparam != VK_SHIFT && wparam != VK_CONTROL && wparam != VK_MENU)
        winui__minibuffer_keydown (wparam);
      break;
    }

  return DefWindowProc (hwnd, msg, wparam, lparam);
}

void winui__minibuffer_text_out (int x, int y, LPCSTR lpString, int c)
{
  if (hdc_minibuffer)
    {
      TextOut (hdc_minibuffer, x, y, lpString, c);
    }
  else
    {
      HDC hdc = GetDC (hwnd_minibuffer);
      SelectObject (hdc, hfont_normal);
      SetTextColor (hdc, rgb_minibuffer_fg);
      SetBkColor (hdc, rgb_minibuffer_bg);
      HideCaret (hwnd_minibuffer);
      TextOut (hdc, x, y, lpString, c);
      ShowCaret (hwnd_minibuffer);
      ReleaseDC (hwnd_minibuffer, hdc);
    }
}

void winui__minibuffer_clear_eol (int x, int y)
{
  HDC hdc = hdc_minibuffer;
  if (!hdc)
    hdc = GetDC (hwnd_minibuffer);
  RECT rect;
  rect.left = x * char_width;
  rect.top = y * char_height;
  rect.right = textview_columns * char_width;
  rect.bottom = (y + 1) * char_height;
  HBRUSH brush = CreateSolidBrush (rgb_minibuffer_bg);
  FillRect (hdc, &rect, brush);
  if (hdc != hdc_minibuffer)
    ReleaseDC (hwnd_minibuffer, hdc);
  DeleteObject (brush);
}

void winui__minibuffer_invalidate (void)
{
  InvalidateRect (hwnd_minibuffer, NULL, FALSE);
}
