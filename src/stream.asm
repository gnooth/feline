; Copyright (C) 2018 Peter Graves <gnooth@gmail.com>

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

%define DIRECTION_INPUT         1
%define DIRECTION_OUTPUT        2

; 4 cells: object header, fd, handle, direction

%define stream_fd_slot                  qword [rbx + BYTES_PER_CELL]
%define this_stream_fd_slot             qword [this_register + BYTES_PER_CELL]

%define stream_handle_slot              qword [rbx + BYTES_PER_CELL * 2]
%define this_stream_handle_slot         qword [this_register + BYTES_PER_CELL * 2]

%define stream_direction_slot           qword [rbx + BYTES_PER_CELL * 3]
%define this_stream_direction_slot      qword [this_register + BYTES_PER_CELL * 3]

; ### stream?
code stream?, 'stream?'                 ; handle -> ?
        _ deref                         ; -> raw-object/0
        test    rbx, rbx
        jz      .1
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_STREAM
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check_stream
code check_stream, 'check_stream', SYMBOL_INTERNAL      ; handle -> stream
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_STREAM
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_stream
        next
endcode

; ### verify-stream
code verify_stream, 'verify-stream'     ; handle -- handle
; returns argument unchanged
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_STREAM
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_stream
        next
endcode

; ### <stream>
code new_stream, '<stream>'             ; -> stream
        _lit 4
        _ raw_allocate_cells            ; -> raw-stream
        _object_set_raw_typecode TYPECODE_STREAM
        _ new_handle
        next
endcode

; ### stream>string
code stream_to_string, 'stream>string'  ; stream -> string

        _ verify_stream

        _quote "<stream 0x"
        _ string_to_sbuf

        _swap
        _ object_address
        _ to_hex
        _over
        _ sbuf_append_string

        _quote ">"
        _over
        _ sbuf_append_string

        _ sbuf_to_string

        next
endcode
