; Copyright (C) 2015-2020 Peter Graves <gnooth@gmail.com>

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

%macro  _handle_to_object_unsafe 0
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]
%endmacro

%macro  _handle_to_object_unsafe_rax 0
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
%endmacro

; typecodes
TYPECODE_UNKNOWN                equ  0
TYPECODE_FIXNUM                 equ  1
TYPECODE_BOOLEAN                equ  2
TYPECODE_VECTOR                 equ  3
TYPECODE_STRING                 equ  4
TYPECODE_SBUF                   equ  5
TYPECODE_ARRAY                  equ  6
TYPECODE_HASHTABLE              equ  7
TYPECODE_CHAR                   equ  8
TYPECODE_SYMBOL                 equ  9
TYPECODE_VOCAB                  equ 10
TYPECODE_QUOTATION              equ 11
TYPECODE_WRAPPER                equ 12
TYPECODE_TUPLE                  equ 13
TYPECODE_SLICE                  equ 14
TYPECODE_RANGE                  equ 15
TYPECODE_LEXER                  equ 16
TYPECODE_FLOAT                  equ 17
TYPECODE_ITERATOR               equ 18
TYPECODE_METHOD                 equ 19
TYPECODE_GENERIC_FUNCTION       equ 20
TYPECODE_UINT64                 equ 21
TYPECODE_INT64                  equ 22
TYPECODE_TYPE                   equ 23
TYPECODE_KEYWORD                equ 24
TYPECODE_THREAD                 equ 25
TYPECODE_MUTEX                  equ 26
TYPECODE_STRING_ITERATOR        equ 27
TYPECODE_SLOT                   equ 28
TYPECODE_FILE_OUTPUT_STREAM     equ 29
TYPECODE_STRING_OUTPUT_STREAM   equ 30
TYPECODE_FIXNUM_HASHTABLE       equ 31
TYPECODE_EQUAL_HASHTABLE        equ 32

LAST_BUILTIN_TYPECODE           equ 32

asm_global last_raw_typecode_, LAST_BUILTIN_TYPECODE + 1

; ### next-typecode
code next_typecode, 'next-typecode'     ; -> fixnum
        pushrbx
        mov     rbx, [last_raw_typecode_]
        add     qword [last_raw_typecode_], 1
        _tag_fixnum
        next
endcode

; Object flag bits.
OBJECT_MARKED_BIT               equ 1
OBJECT_ALLOCATED_BIT            equ 4

; Register reserved for 'this' pointer.
%define this_register   r15

%macro  _this 0
        pushd   this_register
%endmacro

%macro  _slot0 0
        _fetch
%endmacro

; Slot 0 is the object header.

; The object's raw typecode is stored in the first two bytes of the object header.

%macro  _object_raw_typecode 0          ; object -- raw-typecode
        _wfetch                         ; 16 bits
%endmacro

%macro  _object_raw_typecode_eax 0
        movzx   eax, word [rbx]
%endmacro

%macro  _object_set_raw_typecode 1
        mov     word [rbx], %1
%endmacro

%macro  _this_object_set_raw_typecode 1
        mov     word [this_register], %1
%endmacro

; The third byte of the object header contains the object flags.

%define OBJECT_FLAGS_BYTE       byte [rbx + 2]

%macro  _object_flags 0
        movzx   rbx, OBJECT_FLAGS_BYTE
%endmacro

%macro  _object_set_flags 0             ; object flags --
        mov     rax, [rbp]              ; object in rax
        mov     [rax + 2], bl
        _2drop
%endmacro

%macro  _this_object_set_flags 1
        mov     byte [this_register + 2], %1
%endmacro

%macro  _object_allocated? 0            ; object -- 0/1
        test    OBJECT_FLAGS_BYTE, OBJECT_ALLOCATED_BIT
        setnz   bl
        movzx   ebx, bl
%endmacro

; mark byte (gc2)
%define OBJECT_MARK_BYTE_OFFSET         4

%define OBJECT_MARK_BYTE                byte [rbx + OBJECT_MARK_BYTE_OFFSET]

%macro  _object_mark_byte 0
        movzx   rbx, OBJECT_MARK_BYTE
%endmacro

%macro  _slot 1                         ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * %1]
%endmacro

%macro  _this_slot 1                    ; -- x
        pushrbx
        mov     rbx, [this_register + BYTES_PER_CELL * %1]
