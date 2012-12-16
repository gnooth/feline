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

code prompt, "prompt"
        _ state
        _fetch
        _ zero?
        _if prompt1
        _ ?cr
        _lit '<'
        _ emit
        _ depth
        _ paren_dot
        _ type
        _lit '>'
        _ emit
        _ space
        _then prompt1
        next
endcode

code accept, 'accept'                   ; c-addr +n1 -- +n2
; CORE
        xor     ecx, ecx                ; counter in RCX
        _ drop                          ; FIXME ignore +n1 for now
        mov     rdx, rbx                ; c-addr in RDX
        poprbx
        _begin accept1
        push    rcx
        push    rdx
        _ key                           ; char in bl
        pop     rdx
        pop     rcx
        cmp     bl, 13
        jz      out
        cmp     bl, 10
        jz      out
        ; store char
        mov     rax, rdx
        add     rax, rcx
        mov     [rax], bl
        inc     rcx
        _ drop
        _again accept1
out:
        _ drop
        xor     eax, eax
        mov     [nout_data], rax
        pushrbx
        mov     rbx, rcx
        next
endcode

variable ntib, '#tib', 0

variable tick_tib, "'tib", 0            ; initialized in main()

code tib, 'tib'
        _ tick_tib
        _fetch
        next
endcode

variable toin, '>in', 0

code query, "query"                     ; --
; CORE EXT
        _ tib
        _lit 80
        _ accept
        _ ntib
        _ store
        _ toin
        _ off
        next
endcode

code quit, 'quit'                       ; --            r:  i*x --
; CORE
        _ state
        _ off
        _begin quit1
        _ r0
        _fetch
        _ rpstore
        _ prompt
        _ query
        _ tib
        _ ntib
        _fetch
        _ zero
        _ set_input
        _ interpret
        _again quit1
endcode

code abort, 'abort'                     ; i*x --        r: j*x --
; CORE
        mov     rbp, [s0_data]
        jmp     quit
endcode
