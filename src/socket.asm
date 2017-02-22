; Copyright (C) 2017 Peter Graves <gnooth@gmail.com>

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

; ### make-socket
code make_socket, 'make-socket'         ; host port -- fd

        _check_fixnum
        mov     arg1_register, rbx
        poprbx

        _ string_raw_data_address
        mov     arg0_register, rbx
        poprbx

        xcall   c_make_socket

        pushrbx
        mov     rbx, rax

        next
endcode

; ### socket-read-char
code socket_read_char, 'socket-read-char'       ; fd -- char/f
        mov     arg0_register, rbx
        xcall   c_socket_read_char
        test    rax, rax
        js      .1
        mov     ebx, eax
        _tag_char
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### socket-write-char
code socket_write_char, 'socket-write-char'     ; tagged-char fd --
        _untag_char qword [rbp]
        popd    arg1_register
        popd    arg0_register
        xcall   c_socket_write_char
        next
endcode

; ### socket-write-string
code socket_write_string, 'socket-write-string' ; string fd --
        _tor
        _dup
        _ string_raw_data_address
        _swap
        _ string_raw_length
        _rfrom                  ; -- buf count fd
        popd    arg0_register
        popd    arg2_register
        popd    arg1_register
        xcall   c_socket_write
        test    rax, rax
        jns     .1
        _error "error writing to socket"
.1:
        next
endcode

; ### socket-close
code socket_close, 'socket-close'           ; fd --
        popd    arg0_register
        xcall   c_socket_close
        test    rax, rax
        js      .1
        _return
.1:
        _error "unable to close socket"
        next
endcode
