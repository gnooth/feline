// Copyright (C) 2019-2020 Peter Graves <gnooth@gmail.com>

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
#define FERAL_DEFAULT_FRAME_HEIGHT      600

#define FERAL_DEFAULT_FONT_SIZE         14.0

#define FERAL_DEFAULT_MODELINE_HEIGHT   20
#define FERAL_DEFAULT_MINIBUFFER_HEIGHT 24

#define FERAL_DEFAULT_TEXTVIEW_HEIGHT \
 (FERAL_DEFAULT_FRAME_HEIGHT - \
  FERAL_DEFAULT_MODELINE_HEIGHT - \
  FERAL_DEFAULT_MINIBUFFER_HEIGHT)

static int ascent = 0;
static int descent = 0;
static int char_width = 0;
static int char_height = 0;

static int textview_rows = 0;
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

static gboolean gtkui__textview_mousewheel (GtkWidget *widget,
                                            GdkEventScroll *event,
                                            gpointer data);

static gboolean gtkui__textview_button_press (GtkWidget *widget,
                                              GdkEventButton *event,
                                              gpointer data);

static gboolean gtkui__textview_motion_notify (GtkWidget *widget,
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

static gboolean gtkui__textview_size_allocate (GtkWidget *widget,
                                               GdkRectangle* allocation,
                                               gpointer data);

static gboolean gtkui__textview_realize (GtkWidget *widget,
                                         gpointer data);

static gboolean gtkui__frame_configure (GtkWidget *widget,
                                        GdkEventConfigure *event,
                                        gpointer data);

// gtkui.asm
extern void gtkui_close (void);

static gboolean
gtkui__close (GtkWidget *widget, GdkEvent *event, gpointer data)
{
  gtkui_close ();
  return TRUE;
}

void gtkui__initialize (void)
{
  gtk_init(0,  NULL);

  frame = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title (GTK_WINDOW (frame), "Feral");
  gtk_window_set_default_size (GTK_WINDOW (frame),
                               FERAL_DEFAULT_FRAME_WIDTH,
                               FERAL_DEFAULT_FRAME_HEIGHT);

  g_signal_connect (frame, "configure-event",
                    G_CALLBACK (gtkui__frame_configure), NULL);

  g_signal_connect (frame, "delete-event", G_CALLBACK (gtkui__close), NULL);

  GtkBox *box = GTK_BOX (gtk_box_new (GTK_ORIENTATION_VERTICAL, 0));
  gtk_container_add (GTK_CONTAINER (frame), GTK_WIDGET(box));

  textview = gtk_drawing_area_new();

  gtk_widget_set_size_request (textview, -1, -1);

  gtk_widget_set_can_focus (textview, TRUE);

  gtk_widget_set_events (textview,
                         GDK_BUTTON_PRESS_MASK |
                         GDK_POINTER_MOTION_MASK |
                         GDK_SCROLL_MASK |
                         GDK_KEY_PRESS_MASK
                         );

  g_signal_connect (textview, "draw",
                    G_CALLBACK (gtkui__textview_draw), NULL);
  g_signal_connect (textview, "key-press-event",
                    G_CALLBACK(gtkui__textview_key_press), NULL);
  g_signal_connect (textview, "button-press-event",
                    G_CALLBACK(gtkui__textview_button_press), NULL);
  g_signal_connect (textview, "motion-notify-event",
                    G_CALLBACK(gtkui__textview_motion_notify),  NULL);
  g_signal_connect (textview, "scroll-event",
                    G_CALLBACK(gtkui__textview_mousewheel), NULL);
  g_signal_connect (textview, "size-allocate",
                    G_CALLBACK (gtkui__textview_size_allocate), NULL);
  g_signal_connect (textview, "realize",
                    G_CALLBACK (gtkui__textview_realize), NULL);

  modeline = gtk_drawing_area_new();

  gtk_widget_set_size_request (modeline,
                               -1,
                               FERAL_DEFAULT_MODELINE_HEIGHT);

  gtk_widget_set_can_focus (modeline, TRUE);

  gtk_widget_set_events (modeline, GDK_KEY_PRESS_MASK);

  g_signal_connect (modeline, "draw",
                    G_CALLBACK (on_modeline_draw), NULL);

  minibuffer = gtk_drawing_area_new();

  gtk_widget_set_size_request (minibuffer,
                               -1,
                               FERAL_DEFAULT_MINIBUFFER_HEIGHT);

  gtk_widget_set_can_focus (minibuffer, TRUE);

  gtk_widget_set_events (minibuffer,
                         GDK_BUTTON_PRESS_MASK | GDK_KEY_PRESS_MASK );

  g_signal_connect (minibuffer, "draw",
                    G_CALLBACK (gtkui__minibuffer_draw), NULL);

  g_signal_connect (minibuffer, "key-press-event",
                    G_CALLBACK (on_minibuffer_key_press), NULL);

  gtk_box_pack_end (box, minibuffer, FALSE, FALSE, 0);
  gtk_box_pack_end (box, modeline, FALSE, FALSE, 0);
  gtk_box_pack_end (box, textview, TRUE, TRUE, 0);

  // REVIEW
  gtk_window_move (GTK_WINDOW (frame), 480, 0);

  gtk_widget_show_all (frame);
}

void gtkui__textview_invalidate (void)
{
  gtk_widget_queue_draw (textview);
  gtk_widget_queue_draw (modeline);
}

void gtkui__minibuffer_invalidate (void)
{
  gtk_widget_queue_draw (minibuffer);
}

static gboolean gtkui__textview_size_allocate (GtkWidget *widget,
                                               GdkRectangle *allocation,
                                               gpointer data)
{
  if (char_height)
    textview_rows = allocation->height / char_height;
  if (char_width)
    textview_columns = allocation->width / char_width;
  return TRUE;
}

static gboolean gtkui__textview_realize (GtkWidget *widget,
                                         gpointer data)
{
  GdkCursor *cursor = gdk_cursor_new_from_name (gdk_display_get_default (),
                                                "text");
  gdk_window_set_cursor (gtk_widget_get_window (textview), cursor);
}

static gboolean gtkui__frame_configure (GtkWidget *widget,
                                        GdkEventConfigure *event,
                                        gpointer data)
{
  gtk_widget_queue_resize (textview);
  return TRUE;
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

// gtkui.asm
extern void gtkui_textview_keydown (guint);
extern void gtkui_textview_button_press (int, int);
extern void gtkui_textview_mousemove (int, int);

#define ALT_MASK        0x01 << 16
#define CTRL_MASK       0x02 << 16
#define SHIFT_MASK      0x04 << 16

static void gtkui__textview_keydown (GdkEventKey *event)
{
  guint keyval = event->keyval;
  guint state = event->state;
  if (state & GDK_MOD1_MASK)
    keyval |= ALT_MASK;
  if (state & GDK_CONTROL_MASK)
    keyval |= CTRL_MASK;
  if (state & GDK_SHIFT_MASK)
    keyval |= SHIFT_MASK;
  gtkui_textview_keydown (keyval);
  gtk_widget_queue_draw (frame);
}

static gboolean
gtkui__textview_button_press (GtkWidget *widget,
                              GdkEventButton *event,
                              gpointer data)
{
  if (event->type == GDK_2BUTTON_PRESS)
    {
      guint keyval = GDK_KEY_Pointer_DblClick1;
      guint state = event->state;
      if (state & GDK_MOD1_MASK)
        keyval |= ALT_MASK;
      if (state & GDK_CONTROL_MASK)
        keyval |= CTRL_MASK;
      if (state & GDK_SHIFT_MASK)
        keyval |= SHIFT_MASK;
      gtkui_textview_keydown (keyval);
    }
  else
    gtkui_textview_button_press (event->x, event->y);
  return TRUE;
}

static gboolean
gtkui__textview_motion_notify (GtkWidget *widget,
                               GdkEventButton *event,
                               gpointer data)
{
  if (event->state & GDK_BUTTON1_MASK)
    {
      gtkui_textview_mousemove (event->x, event->y);
      return TRUE;
    }
  else
    return FALSE;
}

extern void gtkui_textview_mousewheel (cell);

static gboolean
gtkui__textview_mousewheel (GtkWidget *widget,
                            GdkEventScroll *event,
                            gpointer data)
{
  if (event->direction == GDK_SCROLL_UP)
    gtkui_textview_mousewheel (1);
  else if (event->direction == GDK_SCROLL_DOWN)
    gtkui_textview_mousewheel (-1);
  gtkui__textview_invalidate ();
  return TRUE;
}

static gboolean
gtkui__textview_key_press (GtkWidget *widget,
                           GdkEventKey *event,
                           gpointer data)
{
  if (event->keyval == GDK_KEY_Control_L || event->keyval == GDK_KEY_Control_R)
    return FALSE;
  if (event->keyval == GDK_KEY_Alt_L || event->keyval == GDK_KEY_Alt_R)
    return FALSE;
  if (event->keyval == GDK_KEY_Shift_L || event->keyval == GDK_KEY_Shift_R)
    return FALSE;
  gtkui__textview_keydown (event);
  return TRUE;
}

extern void gtkui_minibuffer_keydown (guint);

static gboolean
on_minibuffer_key_press (GtkWidget *widget, GdkEventKey *event, gpointer data)
{
  if (event->keyval == GDK_KEY_Control_L || event->keyval == GDK_KEY_Control_R)
    return FALSE;
  if (event->keyval == GDK_KEY_Alt_L || event->keyval == GDK_KEY_Alt_R)
    return FALSE;

  guint keyval = event->keyval;

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

void
gtkui__textview_text_out (int column, int row, const char* s)
{
  int x = column * char_width;
  int y = (row + 1) * char_height;

  if (cr_textview)
    {
      if (rgb_textview_bg != 0) // REVIEW
        {
          cairo_save (cr_textview);
          cairo_set_source_rgb (cr_textview,
                                rgb_red (rgb_textview_bg),
                                rgb_green (rgb_textview_bg),
                                rgb_blue (rgb_textview_bg));
          cairo_rectangle (cr_textview,
                           x,
                           y - ascent,
                           char_width * strlen (s),
                           char_height);
          cairo_clip (cr_textview);
          cairo_paint (cr_textview);
          cairo_restore (cr_textview);
        }

      cairo_set_source_rgb (cr_textview,
                            rgb_red (rgb_textview_fg),
                            rgb_green (rgb_textview_fg),
                            rgb_blue (rgb_textview_fg));
      cairo_move_to (cr_textview, x, y);
      cairo_show_text (cr_textview, s);
    }
  else
    {
      g_print ("no cr\n");
    }
}

void
gtkui__textview_clear_eol (int column, int row)
{
  cairo_save (cr_textview);
  cairo_set_source_rgb (cr_textview,
                        rgb_red (rgb_textview_bg),
                        rgb_green (rgb_textview_bg),
                        rgb_blue (rgb_textview_bg));
  cairo_rectangle (cr_textview,
                   column * char_width,
                   (row + 1) * char_height - ascent,
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
      cairo_set_source_rgb (cr_textview, 1.0, 1.0, 1.0); // white
      cairo_rectangle (cr_textview, x, y + descent, 2, char_height);
      cairo_fill (cr_textview);
    }
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

      ascent = (int) fe.ascent;
      descent = (int) fe.descent;
      char_width = (int) fe.max_x_advance;
      char_height = ascent + descent + 1;

      GtkAllocation allocation;
      gtk_widget_get_allocation (widget, &allocation);

      textview_rows = allocation.height / char_height;
      textview_columns = allocation.width / char_width;
    }

  // black background
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
  cairo_paint (cr);

  // white text
  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);

  gtkui_textview_paint ();

  gtkui__textview_draw_caret ();

  cr_textview = 0;
  return TRUE;
}

static gboolean
on_modeline_draw (GtkWidget *widget, cairo_t *cr, gpointer data)
{
  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_NORMAL);

  cairo_move_to (cr, 0, 14);
  cairo_set_font_size (cr, 14.0);
  // white background
  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);
  cairo_paint (cr);
  // black text
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
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
  cr_minibuffer = cr;

  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_NORMAL);

  cairo_set_font_size (cr, 14.0);

  // black background
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
  cairo_paint (cr);

  // white text
  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);
  gtkui_minibuffer_paint ();

  gtkui__minibuffer_draw_caret ();

  cr_minibuffer = 0;

  return TRUE;
}

