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

code bmark, '<mark'
        _ here
        next
endcode

code bresolve, '<resolve'
        _ comma
        next
endcode

code branch, 'branch'                   ; --
        pop     rax                     ; return addr
        mov     rax, [rax]
        push    rax
        next
endcode

code ?branch, '?branch'                 ; flag --
        popd    rax
        or      rax, rax
        jz      branch
        pop     rax
        add     rax, BYTES_PER_CELL
        push    rax
        next
endcode

code if, 'if', IMMEDIATE
        _lit ?branch
        _ commacall
        _ fmark
        next
endcode

code else, 'else', IMMEDIATE
        _lit branch
        _ commacall
        _ fmark
        _ swap
        _ fresolve
        next
endcode

code then, 'then', IMMEDIATE
        _ fresolve
        next
endcode

code dobegin, 'dobegin'                 ; only needed for decompiler
        next
endcode

code ?while, '?while'                   ; flag --
        popd    rax
        or      rax, rax
        jz      dorepeat
        pop     rax
        add     rax, BYTES_PER_CELL
        push    rax
        next
endcode

code dorepeat, 'dorepeat'               ; same as BRANCH
        pop     rax                     ; return addr
        mov     rax, [rax]
        push    rax
        next
endcode

code begin, 'begin', IMMEDIATE
        _lit dobegin
        _ commacall
        _ bmark
        next
endcode

code while, 'while', IMMEDIATE
        _lit ?while
        _ commacall
        _ fmark
        _ swap
        next
endcode

code repeat, 'repeat', IMMEDIATE
        _lit dorepeat
        _ commacall
        _ bresolve
        _ fresolve
        next
endcode

code doagain, 'doagain'                 ; same as BRANCH
        pop     rax                     ; return addr
        mov     rax, [rax]
        push    rax
        next
endcode

code again, 'again', IMMEDIATE
        _lit doagain
        _ commacall
        _ bresolve
        next
endcode

code ?until, '?until'                   ; flag --
        popd    rax
        or      rax, rax
        jz      dorepeat
        pop     rax
        add     rax, BYTES_PER_CELL
        push    rax
        next
endcode

code until, 'until', IMMEDIATE
        _lit ?until
        _ commacall
        _ bresolve
        next
endcode
