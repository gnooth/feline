; Copyright (C) 2019-2020 Peter Graves <gnooth@gmail.com>

; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

file __FILE__

asm_global gtkui_raw_sp0_, 0

; ### gtkui-initialize
code gtkui_initialize, 'gtkui-initialize'

        _ current_thread_raw_sp0
        mov     [gtkui_raw_sp0_], rbx
        _drop

        extern  gtkui__initialize
        xcall   gtkui__initialize

        next
endcode

; ### gtkui-main
code gtkui_main, 'gtkui-main'           ; void -> void
        extern  gtkui__main
        xcall   gtkui__main
        next
endcode

; ### gtkui_close
subroutine gtkui_close                  ; void -> void
; 0-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [gtkui_raw_sp0_]

        _quote "do-quit"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### gtkui-exit
code gtkui_exit, 'gtkui-exit'
        extern  gtkui__exit
        xcall   gtkui__exit
        next
endcode

; ### gtkui-textview-rows
code gtkui_textview_rows, 'gtkui-textview-rows' ; void -> fixnum
        extern  gtkui__textview_rows
        xcall   gtkui__textview_rows
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### gtkui-textview-columns
code gtkui_textview_columns, 'gtkui-textview-columns' ; void -> fixnum
        extern  gtkui__textview_columns
        xcall   gtkui__textview_columns
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### textview-set-fg-color
code gtkui_textview_set_fg_color, 'textview-set-fg-color' ; color -> void
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
        extern  gtkui__textview_set_fg_color
        xcall   gtkui__textview_set_fg_color
        next
endcode

; ### textview-set-bg-color
code gtkui_textview_set_bg_color, 'textview-set-bg-color' ; color -> void
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
        extern  gtkui__textview_set_bg_color
        xcall   gtkui__textview_set_bg_color
        next
endcode

; ### textview-char-width
code gtkui_char_width, 'textview-char-width' ; void -> fixnum
        extern  gtkui__char_width
        xcall   gtkui__char_width
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### textview-char-height
code gtkui_char_height, 'textview-char-height' ; void -> fixnum
        extern  gtkui__char_height
        xcall   gtkui__char_height
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### frame-set-text
code gtkui_frame_set_text, 'frame-set-text' ; string -> void
        _ string_raw_data_address
        mov     arg0_register, rbx
        _drop

        extern gtkui__frame_set_text
        xcall  gtkui__frame_set_text

        next
endcode

; ### modeline-set-text
code gtkui_modeline_set_text, 'modeline-set-text' ; string -> void
        _ string_raw_data_address
        mov     arg0_register, rbx
        poprbx

        extern  gtkui__modeline_set_text
        xcall   gtkui__modeline_set_text

        next
endcode

; ### textview-text-out
code gtkui_textview_text_out, 'textview-text-out' ; column row string -> void
        _ string_raw_data_address
        mov     arg2_register, rbx
        poprbx
        _ check_fixnum
        mov     arg1_register, rbx
        poprbx
        _ check_fixnum
        mov     arg0_register, rbx
        poprbx

        extern  gtkui__textview_text_out
        xcall   gtkui__textview_text_out

        next
endcode

; ### textview-clear-eol
code gtkui_textview_clear_eol, 'textview-clear-eol' ; column row -> void
        _check_fixnum
        mov     arg1_register, rbx
        poprbx
        _check_fixnum
        mov     arg0_register, rbx
        poprbx

        extern  gtkui__textview_clear_eol
        xcall   gtkui__textview_clear_eol

        next
endcode

; ### gtkui-textview-invalidate
code gtkui_textview_invalidate, 'gtkui-textview-invalidate'

        extern  gtkui__textview_invalidate
        xcall   gtkui__textview_invalidate

        next
endcode

; ### gtkui-minibuffer-invalidate
code gtkui_minibuffer_invalidate, 'gtkui-minibuffer-invalidate' ; void -> void
        extern  gtkui__minibuffer_invalidate
        xcall   gtkui__minibuffer_invalidate
        next
