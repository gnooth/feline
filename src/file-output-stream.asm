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

; 3 cells: object header, fd, output column

; slot 1: fd
%define file_output_stream_fd_slot                      qword [rbx + BYTES_PER_CELL]
%define this_file_output_stream_fd_slot                 qword [this_register + BYTES_PER_CELL]

; slot 2: output column
%define file_output_stream_output_column_slot           qword [rbx + BYTES_PER_CELL * 2]
%define this_file_output_stream_output_column_slot      qword [this_register + BYTES_PER_CELL * 2]

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

asm_global stdout_

; ### stdout
code stdout, 'stdout'                   ; -> stream
        pushrbx
        mov     rbx, [stdout_]
        next
endcode

special standard_output, 'standard-output'

; ### initialize-streams
code initialize_streams, 'initialize-streams'
        pushrbx
%ifdef WIN64
        mov     rbx, [standard_output_handle]
%else
        mov     rbx, 1
%endif
        _ make_file_output_stream
        mov     [stdout_], rbx
        _drop

        _lit stdout_
        _ gc_add_root

        _ stdout
        _ standard_output
        _ set

        next
endcode

; ### space
code space, 'space'
        _tagged_char(32)
        _ standard_output
        _ get
        _ file_output_stream_write_char
        next
endcode

%define MAX_SPACES      256

        section .data
        align   DEFAULT_DATA_ALIGNMENT
spaces_:
        times MAX_SPACES db 32

; ### spaces
code spaces, 'spaces'                   ; n -> void

        _check_fixnum                   ; -> raw-count
        test    rbx, rbx
        jng     .exit

        cmp     rbx, MAX_SPACES
        jg      .1
        lea     rbp, [rbp - BYTES_PER_CELL]
        mov     qword [rbp], spaces_    ; -> raw-address raw-count

        _ standard_output
        _ get
        _ check_file_output_stream

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> raw-address raw-count

        ; returns number of bytes written in rax
        call    this_stream_write_bytes_unsafe

        ; update output column
        add     this_file_output_stream_output_column_slot, rax

        pop     this_register
        next

.1:
        _register_do_times .2
        _ space
        _loop .2
        next

.exit:
        _drop
        next
endcode

