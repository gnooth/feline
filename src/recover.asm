; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

; ### feline-catch
code feline_catch, 'feline-catch'
        _ spfetch
        _tor
        _ lpfetch
        _tor
        _ feline_handler
        _tor
        _ rpfetch
        _ set_feline_handler

        _ callable_code_address
        mov     rax, rbx
        _drop
        call    rax

        _rfrom
        _ set_feline_handler
        lea     rsp, [rsp + BYTES_PER_CELL * 2] ; rdrop rdrop
        _zero
        next
endcode

; ### feline-throw
code feline_throw, 'feline-throw'
        test    rbx, rbx
        jnz .1
        poprbx
        _return
.1:
        _ save_backtrace
        _dup
        _ feline_handler
        _ rpstore

        _rfrom
        _ set_feline_handler
        _rfrom
        _ lpstore
        _rfrom
        _swap
        _tor
        _ spstore
        _drop
        _rfrom
        next
endcode

section .data
error_object_data:
        dq      f_value

; ### recover
code recover, 'recover'                 ; try-quot recover-quot --
        _tor
        _tor                            ; --            r: -- recover-quot try-quot
        _ get_datastack                 ; -- datastack
        _rfrom                          ; -- datastack try-quot
        _swap
        _tor                            ; -- try-quot
        _ feline_catch
        test    rbx, rbx
        jnz     .error

        ; no error
        poprbx
        _rdrop
        _rdrop
        _return

.error:
        ; error object is in rbx
        mov     [error_object_data], rbx

        ; restore data stack
        _ clear
        _rfrom
        _quotation .1
        _ noop
        _end_quotation .1
        _ each

        pushrbx
        mov     rbx, [error_object_data]
        mov     qword [error_object_data], f_value

        _rfrom                          ; -- recover-quot

        _ callable_code_address
        mov     rax, rbx
        _drop
        call    rax

        next
endcode
