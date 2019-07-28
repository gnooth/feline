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

#include <gtk/gtk.h>

#include "feline.h"

#define FERAL_DEFAULT_FRAME_WIDTH       800
#define FERAL_DEFAULT_FRAME_HEIGHT      768

#define FERAL_DEFAULT_FONT_SIZE         14.0

#define FERAL_DEFAULT_CHAR_HEIGHT       16

#define FERAL_DEFAULT_MODELINE_HEIGHT   20
#define FERAL_DEFAULT_MINIBUFFER_HEIGHT 20

#define FERAL_DEFAULT_TEXTVIEW_HEIGHT \
 (FERAL_DEFAULT_FRAME_HEIGHT - \
  FERAL_DEFAULT_MODELINE_HEIGHT - \
  FERAL_DEFAULT_MINIBUFFER_HEIGHT)

static int char_width = 0;
static int char_height = FERAL_DEFAULT_CHAR_HEIGHT;

static int textview_rows
  = FERAL_DEFAULT_FRAME_HEIGHT / FERAL_DEFAULT_CHAR_HEIGHT - 2;
static int textview_columns = 0;

static GtkWidget *frame;

static GtkWidget *textview;
static GtkWidget *modeline;
static GtkWidget *minibuffer;

static cairo_t *cr_textview;
static cairo_t *cr_minibuffer;

static COLORREF rgb_textview_fg = RGB (192, 192, 192);
static COLORREF rgb_textview_bg = 0;

static COLORREF rgb_modeline_fg = 0;
static COLORREF rgb_modeline_bg = RGB (192, 192, 192);

static COLORREF rgb_minibuffer_fg = RGB (192, 192, 192);
static COLORREF rgb_minibuffer_bg = 0;

double rgb_red (COLORREF rgb)
{
  return (rgb & 0xff) / 255.0;
}

double rgb_green (COLORREF rgb)
{
  return ((rgb >> 8) & 0xff) / 255.0;
}

double rgb_blue (COLORREF rgb)
{
  return ((rgb >> 16) & 0xff) / 255.0;
}

static const char *mode_line_text;

static int textview_caret_row;
static int textview_caret_column;

static int minibuffer_caret_row;
static int minibuffer_caret_column;

static gboolean gtkui__textview_key_press (GtkWidget *widget,
                                           GdkEventKey *event,
                                           gpointer data);

static gboolean gtkui__textview_button_press (GtkWidget *widget,
                                              GdkEventButton *event,
                                              gpointer data);

static gboolean on_minibuffer_key_press (GtkWidget *widget,
                                         GdkEventKey *event,
                                         gpointer data);

static gboolean on_modeline_draw (GtkWidget *widget,
                                  cairo_t *cr,
                                  gpointer data);

static gboolean gtkui__minibuffer_draw (GtkWidget *widget,
                                        cairo_t *cr,
                                        gpointer data);

static gboolean gtkui__textview_draw (GtkWidget *widget,
                                      cairo_t *cr,
                                      gpointer data);

