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

asm_global winui_raw_sp0_, 0

; ### winui-initialize
code winui_initialize, 'winui-initialize' ; void -> void
        _ current_thread_raw_sp0
        mov     [winui_raw_sp0_], rbx
        _drop

        extern  winui__initialize
        xcall   winui__initialize

        next
endcode

; ### winui-create-frame
code winui_create_frame, 'winui-create-frame' ; void -> void
        extern  winui__create_frame
        xcall   winui__create_frame
        next
endcode

; ### winui-main
code winui_main, 'winui-main'           ; void -> void
        extern  winui__main
        xcall   winui__main
        next
endcode

; ### winui_close
subroutine winui_close                  ; void -> void
; 0-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [winui_raw_sp0_]

        _quote "do-quit"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### winui-exit
code winui_exit, 'winui-exit'
        extern  winui__exit
        xcall   winui__exit
        next
endcode

; ### winui_safepoint
subroutine winui_safepoint              ; void -> void
; 0-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [winui_raw_sp0_]

        _ safepoint

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### winui_textview_paint
subroutine winui_textview_paint         ; void -> void
; 0-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [winui_raw_sp0_]

        _quote "repaint"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### winui_textview_char
subroutine winui_textview_char          ; wparam -> void
; 1-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [winui_raw_sp0_]

        pushrbx
        mov     rbx, arg0_register
        _tag_char

        _quote "winui-textview-char"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### winui_textview_keydown
subroutine winui_textview_keydown       ; wparam -> void
; 1-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [winui_raw_sp0_]

        pushrbx
        mov     rbx, arg0_register
        _tag_fixnum

        _quote "winui-textview-keydown"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### winui_textview_lbuttondown
subroutine winui_textview_lbuttondown   ; wparam lparam -> void
; 2-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [winui_raw_sp0_]

        pushrbx
        mov     rbx, arg0_register      ; wparam
        _tag_fixnum
        pushrbx
        mov     rbx, arg1_register      ; lparam
        _tag_fixnum

        _quote "winui-textview-lbuttondown"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### winui_textview_mousewheel
subroutine winui_textview_mousewheel    ; delta -> void
; 1-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [winui_raw_sp0_]

        pushrbx
        mov     rbx, arg0_register
        movsx   rbx, ebx
        _tag_fixnum

        test    rbx, rbx
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

; ### winui-textview-text-out
code winui_textview_text_out, 'winui-textview-text-out' ; x y string -> void
        _ string_from
        mov     arg3_register, rbx
        poprbx
        mov     arg2_register, rbx
        poprbx
        _ check_fixnum
        mov     arg1_register, rbx
        poprbx
        _ check_fixnum
        mov     arg0_register, rbx
        poprbx

        extern  winui__textview_text_out
        xcall   winui__textview_text_out

        next
endcode

; ### winui-textview-clear-eol
code winui_textview_clear_eol, 'winui-textview-clear-eol' ; x y -> void
        _check_fixnum
        mov     arg1_register, rbx
        poprbx
        _check_fixnum
        mov     arg0_register, rbx
        poprbx

        extern  winui__textview_clear_eol
        xcall   winui__textview_clear_eol

        next
endcode

; ### winui-textview-rows
code winui_textview_rows, 'winui-textview-rows' ; void -> fixnum
        extern  winui__textview_rows
        xcall   winui__textview_rows
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### winui-textview-columns
code winui_textview_columns, 'winui-textview-columns' ; void -> fixnum
        extern  winui__textview_columns
        xcall   winui__textview_columns
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### winui-textview-set-fg-color
code winui_textview_set_fg_color, 'winui-textview-set-fg-color' ; color -> void
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
        extern  winui__textview_set_fg_color
        xcall   winui__textview_set_fg_color
        next
endcode

; ### winui-textview-set-bg-color
code winui_textview_set_bg_color, 'winui-textview-set-bg-color' ; color -> void
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
        extern  winui__textview_set_bg_color
        xcall   winui__textview_set_bg_color
        next
endcode

; ### winui-char-width
code winui_char_width, 'winui-char-width' ; void -> fixnum
        extern  winui__char_width
        xcall   winui__char_width
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### winui-char-height
code winui_char_height, 'winui-char-height' ; void -> fixnum
        extern  winui__char_height
        xcall   winui__char_height
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### winui-modeline-set-text
code winui_modeline_set_text, 'winui-modeline-set-text' ; string -> void
        _ string_raw_data_address
        mov     arg0_register, rbx
        poprbx

        extern  winui__modeline_set_text
        xcall   winui__modeline_set_text

        next
endcode

; ### winui-minibuffer-text-out
code winui_minibuffer_text_out, 'winui-minibuffer-text-out' ; x y string -> void
        _ string_from
        mov     arg3_register, rbx
        poprbx
        mov     arg2_register, rbx
        poprbx
        _ check_fixnum
        mov     arg1_register, rbx
        poprbx
        _ check_fixnum
        mov     arg0_register, rbx
        poprbx

        extern  winui__minibuffer_text_out
        xcall   winui__minibuffer_text_out

        next
endcode

; ### winui-minibuffer-clear-eol
code winui_minibuffer_clear_eol, 'winui-minibuffer-clear-eol' ; x y -> void
        _check_fixnum
        mov     arg1_register, rbx
        poprbx
        _check_fixnum
        mov     arg0_register, rbx
        poprbx

        extern  winui__minibuffer_clear_eol
        xcall   winui__minibuffer_clear_eol

        next
endcode

; ### winui-minibuffer-invalidate
code winui_minibuffer_invalidate, 'winui-minibuffer-invalidate' ; void -> void
        extern  winui__minibuffer_invalidate
        xcall   winui__minibuffer_invalidate
        next
endcode

; ### winui_minibuffer_paint
subroutine winui_minibuffer_paint       ; void -> void
; 0-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [winui_raw_sp0_]

        _quote "repaint-minibuffer"     ; name
        _quote "mini"                   ; vocab-name
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### winui-minibuffer-main
code winui_minibuffer_main, 'winui-minibuffer-main' ; void -> void
        extern  winui__minibuffer_main
        xcall   winui__minibuffer_main
        next
endcode

; ### winui-minibuffer-exit
code winui_minibuffer_exit, 'winui-minibuffer-exit' ; void -> void
        extern  winui__minibuffer_exit
        xcall   winui__minibuffer_exit
        next
endcode

; ### winui_minibuffer_char
subroutine winui_minibuffer_char        ; char -> void
; 1-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [winui_raw_sp0_]

        pushrbx
        mov     rbx, arg0_register
        _tag_char

        _quote "winui-minibuffer-char"
        _quote "mini"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### winui_minibuffer_keydown
subroutine winui_minibuffer_keydown     ; wparam -> void
; 1-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [winui_raw_sp0_]

        pushrbx
        mov     rbx, arg0_register
        _tag_fixnum

        _quote "winui-minibuffer-keydown"
        _quote "mini"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub

; ### winui-show-caret
code winui_show_caret, 'winui-show-caret' ; void -> void
        xor     arg0_register, arg0_register
        extern  ShowCaret
        xcall   ShowCaret
        next
endcode

; ### winui-hide-caret
code winui_hide_caret, 'winui-hide-caret' ; void -> void
        xor     arg0_register, arg0_register
        extern  HideCaret
        xcall   HideCaret
        next
endcode

; ### winui-set-caret-pos
code winui_set_caret_pos, 'winui-set-caret-pos' ; x y -> void
        _check_fixnum
        mov     arg1_register, rbx
        poprbx
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
        extern  SetCaretPos
        xcall   SetCaretPos
        next
endcode
