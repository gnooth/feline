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

static gboolean
key_press_callback (GtkWidget *widget, GdkEventKey *event, gpointer data)
{
  g_print ("key pressed 0x%08x 0x%08x %s\n", event->state, event->keyval,
           gdk_keyval_name (event->keyval));
  return TRUE;
}

static gboolean
draw_callback (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
  g_print ("draw_callback called\n");
  cairo_move_to (cr, 40, 40);
  cairo_set_font_size (cr, 16.0);
  cairo_show_text (cr, "This is a test!");
  return TRUE;
}

void gtkui__initialize (void)
{
  gtk_init(0,  NULL);
  GtkWidget *window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title (GTK_WINDOW (window), "Feral");
  gtk_window_set_default_size (GTK_WINDOW (window), 400, 400);

  GtkWidget *drawing_area = gtk_drawing_area_new();
  gtk_widget_set_size_request (drawing_area, 400, 400);
  gtk_container_add (GTK_CONTAINER (window), drawing_area);
  gtk_widget_set_can_focus (drawing_area, TRUE);

  gtk_widget_set_events (drawing_area,
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

  g_signal_connect (drawing_area, "draw", G_CALLBACK (draw_callback), NULL);
  g_signal_connect (drawing_area, "key-press-event",
                    G_CALLBACK(key_press_callback), NULL);

  gtk_widget_show_all (window);

//   gtk_main ();
}
