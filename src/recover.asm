; Copyright (C) 2016-2018 Peter Graves <gnooth@gmail.com>

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

%macro _spfetch 0
        lea     rbp, [rbp - BYTES_PER_CELL]
        mov     [rbp], rbx
        mov     rbx, rbp
%endmacro

%macro _spstore 0
        mov     rbp, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

section .data
feline_handler_data:
        dq      0

; ### feline_handler
code feline_handler, 'feline-handler'   ; -- handler
        pushrbx
        mov     rbx, [feline_handler_data]
        next
endcode

; ### feline_handler!
code set_feline_handler, 'feline-handler!' ; handler --
        mov     [feline_handler_data], rbx
        poprbx
        next
endcode

; ### catch
code catch, 'catch'
        _spfetch
        _tor
        _lpfetch
        _tor

        _ get_dynamic_scope
        _dup
        _ vector?
        _tagged_if .1
        _ vector_length
        _else .1
        _ drop
        _ f
        _then .1
        _tor

        _ feline_handler
        _tor
        _rpfetch
        _ set_feline_handler

        _ callable_raw_code_address
        mov     rax, rbx
        _drop
        call    rax

        _rfrom
        _ set_feline_handler

        lea     rsp, [rsp + BYTES_PER_CELL * 3]

        _zero

        next
endcode

; ### throw
code throw, 'throw'
        test    rbx, rbx
        jnz .1
        poprbx
        _return
.1:
        _ save_backtrace
        _dup
        _ feline_handler
        _rpstore

        _rfrom
        _ set_feline_handler

        _rfrom
        _dup
        _tagged_if .2
        _ get_dynamic_scope
        _ vector_set_length
        _else .2
        _drop
        _then .2

        _rfrom
        _lpstore
        _rfrom
        _swap
        _tor
        _spstore
        _drop
        _rfrom
        next
endcode

asm_global error_object_, f_value

; ### error-object
code error_object, 'error-object'
        pushrbx
        mov     rbx, [error_object_]
        next
endcode

; ### recover
code recover, 'recover'                 ; try-quot recover-quot --
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

        test    rbx, rbx
        jnz     .error

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
