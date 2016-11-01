; Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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

; ### accept-line
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

; ### (accept)
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
        _ forth_space
        next
endcode

%ifdef WINDOWS_UI

extern c_accept

; ### waccept
code waccept, 'waccept'                 ; c-addr +n1 -- +n2
        popd    rdx
        popd    rcx
        xcall   c_accept
        pushrbx
        mov     rbx, rax
        next
endcode

; CORE
; ### accept
deferred accept, 'accept', waccept      ; c-addr +n1 -- +n2

%else

; CORE
; ### accept
deferred accept, 'accept', paren_accept ; c-addr +n1 -- +n2

%endif

; ### #tib
variable ntib, '#tib', 0

; ### 'tib
variable tick_tib, "'tib", 0            ; initialized in main()

; ### tib
; CORE EXT in Forth 94 but removed in Forth 2012
; "The functions of TIB and #TIB have been superseded by SOURCE."
code tib, 'tib'
        _ tick_tib
        _fetch
        next
endcode

; ### >in
; CORE
variable toin, '>in', 0

; ### msg
value msg, 'msg', 0
