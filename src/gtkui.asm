; Copyright (C) 2019 Peter Graves <gnooth@gmail.com>

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

; ### gtkui-textview-set-fg-color
code gtkui_textview_set_fg_color, 'gtkui-textview-set-fg-color' ; color -> void
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
        extern  gtkui__textview_set_fg_color
        xcall   gtkui__textview_set_fg_color
        next
endcode

; ### gtkui-textview-set-bg-color
code gtkui_textview_set_bg_color, 'gtkui-textview-set-bg-color' ; color -> void
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
        extern  gtkui__textview_set_bg_color
        xcall   gtkui__textview_set_bg_color
        next
endcode

; ### gtkui-char-width
code gtkui_char_width, 'gtkui-char-width' ; void -> fixnum
        extern  gtkui__char_width
        xcall   gtkui__char_width
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### gtkui-char-height
code gtkui_char_height, 'gtkui-char-height' ; void -> fixnum
        extern  gtkui__char_height
        xcall   gtkui__char_height
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### gtkui-modeline-set-text
code gtkui_modeline_set_text, 'gtkui-modeline-set-text' ; string -> void
        _ string_raw_data_address
        mov     arg0_register, rbx
        poprbx

        extern  gtkui__modeline_set_text
        xcall   gtkui__modeline_set_text

        next
endcode

; ### gtkui-textview-text-out
code gtkui_textview_text_out, 'gtkui-textview-text-out' ; x y string -> void
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

        extern  gtkui__textview_text_out
        xcall   gtkui__textview_text_out

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

        _quote "gtkui-minibuffer-keydown"
        _quote "mini"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### gtkui-set-caret-pos
code gtkui_set_caret_pos, 'gtkui-set-caret-pos' ; x y -> void
        _check_fixnum
        mov     arg1_register, rbx
        poprbx
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
;         extern  SetCaretPos
;         xcall   SetCaretPos
        extern  gtkui__set_caret_pos
        xcall   gtkui__set_caret_pos
        next
endcode