%endmacro

%macro  _set_slot 1                     ; x object --
        mov     rax, [rbp]
        mov     [rbx + BYTES_PER_CELL * %1], rax
        _2drop
%endmacro

%macro  _this_set_slot 1                ; x --
        mov     [this_register + BYTES_PER_CELL * %1], rbx
        poprbx
%endmacro

%macro  _this_nth_slot 0                ; n -- x
        _cells
        add     rbx, this_register
        mov     rbx, [rbx]
%endmacro

%macro  _slot1 0                        ; object -- x
        _slot 1
%endmacro

%macro  _set_slot1 0                    ; x object --
        _set_slot 1
%endmacro

%define this_slot1      qword [this_register + BYTES_PER_CELL * 1]

%macro  _this_slot1 0                   ; -- x
        pushrbx
        mov     rbx, this_slot1
%endmacro

%macro  _this_set_slot1 0               ; x --
        mov     this_slot1, rbx
        poprbx
%endmacro

%macro  _slot2 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 2]
%endmacro

%macro  _set_slot2 0                    ; x object --
        mov     rax, [rbp]
        mov     [rbx + BYTES_PER_CELL * 2], rax
        _2drop
%endmacro

%define this_slot2      qword [this_register + BYTES_PER_CELL * 2]

%macro  _this_slot2 0                   ; -- x
        pushrbx
        mov     rbx, this_slot2
%endmacro

%macro  _this_set_slot2 0               ; x --
        mov     this_slot2, rbx
        poprbx
%endmacro

%macro  _slot3 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 3]
%endmacro

%macro  _set_slot3 0                    ; x object --
        mov     rax, [rbp]              ; x in rax
        mov     [rbx + BYTES_PER_CELL * 3], rax
        _2drop
%endmacro

%define this_slot3      qword [this_register + BYTES_PER_CELL * 3]

%macro  _this_slot3 0                   ; -- x
        pushrbx
        mov     rbx, this_slot3
%endmacro

%macro  _this_set_slot3 0               ; x --
        mov     this_slot3, rbx
        poprbx
%endmacro

%macro  _slot4 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 4]
%endmacro

%macro  _set_slot4 0                    ; x object --
        mov     rax, [rbp]              ; x in rax
        mov     [rbx + BYTES_PER_CELL * 4], rax
        _2drop
%endmacro

%define this_slot4      qword [this_register + BYTES_PER_CELL * 4]

%macro  _this_slot4 0
        pushrbx
        mov     rbx, this_slot4
%endmacro

%macro  _this_set_slot4 0               ; x --
        mov     this_slot4, rbx
        poprbx
%endmacro

%macro  _slot5 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 5]
%endmacro

%macro  _set_slot5 0                    ; x object --
        mov     rax, [rbp]              ; x in rax
        mov     [rbx + BYTES_PER_CELL * 5], rax
        _2drop
%endmacro

%define this_slot5      qword [this_register + BYTES_PER_CELL * 5]

%macro  _this_slot5 0
        pushrbx
        mov     rbx, [this_register + BYTES_PER_CELL * 5]
%endmacro

%macro  _this_set_slot5 0               ; x --
        mov     [this_register + BYTES_PER_CELL * 5], rbx
        poprbx
%endmacro

%macro  _slot6 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 6]
%endmacro

%macro  _set_slot6 0                    ; x object --
        mov     rax, [rbp]              ; x in rax
        mov     [rbx + BYTES_PER_CELL * 6], rax
        _2drop
%endmacro

%define this_slot6      qword [this_register + BYTES_PER_CELL * 6]

%macro  _this_slot6 0
        pushrbx
        mov     rbx, [this_register + BYTES_PER_CELL * 6]
%endmacro

%macro  _this_set_slot6 0               ; x --
        mov     [this_register + BYTES_PER_CELL * 6], rbx
        poprbx
%endmacro

%macro  _slot7 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 7]
%endmacro

%define this_slot7      qword [this_register + BYTES_PER_CELL * 7]

%macro  _this_slot7 0
        pushrbx
        mov     rbx, [this_register + BYTES_PER_CELL * 7]
%endmacro

%macro  _this_set_slot7 0               ; x --
        mov     [this_register + BYTES_PER_CELL * 7], rbx
        poprbx
%endmacro