endcode

; ### gtkui_textview_paint
subroutine gtkui_textview_paint         ; void -> void
; 0-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [gtkui_raw_sp0_]

        _quote "repaint"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### gtkui_textview_keydown
subroutine gtkui_textview_keydown       ; keyval -> void
; 1-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [gtkui_raw_sp0_]

        pushrbx
        mov     rbx, arg0_register
        _tag_fixnum

        _quote "gtkui-textview-keydown"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### gtkui_textview_button_press
subroutine gtkui_textview_button_press  ; x y -> void
; 2-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [gtkui_raw_sp0_]

        pushrbx
        mov     rbx, arg0_register      ; x
        _tag_fixnum
        pushrbx
        mov     rbx, arg1_register      ; y
        _tag_fixnum

        _quote "gtkui-textview-button-press"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### gtkui_textview_mousemove
subroutine gtkui_textview_mousemove     ; x y -> void
; 2-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [gtkui_raw_sp0_]

        pushrbx
        mov     rbx, arg0_register      ; x
        _tag_fixnum
        pushrbx
        mov     rbx, arg1_register      ; y
        _tag_fixnum

        _quote "gtkui-textview-mousemove"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### gtkui_textview_mousewheel
subroutine gtkui_textview_mousewheel    ; +1/-1 -> void
; 1-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [gtkui_raw_sp0_]

        test    arg0_register, arg0_register
        js      .1

        _quote "mousewheel-scroll-up"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol
        jmp     .exit

.1:
        _quote "mousewheel-scroll-down"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

.exit:
        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### textview-set-caret-pos
code gtkui_textview_set_caret_pos, 'textview-set-caret-pos' ; x y -> void
        _check_fixnum
        mov     arg1_register, rbx
        poprbx
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
        extern  gtkui__textview_set_caret_pos
        xcall   gtkui__textview_set_caret_pos
        next
endcode

; ### gtkui-minibuffer-main
code gtkui_minibuffer_main, 'gtkui-minibuffer-main' ; void -> void
        extern  gtkui__minibuffer_main
        xcall   gtkui__minibuffer_main
        next
endcode

; ### gtkui-minibuffer-exit
code gtkui_minibuffer_exit, 'gtkui-minibuffer-exit' ; void -> void
        extern  gtkui__minibuffer_exit
        xcall   gtkui__minibuffer_exit
        next
endcode

; ### gtkui-minibuffer-text-out
code gtkui_minibuffer_text_out, 'gtkui-minibuffer-text-out' ; x y string -> void
        _ string_from
        _drop
        mov     arg2_register, rbx
        poprbx
        _ check_fixnum
        mov     arg1_register, rbx
        poprbx
        _ check_fixnum
        mov     arg0_register, rbx
        poprbx

        extern  gtkui__minibuffer_text_out
        xcall   gtkui__minibuffer_text_out

        next
endcode

; ### gtkui_minibuffer_paint
subroutine gtkui_minibuffer_paint       ; void -> void
; 0-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [gtkui_raw_sp0_]

        _quote "repaint-minibuffer"     ; name
        _quote "mini"                   ; vocab-name
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### gtkui_minibuffer_keydown
subroutine gtkui_minibuffer_keydown     ; wparam -> void
; 1-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [gtkui_raw_sp0_]

        pushrbx
        mov     rbx, arg0_register
        _tag_fixnum

        _quote "minibuffer-dispatch"
        _quote "mini"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### gtkui-minibuffer-set-caret-pos
code gtkui_minibuffer_set_caret_pos, 'gtkui-minibuffer-set-caret-pos' ; x y -> void
        _check_fixnum
        mov     arg1_register, rbx
        poprbx
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
        extern  gtkui__minibuffer_set_caret_pos
        xcall   gtkui__minibuffer_set_caret_pos
        next
endcode
