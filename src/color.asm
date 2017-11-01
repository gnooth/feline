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

%define BLACK   tagged_fixnum(0)
%define RED     tagged_fixnum(1)
%define GREEN   tagged_fixnum(2)
%define YELLOW  tagged_fixnum(3)
%define BLUE    tagged_fixnum(4)
%define MAGENTA tagged_fixnum(5)
%define CYAN    tagged_fixnum(6)
%define WHITE   tagged_fixnum(7)

feline_constant black,   'black',   BLACK
feline_constant red,     'red',     RED
feline_constant green,   'green',   GREEN
feline_constant yellow,  'yellow',  YELLOW
feline_constant blue,    'blue',    BLUE
feline_constant magenta, 'magenta', MAGENTA
feline_constant cyan,    'cyan',    CYAN
feline_constant white,   'white',   WHITE

; ### verify-color
code verify_color, 'verify-color'

        _dup
        _ index?
        _tagged_if_not .1
        _error "not a color"
        _return
        _then .1

        _dup
        _tagged_fixnum(7)
        _ fixnum_fixnum_le
        _tagged_if_not .2
        _error "not a color"
        _then .2

        next
endcode

asm_global prompt_foreground_, GREEN

; ### prompt-foreground
code prompt_foreground, 'prompt-foreground'
        pushrbx
        mov     rbx, [prompt_foreground_]
        next
endcode

; ### set-prompt-foreground
code set_prompt_foreground, 'set-prompt-foreground'
        _ verify_color
        mov     [prompt_foreground_], rbx
        poprbx
        next
endcode

; ### prompt-style
code prompt_style, 'prompt-style'
        _ prompt_foreground
        _ foreground
        next
endcode

asm_global input_foreground_, YELLOW

; ### input-foreground
code input_foreground, 'input-foreground'
        pushrbx
        mov     rbx, [input_foreground_]
        next
endcode

; ### set-input-foreground
code set_input_foreground, 'set-input-foreground'
        _ verify_color
        mov     [input_foreground_], rbx
        poprbx
        next
endcode

; ### input-style
code input_style, 'input-style'
        _ input_foreground
        _ foreground
        next
endcode

asm_global output_foreground_, WHITE

; ### output-foreground
code output_foreground, 'output-foreground'
        pushrbx
        mov     rbx, [output_foreground_]
        next
endcode

; ### set-output-foreground
code set_output_foreground, 'set-output-foreground'
        _ verify_color
        mov     [output_foreground_], rbx
        poprbx
        next
endcode

; ### output-style
code output_style, 'output-style'
        _ output_foreground
        _ foreground
        next
endcode

asm_global comment_foreground_, CYAN

; ### comment-foreground
code comment_foreground, 'comment-foreground'
        pushrbx
        mov     rbx, [comment_foreground_]
        next
endcode

; ### set-comment-foreground
code set_comment_foreground, 'set-comment-foreground'
        _ verify_color
        mov     [comment_foreground_], rbx
        poprbx
        next
endcode

; ### comment-style
code comment_style, 'comment-style'
        _ comment_foreground
        _ foreground
        next
endcode

asm_global error_foreground_, RED

; ### error-foreground
code error_foreground, 'error-foreground'
        pushrbx
        mov     rbx, [error_foreground_]
        next
endcode

; ### set-error-foreground
code set_error_foreground, 'set-error-foreground'
        _ verify_color
        mov     [error_foreground_], rbx
        poprbx
        next
endcode

; ### error-style
code error_style, 'error-style'
        _ error_foreground
        _ foreground
        next
endcode
