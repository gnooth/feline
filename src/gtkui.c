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

static GtkWidget *window;

static gboolean
key_press_callback (GtkWidget *widget, GdkEventKey *event, gpointer data)
{
  g_print ("key pressed 0x%08x 0x%08x %s\n", event->state, event->keyval,
           gdk_keyval_name (event->keyval));
  if (event->keyval == 0x71)
    {
      gtk_widget_destroy (window);
      gtk_main_quit ();
    }
  return TRUE;
}

static gboolean
textview_draw_callback (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
  g_print ("textview_draw_callback called\n");

  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_NORMAL);

  cairo_move_to (cr, 40, 40);
  cairo_set_font_size (cr, 14.0);
  // black background
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
  cairo_paint (cr);
  // white text
  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);
  cairo_show_text (cr, "This is a test!");
  return TRUE;
}

static gboolean
modeline_draw_callback (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
  g_print ("modeline_draw_callback called\n");

  GtkAllocation allocation;
  gtk_widget_get_allocation (widget, &allocation);
  g_print ("modeline height = %d\n", allocation.height);

  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_BOLD);

  cairo_text_extents_t extents;
  cairo_text_extents (cr, "test", &extents);
  double char_width = extents.width / 4;
  double char_height = extents.height;
  g_print ("char_width = %f char_height = %f\n", char_width, char_height);

  cairo_move_to (cr, 0, 10);
  cairo_set_font_size (cr, 14.0);
  // white background
  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);
  cairo_paint (cr);
  // black text
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
  cairo_show_text (cr, "This is a test!");
  return TRUE;
}

static gboolean
minibuffer_draw_callback (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
  g_print ("minibuffer_draw_callback called\n");

  cairo_select_font_face (cr, "monospace",
                          CAIRO_FONT_SLANT_NORMAL,
                          CAIRO_FONT_WEIGHT_NORMAL);

  cairo_text_extents_t extents;
  cairo_text_extents (cr, "test", &extents);
  double char_width = extents.width / 4;
  double char_height = extents.height;
  g_print ("char_width = %f char_height = %f\n", char_width, char_height);

  cairo_move_to (cr, 0, 10);
  cairo_set_font_size (cr, 14.0);
  // black background
  cairo_set_source_rgb (cr, 0.0, 0.0, 0.0);
  cairo_paint (cr);
  // white text
  cairo_set_source_rgb (cr, 1.0, 1.0, 1.0);
  cairo_show_text (cr, "This is a test!");
  return TRUE;
}

void gtkui__initialize (void)
{
  gtk_init(0,  NULL);

  window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title (GTK_WINDOW (window), "Feral");
  gtk_window_set_default_size (GTK_WINDOW (window), 800, 600);

  GtkWidget *box = gtk_box_new (GTK_ORIENTATION_VERTICAL, 1);
  gtk_container_add (GTK_CONTAINER (window), box);

  GtkWidget *drawing_area_1 = gtk_drawing_area_new();
  gtk_widget_set_size_request (drawing_area_1, 800, 576);
  gtk_container_add (GTK_CONTAINER (box), drawing_area_1);
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
                    G_CALLBACK (textview_draw_callback), NULL);
  g_signal_connect (drawing_area_1, "key-press-event",
                    G_CALLBACK(key_press_callback), NULL);

  GtkWidget *drawing_area_2 = gtk_drawing_area_new();
  gtk_widget_set_size_request (drawing_area_2, 576, 12);
  gtk_container_add (GTK_CONTAINER (box), drawing_area_2);
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

  GtkWidget *drawing_area_3 = gtk_drawing_area_new();
  gtk_widget_set_size_request (drawing_area_3, 588, 12);
  gtk_container_add (GTK_CONTAINER (box), drawing_area_3);
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
                    G_CALLBACK (minibuffer_draw_callback), NULL);
  //   g_signal_connect (drawing_area_3, "key-press-event",
  //                     G_CALLBACK(key_press_callback), NULL);

  gtk_widget_show_all (window);
  g_print ("leaving gtkui__initialize\n");
  gtk_main ();
}
