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

; ### catch
code catch, 'catch'
        _ spfetch
        _tor
        _ lpfetch
        _tor

        _ get_namestack
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
        _ rpfetch
        _ set_feline_handler

        _ callable_code_address
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
        _ rpstore

        _rfrom
        _ set_feline_handler

        _rfrom
        _dup
        _tagged_if .2
        _ get_namestack
        _ vector_set_length
        _else .2
        _drop
        _then .2

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

_global error_object, f_value

; ### recover
code recover, 'recover'                 ; try-quot recover-quot --
        _tor
        _tor                            ; --            r: -- recover-quot try-quot
        _ get_datastack                 ; -- datastack
        _rfrom                          ; -- datastack try-quot
        _swap
        _tor                            ; -- try-quot
        _ catch
        test    rbx, rbx
        jnz     .error

        ; no error
        poprbx
        _rdrop
        _rdrop
        _return

.error:
        ; error object is in rbx
        mov     [error_object], rbx

        ; restore data stack
        _ clear
        _rfrom
        _quotation .1
        _ noop
        _end_quotation .1
        _ each

        pushrbx
        mov     rbx, [error_object]
        mov     qword [error_object], f_value

        _rfrom                          ; -- recover-quot

        _ callable_code_address
        mov     rax, rbx
        _drop
        call    rax

        next
endcode