void gtkui__initialize (void)
{
  gtk_init(0,  NULL);

  frame = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title (GTK_WINDOW (frame), "Feral");
  gtk_window_set_default_size (GTK_WINDOW (frame),
                               FERAL_DEFAULT_FRAME_WIDTH,
                               FERAL_DEFAULT_FRAME_HEIGHT);

  GtkBox *box = GTK_BOX (gtk_box_new (GTK_ORIENTATION_VERTICAL, 0));
  gtk_container_add (GTK_CONTAINER (frame), GTK_WIDGET(box));

  textview = gtk_drawing_area_new();

  gtk_widget_set_size_request (textview,
                               FERAL_DEFAULT_FRAME_WIDTH,
                               FERAL_DEFAULT_TEXTVIEW_HEIGHT);

  gtk_widget_set_can_focus (textview, TRUE);

  gtk_widget_set_events (textview,
                         //                          GDK_EXPOSURE_MASK |
                         //                          GDK_ENTER_NOTIFY_MASK |
                         //                          GDK_LEAVE_NOTIFY_MASK |
                         GDK_BUTTON_PRESS_MASK |
                         //                          GDK_BUTTON_RELEASE_MASK |
                         //                          GDK_SCROLL_MASK |
                         GDK_KEY_PRESS_MASK
                         //                          GDK_KEY_RELEASE_MASK |
                         //                          GDK_POINTER_MOTION_MASK |
                         //                          GDK_POINTER_MOTION_HINT_MASK
                         );

  g_signal_connect (textview, "draw",
                    G_CALLBACK (gtkui__textview_draw), NULL);
  g_signal_connect (textview, "key-press-event",
                    G_CALLBACK(gtkui__textview_key_press), NULL);
  g_signal_connect (textview, "button-press-event",
                    G_CALLBACK(gtkui__textview_button_press), NULL);

  modeline = gtk_drawing_area_new();

  gtk_widget_set_size_request (modeline,
                               FERAL_DEFAULT_FRAME_WIDTH,
                               FERAL_DEFAULT_MODELINE_HEIGHT);

  gtk_widget_set_can_focus (modeline, TRUE);

  gtk_widget_set_events (modeline,
                         //                          GDK_EXPOSURE_MASK |
                         //                          GDK_ENTER_NOTIFY_MASK |
                         //                          GDK_LEAVE_NOTIFY_MASK |
                         //                          GDK_BUTTON_PRESS_MASK |
                         //                          GDK_BUTTON_RELEASE_MASK |
                         //                          GDK_SCROLL_MASK |
                         GDK_KEY_PRESS_MASK
                         //                          GDK_KEY_RELEASE_MASK |
                         //                          GDK_POINTER_MOTION_MASK |
                         //                          GDK_POINTER_MOTION_HINT_MASK
                         );

  g_signal_connect (modeline, "draw",
                    G_CALLBACK (on_modeline_draw), NULL);
  //   g_signal_connect (modeline, "key-press-event",
  //                     G_CALLBACK(key_press_callback), NULL);

  minibuffer = gtk_drawing_area_new();

  gtk_widget_set_size_request (minibuffer,
                               FERAL_DEFAULT_FRAME_WIDTH,
                               FERAL_DEFAULT_MINIBUFFER_HEIGHT);

  gtk_widget_set_can_focus (minibuffer, TRUE);

  gtk_widget_set_events (minibuffer,
                         //                          GDK_EXPOSURE_MASK |
                         //                          GDK_ENTER_NOTIFY_MASK |
                         //                          GDK_LEAVE_NOTIFY_MASK |
                         GDK_BUTTON_PRESS_MASK |
                         //                          GDK_BUTTON_RELEASE_MASK |
                         //                          GDK_SCROLL_MASK |
                         GDK_KEY_PRESS_MASK
                         //                          GDK_KEY_RELEASE_MASK |
                         //                          GDK_POINTER_MOTION_MASK |
                         //                          GDK_POINTER_MOTION_HINT_MASK
                         );

  g_signal_connect (minibuffer, "draw",
                    G_CALLBACK (gtkui__minibuffer_draw), NULL);

  g_signal_connect (minibuffer, "key-press-event",
                    G_CALLBACK (on_minibuffer_key_press), NULL);

  gtk_box_pack_end (box, minibuffer, FALSE, FALSE, 0);
  gtk_box_pack_end (box, modeline, FALSE, FALSE, 0);
  gtk_box_pack_end (box, textview, FALSE, FALSE, 0);

  // REVIEW
  gtk_window_move (GTK_WINDOW (frame), 480, 0);

  gtk_widget_show_all (frame);
}

void gtkui__main (void)
{
  gtk_main ();
}

void gtkui__exit (void)
{
  gtk_widget_destroy (frame);
  gtk_main_quit ();
}

int gtkui__textview_rows (void)
{
  return textview_rows;
}

int gtkui__textview_columns (void)
{
  return textview_columns;
}

void gtkui__textview_set_fg_color (int rgb)
{
  rgb_textview_fg = rgb;
}

void gtkui__textview_set_bg_color (int rgb)
{
  rgb_textview_bg = rgb;
}

int gtkui__char_height (void)
{
  return char_height;
}

int gtkui__char_width (void)
{
  return char_width;
}

extern void gtkui_textview_keydown (guint);
extern void gtkui_textview_button_press (int, int);

#define ALT_MASK        0x01 << 16
#define CTRL_MASK       0x02 << 16
#define SHIFT_MASK      0x04 << 16

void gtkui__modeline_set_text (const char *s)
{
  mode_line_text = s;
}

static void gtkui__textview_keydown (GdkEventKey *event)
{
  guint keyval = event->keyval;

//   if (keyval == 0xffe3 || keyval == 0xffe4) // Control_L, Control_R
//     return;

  guint state = event->state;
  if (state & GDK_MOD1_MASK)
    keyval |= ALT_MASK;
  if (state & GDK_CONTROL_MASK)
    keyval |= CTRL_MASK;
  if (state & GDK_SHIFT_MASK)
    keyval |= SHIFT_MASK;
//   g_print ("gtkui__textview_keydown keyval = 0x%08x\n", keyval);
  gtkui_textview_keydown (keyval);
  gtk_widget_queue_draw (frame);
}

