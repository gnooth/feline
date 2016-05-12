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

; ### line-input?
value line_input, 'line-input?', -1

; ### forth-ok
code forth_ok, 'forth-ok'
        _ statefetch
        _zeq_if .1
        _ green
        _ foreground
        _dotq " ok"
        _ depth
        _?dup_if .2
        _lit '-'
        _ emit
        _ decdot
        _then .2
        _then .1
        next
endcode

deferred ok, 'ok', forth_ok

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
value msg, 'msg', 0

; ### .msg
code dotmsg, '.msg'
        _ red
        _ foreground
        _from msg
        _?dup_if .1
        _ ?cr
        _ dot_string
        _clear msg
        _else .1
        _dotq "Error "
        _ exception
        _ dot
        _then .1
        next
endcode

; ### where
code where, 'where'                     ; --
        ; Print source line.
        _ ?cr
        _ source
        _ type

        ; Put ^ on next line after last character of offending token.
        _ cr
        _ parsed_name_start
        _ parsed_name_length
        _plus
        _ source
        _drop
        _minus
        _ spaces
        _lit '^'
        _ emit
        _ cr

        _ source_id
        _zgt
        _if .2
        _ ?cr
        _ source_filename
        _?dup_if .3
        _ dot_string
        _ space
        _then .3
        _dotq "line "
        _ source_line_number
        _ decdot
        _ cr
        _then .2

        next
endcode

value exception, 'exception', 0

; ### do-error
code do_error, 'do-error'               ; n --
        _to exception

        _ exception
        _lit -1
        _ equal
        _if .1
        _ reset                         ; ABORT (no message)
        _then .1

        _ exception
        _lit -2
        _equal
        _if .2
        _ dotmsg                        ; ABORT"
        _ print_backtrace
        _ reset
        _then .2

        ; otherwise...
        _ dotmsg

        _ where

        ; automatically print a backtrace if it is likely to be useful
        _ exception
        _lit -13                        ; undefined word
        _notequal
        _ exception
        _lit -4                         ; data stack underflow
        _notequal
        _ and
        _if .4
        _ print_backtrace
        _then .4
        _ reset
        next
endcode

; ### prompt
deferred prompt, 'prompt', forth_prompt

; ### quit
code quit, 'quit'                       ; --            r:  i*x --
; CORE
        _ lbrack
        _begin .1
        mov     rsp, [rp0_data]
        _ ?cr
        _ prompt
        _ query
        _ tib
        _ ntib
        _fetch
        _zero
        _ set_input
        _zeroto source_filename
        _lit interpret_xt
        _ catch
        _?dup_if .2
        ; THROW occurred
        _ do_error
        _else .2
        _ ok
        _then .2
        _again .1
        next                            ; for decompiler
endcode

; ### reset
code reset, 'reset'                     ; i*x --        r: j*x --
; This is the CORE version of ABORT (6.1.0670).
; "Empty the data stack and perform the function of QUIT, which includes
; emptying the return stack, without displaying a message."
        mov     rbp, [sp0_data]

        _ lp0
        _?dup_if .1
        _ lpstore
        _then .1

        ; REVIEW
        _clear exception

        ; REVIEW windows-ui
        _ standard_output

        jmp     quit
        next                            ; for decompiler
endcode

; ### abort
code abort, 'abort'                     ; i*x --        r: j*x --
; This is the EXCEPTION EXT version of ABORT (9.6.2.0670).
; "Perform the function of -1 THROW."
        _lit -1
        _ throw
        next                            ; for decompiler
endcode
