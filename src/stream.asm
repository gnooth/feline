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

; 4 cells: object header, fd, input?, output?

%define stream_fd_slot                  qword [rbx + BYTES_PER_CELL]
%define this_stream_fd_slot             qword [this_register + BYTES_PER_CELL]

%define stream_input?_slot              qword [rbx + BYTES_PER_CELL * 2]
%define this_stream_input?_slot         qword [this_register + BYTES_PER_CELL * 2]

%define stream_output?_slot             qword [rbx + BYTES_PER_CELL * 3]
%define this_stream_output?_slot        qword [this_register + BYTES_PER_CELL * 3]

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

; ### stream-fd
code stream_fd, 'stream-fd'             ; -> fd
        _ check_stream
        mov     rbx, stream_fd_slot
        _ normalize
        next
endcode

; ### make-stream
code make_stream, 'make-stream'         ; fd input? output? -> stream
        _lit 4
        _ raw_allocate_cells
        _object_set_raw_typecode TYPECODE_STREAM
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> fd input? output?

        ; output?
        _ to_boolean
        mov     this_stream_output?_slot, rbx
        poprbx

        ; input?
        _ to_boolean
        mov     this_stream_input?_slot, rbx
        poprbx

        ; fd
        mov     this_stream_fd_slot, rbx

        mov     rbx, this_register
        _ new_handle
        pop     this_register
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

; ### stream-write-string
code stream_write_string, 'stream-write-string' ; string stream -> void

        _ check_stream
        _swap
        _ string_from                   ; -> stream address length

        ; test for zero length string
        test    rbx, rbx
        jz      .zero_length

.1:
        push    rbx                     ; save length
        popd    arg2_register
        popd    arg1_register
        mov     arg0_register, stream_fd_slot
        poprbx

        xcall   os_write_file           ; cell os_write_file(cell fd, void *buf, size_t count)

        ; os_write_file returns number of bytes written or -1 in rax
        pop     rdx                     ; length
        cmp     rdx, rax
        jne     .error
        next

.error:
        _error "error writing to file"
        next

.zero_length:
        _3drop
        next
endcode