// static void
// on_size_allocate (GtkWidget *widget, GtkAllocation *allocation)
// {
//   int  width, height;
//   gtk_window_get_size (GTK_WINDOW (widget), &width, &height);
//   g_print ("w = %d h = %d\n", width, height);
// }

static gboolean
gtkui__textview_button_press (GtkWidget *widget,
                              GdkEventButton *event,
                              gpointer data)
{
  gtkui_textview_button_press (event->x, event->y);
  return TRUE;
}

static gboolean
gtkui__textview_key_press (GtkWidget *widget,
                           GdkEventKey *event,
                           gpointer data)
{
// #define GDK_KEY_Control_L 0xffe3
// #define GDK_KEY_Control_R 0xffe4
  if (event->keyval == GDK_KEY_Control_L || event->keyval == GDK_KEY_Control_R)
    return FALSE;

// #define GDK_KEY_Alt_L 0xffe9
// #define GDK_KEY_Alt_R 0xffea
  if (event->keyval == GDK_KEY_Alt_L || event->keyval == GDK_KEY_Alt_R)
    return FALSE;

// #define GDK_KEY_Shift_L 0xffe1
// #define GDK_KEY_Shift_R 0xffe2
  if (event->keyval == GDK_KEY_Shift_L || event->keyval == GDK_KEY_Shift_R)
    return FALSE;

//   g_print ("key pressed 0x%08x 0x%08x %s\n", event->state, event->keyval,
//            gdk_keyval_name (event->keyval));
  gtkui__textview_keydown (event);
//   if (event->keyval == 0x71)
//     {
//       gtk_widget_destroy (frame);
//       gtk_main_quit ();
//     }
  return TRUE;
}

extern void gtkui_minibuffer_keydown (guint);

static gboolean
on_minibuffer_key_press (GtkWidget *widget, GdkEventKey *event, gpointer data)
{
// #define GDK_KEY_Control_L 0xffe3
// #define GDK_KEY_Control_R 0xffe4
  if (event->keyval == GDK_KEY_Control_L || event->keyval == GDK_KEY_Control_R)
    return FALSE;

// #define GDK_KEY_Alt_L 0xffe9
// #define GDK_KEY_Alt_R 0xffea
  if (event->keyval == GDK_KEY_Alt_L || event->keyval == GDK_KEY_Alt_R)
    return FALSE;

//   g_print ("minibuffer key pressed 0x%08x 0x%08x %s\n",
//            event->state, event->keyval, gdk_keyval_name (event->keyval));
//   gtkui__textview_keydown (event);

//   if (event->keyval == 0x71)
//     {
//       gtk_widget_destroy (frame);
//       gtk_main_quit ();
//     }

  guint keyval = event->keyval;

  if (keyval == 0xffe3 || keyval == 0xffe4) // Control_L, Control_R
    return FALSE;

  guint state = event->state;
  if (state & GDK_MOD1_MASK)
    keyval |= ALT_MASK;
  if (state & GDK_CONTROL_MASK)
    keyval |= CTRL_MASK;
  if (state & GDK_SHIFT_MASK)
    keyval |= SHIFT_MASK;

  gtkui_minibuffer_keydown (keyval);
  gtk_widget_queue_draw (minibuffer);

  return TRUE;
}

extern void gtkui_textview_paint (void);

void gtkui__textview_text_out (int x, int y, const char* s)
{
//   g_print ("gtkui__textview_text_out called\n");
  if (cr_textview)
    {
//       g_print ("rgb_textview_bg = 0x%08lx\n", rgb_textview_bg);
//       cairo_set_source_rgb (cr_textview,
//                             rgb_red (rgb_textview_bg),
//                             rgb_green (rgb_textview_bg),
//                             rgb_blue (rgb_textview_bg));
//       cairo_paint (cr_textview);

      if (rgb_textview_bg != 0) // REVIEW
        {
          cairo_save (cr_textview);
          cairo_set_source_rgb (cr_textview,
                                rgb_red (rgb_textview_bg),
                                rgb_green (rgb_textview_bg),
                                rgb_blue (rgb_textview_bg));
          cairo_rectangle (cr_textview,
                           x,
                           y - char_height + 3, // REVIEW
                           char_width * strlen (s),
                           char_height);
          cairo_clip (cr_textview);
          cairo_paint (cr_textview);
          cairo_restore (cr_textview);
        }

//       cairo_save (cr_textview);
      cairo_set_source_rgb (cr_textview,
                            rgb_red (rgb_textview_fg),
                            rgb_green (rgb_textview_fg),
                            rgb_blue (rgb_textview_fg));
      cairo_move_to (cr_textview, x, y);
      cairo_show_text (cr_textview, s);
//       cairo_restore (cr_textview);
    }
  else
    {
      g_print ("no cr\n");
    }
}

