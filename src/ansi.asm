; Copyright (C) 2015-2017 Peter Graves <gnooth@gmail.com>

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

feline_constant black,   'black',   tagged_fixnum(0)
feline_constant red,     'red',     tagged_fixnum(1)
feline_constant green,   'green',   tagged_fixnum(2)
feline_constant yellow,  'yellow',  tagged_fixnum(3)
feline_constant blue,    'blue',    tagged_fixnum(4)
feline_constant magenta, 'magenta', tagged_fixnum(5)
feline_constant cyan,    'cyan',    tagged_fixnum(6)
feline_constant white,   'white',   tagged_fixnum(7)

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
code ansi_escape, 'esc['
        _tagged_char $1b
        _ write_char
        _tagged_char '['
        _ write_char
        next
endcode

; ### foreground
code foreground, 'foreground'           ; color --
        _ color?
        _tagged_if .1
        _ ansi_escape
        _tagged_char '3'
        _ write_char
        _tagged_char '0'
        _plus
        _ write_char
        _tagged_char 'm'
        _ write_char
        _else .1
        _drop
        _then .1
        next
endcode

; ### background
code background, 'background'           ; color --
        _ color?
        _tagged_if .1
        _ ansi_escape
        _tagged_char '4'
        _ write_char
        _tagged_char '0'
        _plus
        _ write_char
        _tagged_char 'm'
        _ write_char
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
        _ ansi_escape
        _tagged_char '2'
        _ write_char
        _tagged_char 'J'
        _ write_char
        _ ansi_escape
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

        _ ansi_escape
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
        _ ansi_escape
        _oneplus
        _tag_fixnum
        _ fixnum_to_string
        _ write_string
        _tagged_char 'G'
        _ write_char
        next
endcode

; ### clear-to-eol
code clear_to_eol, 'clear-to-eol'       ; --
        _ ansi_escape
        _write "0K"
        next
endcode
