; Copyright (C) 2016-2020 Peter Graves <gnooth@gmail.com>

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

%macro  _rpfetch 0
        _dup
        mov     rbx, rsp
%endmacro

%macro _rpstore 0
        mov     rsp, rbx
        _drop
%endmacro

; ### catch
code catch, 'catch'                     ; quot -> ... f

        _rpfetch                        ; -> quot raw-rp

        _ current_thread
        _ thread_catchstack
        _ vector_push                   ; -> quot

        _ callable_raw_code_address
        mov     rax, rbx
        _drop
        call    rax

        _ current_thread
        _ thread_catchstack
        _ vector_pop_star

        ; no error
        _f

        next
endcode

; ### throw
code throw, 'throw'                     ; error ->

        cmp     rbx, NIL
        jne     .error
        _drop
        next

.error:
        _ current_thread
        _ thread_catchstack
        _ vector_?pop

        cmp     rbx, NIL
        je      .no_catch

        ; -> saved-raw-rp
        _rpstore
        next

.no_catch:                              ; -> error nil
        ; REVIEW
        _print "no catch"
        _drop                           ; -> error
        _ string?                       ; -> string/nil
        cmp     rbx, NIL
        je      .1
        _ error_output
        _ get
        _ stream_write_string
.1:                                     ; -> nil
        _ maybe_print_backtrace
        _ bye
        next
endcode

; REVIEW
asm_global error_object_, NIL

; ### last-error
code last_error, 'last-error'           ; void -> object/f
        _dup
        mov     rbx, [error_object_]
        next
endcode

; ### recover
code recover, 'recover'                 ; try-quot recover-quot ->
        _tor
        _tor                            ; --            r: -- recover-quot try-quot
        _ get_datastack                 ; -- data-stack
        _rfrom                          ; -- data-stack try-quot
        _swap
        _tor                            ; -- try-quot

        push    r12
        push    r13
        push    r14
        push    r15

        _ catch

        pop     r15
        pop     r14
        pop     r13
        pop     r12

        cmp     rbx, NIL
        jne     .error

        ; no error
        poprbx
        _rdrop
        _rdrop
        _return

.error:
        ; error object is in rbx
        mov     [error_object_], rbx

        ; restore data stack
        _ clear
        _rfrom
        _quotation .1
        _ identity
        _end_quotation .1
        _ each

        pushrbx
        mov     rbx, [error_object_]

        _rfrom                          ; -- recover-quot

        _ callable_raw_code_address
        mov     rax, rbx
        _drop
        call    rax

        next
endcode