void gtkui__textview_clear_eol (int column, int row)
{
//   g_print("clear_eol column = %d row = %d rgb = 0x%08lx\n",
//           column, row, rgb_textview_bg);
  cairo_save (cr_textview);
  cairo_set_source_rgb (cr_textview,
                        rgb_red (rgb_textview_bg),
                        rgb_green (rgb_textview_bg),
                        rgb_blue (rgb_textview_bg));
  cairo_rectangle (cr_textview,
                   column * char_width,
                   row * char_height + 3, // REVIEW
                   textview_columns * char_width,
                   char_height);
  cairo_clip (cr_textview);
  cairo_paint (cr_textview);
  cairo_restore (cr_textview);
}

static void
gtkui__textview_draw_caret ()
{
  if (gtk_widget_is_focus (textview))
    {
      int x = char_width * textview_caret_column;
      int y = char_height * textview_caret_row;
    //   g_print ("drawing caret column = %d row = %d\n", caret_column, caret_row);
    //   g_print ("drawing caret x = %d y = %d\n", x, y);

      cairo_set_source_rgb (cr_textview, 1.0, 1.0, 1.0); // white
    //   cairo_set_source_rgb (cr, 1.0, 0.0, 0.0); // red

    //   cairo_set_line_width (cr, 1.0);
    //   cairo_move_to (cr, x, y);
    //   cairo_line_to (cr, x, y + char_height);

      cairo_rectangle (cr_textview, x, y + 3, 2, char_height);
      cairo_fill (cr_textview);

//       cairo_stroke (cr_textview);
    }
}

void gtkui__textview_invalidate (void)
{
  gtk_widget_queue_draw (textview);
  gtk_widget_queue_draw (modeline);
}

static gboolean
gtkui__textview_draw (GtkWidget *widget, cairo_t *cr, gpointer data)
{
  g_return_val_if_fail (widget == textview, FALSE);

  cr_textview = cr;

  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_NORMAL);
  cairo_set_font_size (cr, FERAL_DEFAULT_FONT_SIZE);

  if (char_width == 0)
    {
      cairo_font_extents_t fe;
      cairo_font_extents (cr, &fe);
      g_print ("ascent = %f  descent = %f\n", fe.ascent, fe.descent);
      g_print ("height = %f\n", fe.height);
      g_print ("max_x_advance = %f max_y_advance = %f\n",
               fe.max_x_advance, fe.max_x_advance);

      char_width = (int) fe.max_x_advance;
      char_height = (int) fe.height;
      g_print ("textview char_width = %d char_height = %d\n",
               char_width, char_height);

//       cairo_text_extents_t extents;
//       cairo_text_extents (cr, "test", &extents);
//       char_width = (int) extents.width / 4;
//       char_height = (int) extents.height;
//       g_print ("textview x_bearing = %f y_bearing = %f\n",
//                extents.x_bearing, extents.y_bearing);

      GtkAllocation allocation;
      gtk_widget_get_allocation (widget, &allocation);
//       g_print ("textview h = %d w = %d\n", allocation.height, allocation.width);

      textview_rows = allocation.height / char_height;
      textview_columns = allocation.width / char_width;
//       g_print ("textview %d rows, %d columns\n", textview_rows, textview_columns);

    }

  // black background
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
  cairo_paint (cr);

  // white text
  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);

//   cairo_set_source_rgb (cr,
//                         rgb_red (rgb_textview_fg),
//                         rgb_green (rgb_textview_fg),
//                         rgb_blue (rgb_textview_fg));

  gtkui_textview_paint ();

  gtkui__textview_draw_caret ();

  cr_textview = 0;
  return TRUE;
}

#if 0
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
#endif

static gboolean
on_modeline_draw (GtkWidget *widget, cairo_t *cr, gpointer data)
{
//   g_print ("on_modeline_draw called\n");

//   GtkAllocation allocation;
//   gtk_widget_get_allocation (widget, &allocation);
//   g_print ("modeline height = %d\n", allocation.height);

  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_NORMAL);

