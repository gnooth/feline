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

; 3 cells: object header, sbuf, output column

; slot 1: sbuf
%define string_output_stream_sbuf_slot                  qword [rbx + BYTES_PER_CELL]
%define this_string_output_stream_sbuf_slot             qword [this_register + BYTES_PER_CELL]

%macro  _string_output_stream_sbuf 0    ; -> sbuf
        _slot1
%endmacro

%macro  _this_string_output_stream_sbuf 0       ; -> sbuf
        _this_slot1
%endmacro

; slot 2: output column
%define string_output_stream_output_column_slot         qword [rbx + BYTES_PER_CELL * 2]
%define this_string_output_stream_output_column_slot    qword [this_register + BYTES_PER_CELL * 2]

; ### string-output-stream?
code string_output_stream?, 'string-output-stream?'     ; handle -> ?
        _ deref                         ; -> raw-object/0
        test    rbx, rbx
        jz      .1
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_STRING_OUTPUT_STREAM
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check_string_output_stream
code check_string_output_stream, 'check_string_output_stream', SYMBOL_INTERNAL      ; handle -> raw-stream
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_STRING_OUTPUT_STREAM
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_string_output_stream
        next
endcode

; ### verify-string-output-stream
code verify_string_output_stream, 'verify-string-output-stream' ; stream -> stream
; returns argument unchanged
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_STRING_OUTPUT_STREAM
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_string_output_stream
        next
endcode

; ### string-output-stream-sbuf
code string_output_stream_sbuf, 'string-output-stream-sbuf'     ; stream -> sbuf
        _ check_string_output_stream
        mov     rbx, string_output_stream_sbuf_slot
        next
endcode

; ### string-output-stream-output-column
code string_output_stream_output_column, 'string-output-stream-output-column'   ; stream -> n
        _ check_string_output_stream
        mov     rbx, string_output_stream_output_column_slot
        _tag_fixnum
        next
endcode

; ### make-string-output-stream
code make_string_output_stream, 'make-string-output-stream'     ; void -> stream
        _lit 3
        _ raw_allocate_cells
        _object_set_raw_typecode TYPECODE_STRING_OUTPUT_STREAM
        _lit 256
        _ new_sbuf_untagged
        mov     rax, rbx
        poprbx
        mov     string_output_stream_sbuf_slot, rax
        mov     string_output_stream_output_column_slot, 0
        _ new_handle
        next
endcode

; ### string-output-stream>string
code string_output_stream_to_string, 'string-output-stream>string'      ; stream -> string
        _ verify_string_output_stream
        _quote "<string-output-stream 0x"
        _ string_to_sbuf
        _swap
        _ object_address
        _ to_hex
        _over
        _ sbuf_append_string
        _lit tagged_char('>')
        _over
        _ sbuf_push
        _ sbuf_to_string
        next
endcode

; ### string-output-stream-write-char
code string_output_stream_write_char, 'string-output-stream-write-char' ; char stream -> void
        _ check_string_output_stream
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> char
        _dup                            ; -> char char
        _this_string_output_stream_sbuf ; -> char char sbuf
        _ sbuf_push                     ; -> char
        cmp     rbx, tagged_char('\n')
        poprbx                          ; -> void
        je      .newline
        add     this_string_output_stream_output_column_slot, 1
        pop     this_register
        next
.newline:
        mov     this_string_output_stream_output_column_slot, 0
        pop     this_register
        next
endcode

; ### string-output-stream-write-char-escaped
code string_output_stream_write_char_escaped, 'string-output-stream-write-char-escaped' ; char stream -> void
        ; does not update output column
        _ string_output_stream_sbuf
        _ sbuf_push
        next
endcode

; ### string-output-stream-write-string
code string_output_stream_write_string, 'string-output-stream-write-string'     ; string stream -> void
        _ check_string_output_stream
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> string
        _dup                            ; -> string string
        _this_string_output_stream_sbuf ; -> string string sbuf
        _ sbuf_append_string            ; -> string
        _ string_length
        _untag_fixnum
        add     this_string_output_stream_output_column_slot, rbx
        poprbx
        pop     this_register
        next
endcode

; ### string-output-stream-write-string-escaped
code string_output_stream_write_string_escaped, 'string-output-stream-write-string-escaped'     ; string stream -> void
        ; does not update output column
        _ string_output_stream_sbuf
        _ sbuf_append_string
        next
endcode

; ### string-output-stream-string
code string_output_stream_string, 'string-output-stream-string' ; stream -> string
        _ check_string_output_stream
        mov     rbx, string_output_stream_sbuf_slot
        _ sbuf_to_string
        next
endcode
