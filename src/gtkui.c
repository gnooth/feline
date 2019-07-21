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

static int char_width;
static int char_height;

static int textview_rows;
static int textview_columns;

static GtkWidget *frame;

static GtkWidget *textview;
static GtkWidget *minibuffer;

static cairo_t *cr_textview;
static cairo_t *cr_minibuffer;

// static int rgb_textview_fg = RGB (192, 192, 192);
// static int rgb_textview_bg = 0;

static const char *mode_line_text;

static int caret_row;
static int caret_column;

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
//   rgb_textview_fg = rgb;
}

void gtkui__textview_set_bg_color (int rgb)
{
//   rgb_textview_bg = rgb;
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

  if (keyval == 0xffe3 || keyval == 0xffe4) // Control_L, Control_R
    return;

  guint state = event->state;
  if (state & GDK_MOD1_MASK)
    keyval |= ALT_MASK;
  if (state & GDK_CONTROL_MASK)
    keyval |= CTRL_MASK;
  if (state & GDK_SHIFT_MASK)
    keyval |= SHIFT_MASK;
  g_print ("gtkui__textview_keydown keyval = 0x%08x\n", keyval);
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
on_textview_key_press (GtkWidget *widget, GdkEventKey *event, gpointer data)
{
// #define GDK_KEY_Control_L 0xffe3
// #define GDK_KEY_Control_R 0xffe4
  if (event->keyval == GDK_KEY_Control_L || event->keyval == GDK_KEY_Control_R)
    return FALSE;

// #define GDK_KEY_Alt_L 0xffe9
// #define GDK_KEY_Alt_R 0xffea
  if (event->keyval == GDK_KEY_Alt_L || event->keyval == GDK_KEY_Alt_R)
    return FALSE;

//   g_print ("key pressed 0x%08x 0x%08x %s\n", event->state, event->keyval,
//            gdk_keyval_name (event->keyval));
  gtkui__textview_keydown (event);
  if (event->keyval == 0x71)
    {
      gtk_widget_destroy (frame);
      gtk_main_quit ();
    }
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

  g_print ("minibuffer key pressed 0x%08x 0x%08x %s\n",
           event->state, event->keyval, gdk_keyval_name (event->keyval));
//   gtkui__textview_keydown (event);

  if (event->keyval == 0x71)
    {
      gtk_widget_destroy (frame);
      gtk_main_quit ();
    }

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
      cairo_move_to (cr_textview, x, y);
      cairo_show_text (cr_textview, s);
    }
  else
    {
      g_print ("no cr\n");
    }
}

static gboolean
on_textview_draw (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
//   g_print ("on_textview_draw called\n");

  cr_textview = cr;

//   gtkui_textview_paint ();

  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_NORMAL);
  cairo_set_font_size (cr, 14.0);

  if (char_width == 0)
    {
      cairo_font_extents_t fe;
      cairo_font_extents (cr, &fe);
//       g_print ("ascent = %f  descent = %f\n", fe.ascent, fe.descent);
//       g_print ("height = %f\n", fe.height);
//       g_print ("max_x_advance = %f max_y_advance = %f\n",
//                fe.max_x_advance, fe.max_x_advance);

      char_width = (int) fe.max_x_advance;
      char_height = (int) fe.height;
//       g_print ("textview char_width = %d char_height = %d\n",
//                char_width, char_height);

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
//   cairo_move_to (cr, 0, char_height * 1);
//   cairo_show_text (cr, "This is a test line 1");
#if 0
  gtkui__textview_text_out (0, char_height * 1, "This is a real test line 1");
  gtkui__textview_text_out (0, char_height * 2, "This is a real test line 2");
#endif
  gtkui_textview_paint ();
//   cairo_move_to (cr, 0, char_height * 2);
//   cairo_show_text (cr, "This is a test line 2");
//   cairo_move_to (cr, 48, 0);
//   cairo_show_text (cr, "This is a test line 3");

  int x = char_width * caret_column;
  int y = char_height * caret_row;
//   g_print ("drawing caret column = %d row = %d\n", caret_column, caret_row);
//   g_print ("drawing caret x = %d y = %d\n", x, y);

  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0); // white
//   cairo_set_source_rgb (cr, 1.0, 0.0, 0.0); // red

