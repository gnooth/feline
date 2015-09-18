; Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

code ?pairs, '?pairs'
        _ xor
        _abortq "Control structure mismatch"
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

; ### if
code if, 'if', IMMEDIATE                ; c: -- orig
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _lit ?branch
        _lit ?branch_end - ?branch
        _ paren_copy_code
        _ here_c
        next
endcode

; ### else
code else, 'else', IMMEDIATE            ; c: orig1 -- orig2
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _lit branch
        _lit branch_end - branch
        _ paren_copy_code
        _ here_c                        ; -- orig1 here
        _ over                          ; -- orig1 here orig1
        _ minus                         ; -- orig1 here-orig1
        _ swap
        _ four
        _ minus
        _ lstore                        ; --
        _ here_c                        ; -- orig2
        next
endcode

; ### then
code then, 'then', IMMEDIATE            ; c: orig --
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ here_c                        ; -- addr here
        _ over                          ; -- addr here addr
        _ minus                         ; -- addr here-addr
        _ swap
        _ four
        _ minus
        _ lstore
        next
endcode

; ### align-code
code align_code, 'align-code'
        _begin .1
        _ here_c
        _lit 8
        _ mod
        _while .1
        _lit $90
        _ ccommac
        _repeat .1
        next
endcode

; ### begin
code begin, 'begin', IMMEDIATE          ; c: -- dest
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ align_code
        _ here_c
        next
endcode

; ### while
code while, 'while', IMMEDIATE          ; c: orig -- orig dest
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _lit ?branch
        _lit ?branch_end - ?branch
        _ paren_copy_code
        _ here_c                        ; location to be patched
        _ swap
        next
endcode

; ### repeat
code repeat, 'repeat', IMMEDIATE        ; orig dest --
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ again
        _ then
        next
endcode

; ### again
code again, 'again', IMMEDIATE          ; dest --
; CORE EXT
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ commajmp
        next
endcode

; ### until
code until, 'until', IMMEDIATE          ; c: dest --
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _lit ?branch
        _lit ?branch_end - ?branch
        _ paren_copy_code
        _ here_c
        _ minus
        _ here_c
        _ four
        _ minus
        _ lstore
        next
endcode