void gtkui__textview_set_caret_pos (int column, int row)
{
  textview_caret_column = column;
  textview_caret_row = row;
}

void gtkui__frame_maximize ()
{
  gtk_window_maximize (GTK_WINDOW (frame));
}

void gtkui__frame_unmaximize ()
{
  gtk_window_unmaximize (GTK_WINDOW (frame));
}

void gtkui__frame_toggle_fullscreen ()
{
  if (gtk_window_is_maximized (GTK_WINDOW (frame)))
    gtk_window_unmaximize (GTK_WINDOW (frame));
  else
    gtk_window_maximize (GTK_WINDOW (frame));
}

void gtkui__frame_set_text (const char *s)
{
  gtk_window_set_title (GTK_WINDOW (frame), s);
}

void gtkui__modeline_set_text (const char *s)
{
  mode_line_text = s;
}

void gtkui__minibuffer_main (void)
{
  gtk_widget_grab_focus (minibuffer);

  // nested call to gtk_main
  gtk_main ();

  gtk_widget_grab_focus (textview);
}

void gtkui__minibuffer_exit (void)
{
  // return from nested call to gtk_main
  gtk_main_quit();
}

void gtkui__minibuffer_text_out (int x, int y, const char* s)
{
  if (*s == 0) // empty string
    return;

  if (cr_minibuffer)
    {
      cairo_move_to (cr_minibuffer, x, y);
      cairo_show_text (cr_minibuffer, s);
    }
  else
    g_print ("gtkui__minibuffer_text_out no cr\n");
}

void gtkui__minibuffer_set_caret_pos (int column, int row)
{
  minibuffer_caret_column = column;
  minibuffer_caret_row = row;
}