//   cairo_set_line_width (cr, 1.0);
//   cairo_move_to (cr, x, y);
//   cairo_line_to (cr, x, y + char_height);

  cairo_rectangle (cr, x, y, 2.0, char_height);
  cairo_fill (cr);

  cairo_stroke (cr);

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
modeline_draw_callback (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
//   g_print ("modeline_draw_callback called\n");

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

extern void gtkui_minibuffer_paint (void);

static gboolean
on_minibuffer_draw (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
  g_print ("on_minibuffer_draw called\n");

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

  if (gtk_widget_is_focus (minibuffer))
    {
      g_print ("minibuffer has focus!\n");
//       cairo_set_source_rgb (cr, 1.0, 1.0, 1.0); // white
      cairo_set_source_rgb (cr, 1.0, 0.0, 0.0); // red

      //   cairo_set_line_width (cr, 1.0);
      //   cairo_move_to (cr, x, y);
      //   cairo_line_to (cr, x, y + char_height);

      cairo_rectangle (cr,
                       0,
                       0,
                       2.0,
                       char_height);
      cairo_fill (cr);
      cairo_paint (cr);
//       cairo_stroke (cr);
    }

  cr_minibuffer = 0;

//   g_print ("on_minibuffer_draw returning\n");

  return TRUE;
}

void gtkui__initialize (void)
{
  gtk_init(0,  NULL);

  frame = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title (GTK_WINDOW (frame), "Feral");
  gtk_window_set_default_size (GTK_WINDOW (frame), 800, 600);

  GtkBox *box = GTK_BOX (gtk_box_new (GTK_ORIENTATION_VERTICAL, 0));
  gtk_container_add (GTK_CONTAINER (frame), GTK_WIDGET(box));

  GtkWidget *drawing_area_1 = gtk_drawing_area_new();
  textview = drawing_area_1;

  gtk_widget_set_size_request (drawing_area_1, 800, 568);
//   gtk_container_add (GTK_CONTAINER (box), drawing_area_1);
  gtk_widget_set_can_focus (drawing_area_1, TRUE);

  gtk_widget_set_events (drawing_area_1,
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

  g_signal_connect (drawing_area_1, "draw",
                    G_CALLBACK (on_textview_draw), NULL);
  g_signal_connect (drawing_area_1, "key-press-event",
                    G_CALLBACK(on_textview_key_press), NULL);
//   g_signal_connect (drawing_area_1, "size-allocate",
//                     G_CALLBACK (on_size_allocate), NULL);

  GtkWidget *drawing_area_2 = gtk_drawing_area_new();
  gtk_widget_set_size_request (drawing_area_2, 568, 16);
//   gtk_container_add (GTK_CONTAINER (box), drawing_area_2);
  gtk_widget_set_can_focus (drawing_area_2, TRUE);

  gtk_widget_set_events (drawing_area_2,
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

  g_signal_connect (drawing_area_2, "draw",
                    G_CALLBACK (modeline_draw_callback), NULL);
//   g_signal_connect (drawing_area_2, "key-press-event",
//                     G_CALLBACK(key_press_callback), NULL);

  // drawing_area_3 is the minibuffer
  GtkWidget *drawing_area_3 = gtk_drawing_area_new();
  minibuffer = drawing_area_3;
  gtk_widget_set_size_request (drawing_area_3, 584, 16);
//   gtk_container_add (GTK_CONTAINER (box), drawing_area_3);
  gtk_widget_set_can_focus (drawing_area_3, TRUE);

  gtk_widget_set_events (drawing_area_3,
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

  g_signal_connect (drawing_area_3, "draw",
                    G_CALLBACK (on_minibuffer_draw), NULL);
  g_signal_connect (drawing_area_3, "key-press-event",
                    G_CALLBACK (on_minibuffer_key_press), NULL);
  //   g_signal_connect (drawing_area_3, "key-press-event",
  //                     G_CALLBACK(key_press_callback), NULL);

//   gtk_container_add (GTK_CONTAINER (box), drawing_area_1);
//   gtk_container_add (GTK_CONTAINER (box), drawing_area_2);
//   gtk_container_add (GTK_CONTAINER (box), drawing_area_3);
  gtk_box_pack_end (box, drawing_area_3, FALSE, FALSE, 0);
  gtk_box_pack_end (box, drawing_area_2, FALSE, FALSE, 0);
  gtk_box_pack_end (box, drawing_area_1, FALSE, FALSE, 0);

  gtk_widget_show_all (frame);
//   g_print ("leaving gtkui__initialize\n");
  gtk_main ();
}

void gtkui__set_caret_pos (int column, int row)
{
  caret_column = column;
  caret_row = row;
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
  g_print ("gtkui__minibuffer_main called\n");
  gtk_widget_queue_draw (minibuffer);
  gtk_widget_grab_focus (minibuffer);

  // nested call to gtk_main
  gtk_main ();

  g_print ("gtkui__minibuffer_main returning\n");

  gtk_widget_grab_focus (textview);
}

void gtkui__minibuffer_exit (void)
{
  g_print ("gtkui__minibuffer_exit called\n");
  // return from nested call to gtk_main
  gtk_main_quit();
}

void gtkui__minibuffer_text_out (int x, int y, const char* s)
{
  if (*s == 0) // empty string
    return;

  g_print ("gtkui__minibuffer_text_out called\n");
  g_print ("x = %d y = %d s = |%s|\n", x, y, s);
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
