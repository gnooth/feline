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

value line_input, 'line-input?', -1

code ok, 'ok'
        _ statefetch
        _zeq
        _if ok1
        _dotq " ok"
        _then ok1
        _ cr
        next
endcode

code accept_line, 'accept-line'         ; c-addr +n1 -- +n2
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
        jz      accept_line_exit
        cmp     bl, 10
        jz      accept_line_exit
        ; store char
        mov     rax, rdx
        add     rax, rcx
        mov     [rax], bl
        inc     rcx
        _ drop
        _again accept1
accept_line_exit:
        _ drop
        pushrbx
        mov     rbx, rcx
        next
endcode

code paren_accept, '(accept)'           ; c-addr +n1 -- +n2
        _ line_input
        _if accept1
        _ accept_line
        _return
        _then accept1
        xor     ecx, ecx                ; counter in RCX
        _ drop                          ; FIXME ignore +n1 for now
        mov     rdx, rbx                ; c-addr in RDX
        poprbx
        _begin accept2
        push    rcx
        push    rdx
        _ key                           ; char in bl
        _ dup
        _ blchar
        _ ge
        _if accept3
        _ dup
        _ emit
        _then accept3
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
        _again accept2
out:
        _ drop
        pushrbx
        mov     rbx, rcx
        _ space
        next
endcode

; CORE
deferred accept, 'accept', paren_accept ; c-addr +n1 -- +n2

variable ntib, '#tib', 0

variable tick_tib, "'tib", 0            ; initialized in main()

code tib, 'tib'
        _ tick_tib
        _fetch
        next
endcode

variable toin, '>in', 0

code query, 'query'                     ; --
; CORE EXT in Forth 94 but removed in Forth 200x
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
        _ lbrack
        _begin quit1
        _ rp0
        _fetch
        _ rpstore
        _ query
        _ tib
        _ ntib
        _fetch
        _ zero
        _ set_input
        _ interpret
        _ ok
        _again quit1
        next                            ; for decompiler
endcode

code abort, 'abort'                     ; i*x --        r: j*x --
; CORE
        mov     rbp, [sp0_data]
        jmp     quit
        next                            ; for decompiler
endcode
