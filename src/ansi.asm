; Copyright (C) 2015-2018 Peter Graves <gnooth@gmail.com>

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

asm_global color?_, f_value

; ### color?
code color?, 'color?'                   ; -- ?
        pushrbx
        mov     rbx, [color?_]
        next
endcode

; ### +color
code color_on, '+color'                 ; --
        mov     qword [color?_], t_value
        next
endcode

; ### -color
code color_off, '-color'                ; --
        mov     qword [color?_], f_value
        next
endcode

; ### esc[
code ansi_csi, 'esc['                   ; --
; control sequence introducer
        _quote `\e[`
        _ write_string_escaped
        next
endcode

; ### check_color
code check_color, 'check_color'         ; color -> untagged-fixnum
        test    bl, FIXNUM_TAG
        jz      .error
        cmp     rbx, tagged_fixnum(7)
        ja     .error
        _untag_fixnum
        _return

.error:
        _quote "a valid color specifier"
        _ format_type_error
        _ error

        next
endcode

; ### foreground
code foreground, 'foreground'           ; color -> void
        _ color?
        _tagged_if .1
        _ check_color                   ; -> untagged-fixnum
        _quote `\e[3`
        _ write_string_escaped
        add     rbx, '0'
        _tag_char
        _ write_char_escaped
        _tagged_char 'm'
        _ write_char_escaped
        _else .1
        _drop
        _then .1
        next
endcode

; ### background
code background, 'background'           ; color -> void
        _ color?
        _tagged_if .1
        _ check_color                   ; -> untagged-fixnum
        _quote `\e[4`
        _ write_string_escaped
        add     rbx, '0'
        _tag_char
        _ write_char_escaped
        _tagged_char 'm'
        _ write_char_escaped
        _else .1
        _drop
        _then .1
        next
endcode

; ### page
code page, 'page'
; Forth 2012
; "On a terminal, PAGE clears the screen and resets the cursor
; position to the upper left corner."
        _ ansi_csi
        _tagged_char '2'
        _ write_char
        _tagged_char 'J'
        _ write_char
        _ ansi_csi
        _tagged_char $3b
        _ write_char
        _tagged_char 'H'
        _ write_char
        next
endcode

; ### at-xy
code at_xy, 'at-xy'                     ; col row --
        _check_fixnum
        _ swap
        _check_fixnum
        _swap

        _ ansi_csi
        _oneplus                        ; ANSI values are 1-based
        _tag_fixnum
        _ fixnum_to_string
        _ write_string

        _tagged_char ';'
        _ write_char

        _oneplus                        ; ANSI values are 1-based
        _tag_fixnum
        _ fixnum_to_string
        _ write_string

        _tagged_char 'H'
        _ write_char
        next
endcode

; ### at-x
code at_x, 'at-x'                       ; col --
        _check_fixnum
        _ ansi_csi
        _oneplus
        _tag_fixnum
        _ fixnum_to_string
        _ write_string
        _tagged_char 'G'
        _ write_char
        next
endcode

; ### hide-cursor
code hide_cursor, 'hide-cursor'
        _quote `\e[?25l`
        _ write_string_escaped
        next
endcode

; ### show-cursor
code show_cursor, 'show-cursor'
        _quote `\e[?25h`
        _ write_string_escaped
        next
endcode

; ### clear-to-eol
code clear_to_eol, 'clear-to-eol'       ; --
        _ ansi_csi
        _write "0K"
        next
endcode

%ifdef WIN64

; emacs/src/w32console.c get-screen-color
; emacs/lisp/term/w32console.el

; ### get-console-character-attributes
code get_console_character_attributes, 'get-console-character-attributes'
; -- attributes
        xcall   os_get_console_character_attributes
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### get-console-background
code get_console_background, 'get-console-background'   ; -- bg
        _ get_console_character_attributes
        _lit tagged_fixnum(4)
        _ rshift
        _lit tagged_fixnum(15)
        _ bitand
        next
endcode

; ### get-console-foreground
code get_console_foreground, 'get-console-foreground'   ; -- fg
        _ get_console_character_attributes
        _lit tagged_fixnum(15)
        _ bitand
        next
endcode
%endif

asm_global using_alternate_screen_buffer_, f_value

; ### use-default-screen-buffer
code use_default_screen_buffer, 'use-default-screen-buffer'
        cmp     qword [using_alternate_screen_buffer_], f_value
        jne .1
        _return
.1:
        _ ansi_csi
        _quote "?1049l"
        _ write_string
        mov     qword [using_alternate_screen_buffer_], f_value
        next
endcode

; ### use-alternate-screen-buffer
code use_alternate_screen_buffer, 'use-alternate-screen-buffer'
        cmp     qword [using_alternate_screen_buffer_], f_value
        je .1
        _return
.1:
        _ ansi_csi
        _quote "?1049h"
        _ write_string
        mov     qword [using_alternate_screen_buffer_], t_value
        next
endcode

; ### using-alternate-screen-buffer?
code using_alternate_screen_buffer, 'using-alternate-screen-buffer?'    ; -- ?
        pushrbx
        mov     rbx, [using_alternate_screen_buffer_]
        next
endcode