//   cairo_text_extents_t extents;
//   cairo_text_extents (cr, "test", &extents);
//   double char_width = extents.width / 4;
//   double char_height = extents.height;
//   g_print ("modeline char_width = %f char_height = %f\n", char_width, char_height);

  cairo_move_to (cr, 0, 14);
  cairo_set_font_size (cr, 14.0);
  // white background
  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);
  cairo_paint (cr);
  // black text
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
//   cairo_show_text (cr, " feline-mode.feline 1:1 (396)");
  cairo_show_text (cr, mode_line_text);
  return TRUE;
}

static void
gtkui__minibuffer_draw_caret (void)
{
  if (gtk_widget_is_focus (minibuffer))
    {
      cairo_set_source_rgb (cr_minibuffer, 1.0, 1.0, 1.0); // white

      cairo_rectangle (cr_minibuffer,
                       minibuffer_caret_column * char_width,
                       3,
                       2,
                       char_height);
      cairo_fill (cr_minibuffer);
    }
}

extern void gtkui_minibuffer_paint (void);

static gboolean
gtkui__minibuffer_draw (GtkWidget *widget, cairo_t *cr, gpointer data)
{
//   g_print ("gtkui__minibuffer_draw called\n");

  cr_minibuffer = cr;

  GtkAllocation allocation;
  gtk_widget_get_allocation (widget, &allocation);
//   g_print ("minibuffer height = %d\n", allocation.height);

  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_NORMAL);

  cairo_text_extents_t extents;
  cairo_text_extents (cr, "test", &extents);
//   double char_width = extents.width / 4;
//   double char_height = extents.height;
//   g_print ("minibuffer char_width = %f char_height = %f\n", char_width, char_height);

//   cairo_move_to (cr, 0, 14);
  cairo_set_font_size (cr, 14.0);
  // black background
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
  cairo_paint (cr);
  // white text
  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);
//   cairo_show_text (cr, "This is a test!");
  gtkui_minibuffer_paint ();

//   if (gtk_widget_is_focus (minibuffer))
//     {
// //       g_print ("minibuffer has focus!\n");
// //       cairo_set_source_rgb (cr, 1.0, 1.0, 1.0); // white
//       cairo_set_source_rgb (cr, 1.0, 0.0, 0.0); // red
//
//       //   cairo_set_line_width (cr, 1.0);
//       //   cairo_move_to (cr, x, y);
//       //   cairo_line_to (cr, x, y + char_height);
//
// //       g_print ("caret_column = %d\n", caret_column);
//
//       cairo_rectangle (cr,
//                        minibuffer_caret_column * char_width,
//                        0,
//                        2.0,
//                        char_height);
//       cairo_fill (cr);
// //       cairo_paint (cr);
// //       cairo_stroke (cr);
//     }
//
  gtkui__minibuffer_draw_caret ();

  cr_minibuffer = 0;

//   g_print ("gtkui__minibuffer_draw returning\n");

  return TRUE;
}

void gtkui__textview_set_caret_pos (int column, int row)
{
  textview_caret_column = column;
  textview_caret_row = row;
}

void gtkui__minibuffer_main (void)
{
//   minibuffer_exit = FALSE;

//   SetFocus (hwnd_minibuffer);

//   BOOL ret;
//   MSG msg;
//   while ((ret = GetMessage (&msg, NULL, 0, 0)) != 0
//          && ret != -1
//          && minibuffer_exit == FALSE)
//     {
//       TranslateMessage (&msg);
//       DispatchMessage (&msg);
//     }

//   SetFocus (hwnd_textview);
//   g_print ("gtkui__minibuffer_main called\n");
  gtk_widget_queue_draw (minibuffer);
  gtk_widget_grab_focus (minibuffer);

  // nested call to gtk_main
  gtk_main ();

//   g_print ("gtkui__minibuffer_main returning\n");

  gtk_widget_grab_focus (textview);
}

void gtkui__minibuffer_exit (void)
{
//   g_print ("gtkui__minibuffer_exit called\n");
  // return from nested call to gtk_main
  gtk_main_quit();
}

void gtkui__minibuffer_text_out (int x, int y, const char* s)
{
  if (*s == 0) // empty string
    return;

//   g_print ("gtkui__minibuffer_text_out called\n");
//   g_print ("x = %d y = %d s = |%s|\n", x, y, s);
  if (cr_minibuffer)
    {
      cairo_move_to (cr_minibuffer, x, y);
      cairo_show_text (cr_minibuffer, s);
    }
  else
    {
      g_print ("gtkui__minibuffer_text_out no cr\n");
    }
}

void gtkui__minibuffer_set_caret_pos (int column, int row)
{
  minibuffer_caret_column = column;
  minibuffer_caret_row = row;
}
