; Copyright (C) 2018-2020 Peter Graves <gnooth@gmail.com>

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

; 3 cells: object header, fd, output column

; slot 1: fd
%define file_output_stream_fd_slot                      qword [rbx + BYTES_PER_CELL]
%define this_file_output_stream_fd_slot                 qword [this_register + BYTES_PER_CELL]

; slot 2: output column
%define file_output_stream_output_column_slot           qword [rbx + BYTES_PER_CELL * 2]
%define this_file_output_stream_output_column_slot      qword [this_register + BYTES_PER_CELL * 2]

; ### file-output-stream?
code file_output_stream?, 'file-output-stream?' ; x -> x/nil
; If x is a file output stream, returns x unchanged. Otherwise returns nil.
        cmp     bl, HANDLE_TAG
        jne     .no
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_FILE_OUTPUT_STREAM
        jne     .no
        next
.no:
%if NIL = 0
        xor     ebx, ebx
%else
        mov     ebx, NIL
%endif
        next
endcode

; ### check_file_output_stream
code check_file_output_stream, 'check_file_output_stream' ; file-output-stream -> ^file-output-stream
        cmp     bl, HANDLE_TAG
        jne     error_not_file_output_stream
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]
        cmp     word [rbx], TYPECODE_FILE_OUTPUT_STREAM
        jne     .error
        next
.error:
        mov     rbx, rax
        jmp     error_not_file_output_stream
endcode

; ### verify-file-output-stream
code verify_file_output_stream, 'verify-file-output-stream' ; file-output-stream -> file-output-stream
; Returns argument unchanged.
        cmp     bl, HANDLE_TAG
        jne     error_not_file_output_stream
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_FILE_OUTPUT_STREAM
        jne     error_not_file_output_stream
        next
endcode

; ### file-output-stream-fd
code file_output_stream_fd, 'file-output-stream-fd'     ; stream -> fd
        _ check_file_output_stream
        mov     rbx, file_output_stream_fd_slot
        _ normalize
        next
endcode

; ### file-output-stream-output-column
code file_output_stream_output_column, 'file-output-stream-output-column'       ; stream -> n
        _ check_file_output_stream
        mov     rbx, file_output_stream_output_column_slot
        _tag_fixnum
        next
endcode

; ### file-output-stream-set-output-column
code file_output_stream_set_output_column, 'file-output-stream-set-output-column'       ; n stream -> void
        _ check_file_output_stream
        push    this_register
        mov     this_register, rbx
        poprbx
        _check_fixnum
        mov     this_file_output_stream_output_column_slot, rbx
        poprbx
        pop     this_register
        next
endcode

; ### make-file-output-stream
code make_file_output_stream, 'make-file-output-stream' ; fd -> stream
        _lit 3
        _ raw_allocate_cells

        _object_set_raw_typecode TYPECODE_FILE_OUTPUT_STREAM

        ; -> fd raw-stream
        mov     rax, [rbp]              ; fd in rax
        _nip
        mov     file_output_stream_fd_slot, rax

        mov     file_output_stream_output_column_slot, 0

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
        push    this_register
        mov     this_register, rbx
        mov     arg1_register, file_output_stream_fd_slot
        poprbx
        _check_char
        mov     arg0_register, rbx      ; untagged char in rbx
        xcall   os_emit_file            ; void os_emit_file(int c, int fd)
        cmp     rbx, 10                 ; newline?
        poprbx
        je      .newline
        add     this_file_output_stream_output_column_slot, 1
        pop     this_register
        next
.newline:
        mov     this_file_output_stream_output_column_slot, 0
        pop     this_register
        next
endcode

; ### file-output-stream-write-char-escaped
code file_output_stream_write_char_escaped, 'file-output-stream-write-char-escaped'     ; char stream -> void
        _ check_file_output_stream
        mov     arg1_register, file_output_stream_fd_slot
        poprbx
        _check_char
        mov     arg0_register, rbx      ; untagged char in rbx
        poprbx
        xcall   os_emit_file            ; void os_emit_file(int c, int fd)
        next
endcode

; ### this_stream_write_bytes_unsafe
subroutine this_stream_write_bytes_unsafe       ; raw-address raw-length -> void
; call with raw address of stream object in this_register
; returns number of bytes written in rax
        push    rbx                     ; save raw length
        popd    arg2_register
        popd    arg1_register
        mov     arg0_register, this_file_output_stream_fd_slot

        xcall   os_write_file           ; cell os_write_file(cell fd, void *buf, size_t count)

        ; os_write_file returns number of bytes written or -1 in rax
        pop     rdx                     ; retrieve raw length
        cmp     rdx, rax
        jne     .error
        ret
.error:
        _error "error writing to file"  ; no return
endsub

; ### file-output-stream-write-string
code file_output_stream_write_string, 'file-output-stream-write-string' ; string stream -> void

        _ check_file_output_stream

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> string

        _ string_from                   ; -> raw-address raw-length

        test    rbx, rbx
        jz      .zero_length_string

        ; returns number of bytes written in rax
        call    this_stream_write_bytes_unsafe

        ; update output column
        add     this_file_output_stream_output_column_slot, rax

        pop     this_register
        next

.zero_length_string:
        _2drop
        pop     this_register
        next
endcode

; ### file-output-stream-write-string-escaped
code file_output_stream_write_string_escaped, 'file-output-stream-write-string-escaped' ; string stream -> void

        ; does not update output column!

        _ check_file_output_stream

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> string

        _ string_from                   ; -> address length

        test    rbx, rbx
        jz      .zero_length_string

        call    this_stream_write_bytes_unsafe

        pop     this_register
        next

.zero_length_string:
        _2drop
        pop     this_register
        next
endcode

; ### file-output-stream-nl
code file_output_stream_nl, 'file-output-stream-nl'     ; stream -> void
        push    rbx                     ; save stream
%ifdef WIN64
        _quote `\r\n`
        _swap
        _ file_output_stream_write_string
%else
        _lit tagged_char(10)
        _swap
        _ file_output_stream_write_char
%endif
        _lit tagged_zero
        pushrbx
        pop     rbx
        _ file_output_stream_set_output_column
        next
endcode

; ### file-output-stream-?nl
code file_output_stream_?nl, 'file-output-stream-?nl'   ; stream -> void
        _dup
        _ file_output_stream_output_column
        cmp     rbx, tagged_zero
        jne     .1
        _2drop
        next
.1:
        _drop
        _ file_output_stream_nl
        next
endcode

; ### file-output-stream-flush
code file_output_stream_flush, 'file-output-stream-flush' ; stream -> void
        _ check_file_output_stream
        mov     arg0_register, file_output_stream_fd_slot
        poprbx
        xcall   os_flush_file
        test    rax, rax
        js      .1
        _return
.1:
        _error "unable to flush file output stream"
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
