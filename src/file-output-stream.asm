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

; 2 cells: object header, fd

; slot 1
%define file_output_stream_fd_slot      qword [rbx + BYTES_PER_CELL]

; ### file-output-stream?
code file_output_stream?, 'file-output-stream?' ; handle -> ?
        _ deref                         ; -> raw-object/0
        test    rbx, rbx
        jz      .1
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_FILE_OUTPUT_STREAM
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check_file_output_stream
code check_file_output_stream, 'check_file_output_stream', SYMBOL_INTERNAL      ; handle -> raw-stream
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_FILE_OUTPUT_STREAM
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_file_output_stream
        next
endcode

; ### verify-file-output-stream
code verify_file_output_stream, 'verify-file-output-stream'     ; handle -> handle
; returns argument unchanged
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_FILE_OUTPUT_STREAM
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_file_output_stream
        next
endcode

; ### file-output-stream-fd
code file_output_stream_fd, 'file-output-stream-fd'     ; -> fd
        _ check_file_output_stream
        mov     rbx, file_output_stream_fd_slot
        _ normalize
        next
endcode

; ### make-file-output-stream
code make_file_output_stream, 'make-file-output-stream' ; fd -> stream
        _lit 2
        _ raw_allocate_cells

        _object_set_raw_typecode TYPECODE_FILE_OUTPUT_STREAM

        ; -> fd raw-stream
        mov     rax, [rbp]              ; fd in rax
        _nip
        mov     file_output_stream_fd_slot, rax

        ; -> raw-stream
        _ new_handle

        next
endcode

; ### file-output-stream>string
code file_output_stream_to_string, 'file-output-stream>string'  ; stream -> string

        _ verify_file_output_stream

        _quote "<file-output-stream 0x"
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

; ### file-output-stream-write-char
code file_output_stream_write_char, 'file-output-stream-write-char'     ; char stream -> void
        _ check_file_output_stream
        mov     arg1_register, file_output_stream_fd_slot
        poprbx
        _check_char
        mov     arg0_register, rbx
        poprbx
        xcall   os_emit_file            ; void os_emit_file(int c, int fd)
        next
endcode

; ### file-output-stream-write-string
code file_output_stream_write_string, 'file-output-stream-write-string' ; string stream -> void

        _ check_file_output_stream
        _swap
        _ string_from                   ; -> raw-stream address length

        ; test for zero length string
        test    rbx, rbx
        jz      .zero_length

.1:
        push    rbx                     ; save length
        popd    arg2_register
        popd    arg1_register
        mov     arg0_register, file_output_stream_fd_slot
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

;  ### file-output-stream-close
code file_output_stream_close, 'file-output-stream-close'       ; stream -> void
        _ check_file_output_stream
        mov     arg0_register, file_output_stream_fd_slot
        xcall   os_close_file
        test    rax, rax
        js      .1
        mov     file_output_stream_fd_slot, -1
        poprbx
        next
.1:
        poprbx
        _error "unable to close stream"
        next
endcode
