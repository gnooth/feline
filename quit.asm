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

; ### line-input?
value line_input, 'line-input?', -1

; ### ok
code ok, 'ok'
        _ statefetch
        _zeq_if .1
        _ green
        _ foreground
        _dotq " ok"
        _ depth
        _ ?dup
        _if .2
        _lit '-'
        _ emit
        _ decdot
        _then .2
        _then .1
        next
endcode

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
        _ space
        next
endcode

; CORE
; ### accept
deferred accept, 'accept', paren_accept ; c-addr +n1 -- +n2

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

; ### query
code query, 'query'                     ; --
; CORE EXT in Forth 94 but removed in Forth 2012
        _ tib
        _lit 80
        _ accept
        _ ntib
        _ store
        _ toin
        _ off
        next
endcode

; ### msg
variable msg, 'msg', 0

; ### .msg
code dotmsg, '.msg'
        _ msg
        _fetch
        _ ?dup
        _if .1
        _ red
        _ foreground
        _ ?cr
        _ counttype
        _ msg
        _ off
        _then .1
        next
endcode

; ### do-error
code do_error, 'do-error'               ; n --
        _ dup
        _ minusone
        _ equal
        _if .1
        _ reset                         ; ABORT (no message)
        _then .1
        _ dup
        _lit -2
        _ equal
        _if .2
        _ dotmsg                        ; ABORT"
        _ reset
        _then .2
        ; otherwise...
        _ dotmsg
        _ red
        _ foreground
        _ ?cr
        _dotq "Exception # "
        _ decdot
        _ where
        _ reset
        next
endcode

; ### quit
code quit, 'quit'                       ; --            r:  i*x --
; CORE
        _ lbrack
        _begin quit1
        _ rp0
        _fetch
        _ rpstore
        _ ?cr
        _ query
        _ tib
        _ ntib
        _fetch
        _ zero
        _ set_input
        _ zero
        _ source_filename
        _ store
        _lit interpret_xt
        _ catch
        _ ?dup
        _if quit2
        ; THROW occurred
        _ do_error
        _else quit2
        _ ok
        _then quit2
        _again quit1
        next                            ; for decompiler
endcode

; ### reset
code reset, 'reset'                     ; i*x --        r: j*x --
; This is the CORE version of ABORT (6.1.0670).
; "Empty the data stack and perform the function of QUIT, which includes
; emptying the return stack, without displaying a message."
        mov     rbp, [sp0_data]
        jmp     quit
        next                            ; for decompiler
endcode

; ### abort
code abort, 'abort'                     ; i*x --        r: j*x --
; This is the EXCEPTION EXT version of ABORT (9.6.2.0670).
; "Perform the function of -1 THROW."
        _ minusone
        _ throw
        next                            ; for decompiler
endcode
