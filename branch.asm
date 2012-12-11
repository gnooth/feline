; Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

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

code ?pairs, '?pairs'
        _ xor
        _abortq "Control structure mismatch"
        next
endcode

code fmark, '>mark'
        _ here
        _ zero
        _ comma
        next
endcode

code fresolve, '>resolve'
        _ here
        _ swap
        _ store
        next
endcode

; code bmark, '<mark'
;         _ here
;         next
; endcode

code bresolve, '<resolve'               ; addr --
        _ comma
        next
endcode

section .text
branch:
        jmp     0
branch_end:

?branch:
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jz      0
?branch_end:

code if, 'if', IMMEDIATE
        _lit ?branch
        _lit ?branch_end - ?branch
        _ paren_copy_code
        _ here
        next
endcode

code else, 'else', IMMEDIATE            ; addr -- addr
        _lit branch
        _lit branch_end - branch
        _ paren_copy_code
        _ here                          ; -- addr here
        _ over                          ; -- addr here addr
        _ minus                         ; -- addr here-addr
        _ swap
        _ four
        _ minus
        _ lstore                        ; --
        _ here                          ; -- here
        next
endcode

code then, 'then', IMMEDIATE            ; addr --
        _ here                          ; -- addr here
        _ over                          ; -- addr here addr
        _ minus                         ; -- addr here-addr
        _ swap
        _ four
        _ minus
        _ lstore
        next
endcode

code begin, 'begin', IMMEDIATE          ; c: -- dest
        _ here
        next
endcode

code while, 'while', IMMEDIATE          ; c: orig -- orig dest
        _lit ?branch
        _lit (?branch_end - ?branch)
        _ paren_copy_code
        _ here                          ; location to be patched
        _ swap
        next
endcode

code repeat, 'repeat', IMMEDIATE        ; orig dest --
        _ again
        _ then
        next
endcode

code again, 'again', IMMEDIATE          ; dest --
        _ commajmp
        next
endcode

code until, 'until', IMMEDIATE          ; c: dest --
        _lit ?branch
        _lit (?branch_end - ?branch)
        _ paren_copy_code
        _ here
        _ minus
        _ here
        _ four
        _ minus
        _ lstore
        next
endcode
