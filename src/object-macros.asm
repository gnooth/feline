; Copyright (C) 2015-2017 Peter Graves <gnooth@gmail.com>

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

; Object type numbers
OBJECT_TYPE_FIXNUM              equ  1
OBJECT_TYPE_F                   equ  2
OBJECT_TYPE_VECTOR              equ  3
OBJECT_TYPE_STRING              equ  4
OBJECT_TYPE_SBUF                equ  5
OBJECT_TYPE_ARRAY               equ  6
OBJECT_TYPE_HASHTABLE           equ  7
OBJECT_TYPE_BIGNUM              equ  8
OBJECT_TYPE_SYMBOL              equ  9
OBJECT_TYPE_VOCAB               equ 10
OBJECT_TYPE_QUOTATION           equ 11
OBJECT_TYPE_WRAPPER             equ 12
OBJECT_TYPE_TUPLE               equ 13
OBJECT_TYPE_CURRY               equ 14
OBJECT_TYPE_SLICE               equ 15
OBJECT_TYPE_RANGE               equ 16
OBJECT_TYPE_LEXER               equ 17
OBJECT_TYPE_FLOAT               equ 18
OBJECT_TYPE_ITERATOR            equ 19

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

; The object's raw type number is stored in the first two bytes of the object header.

%macro  _object_raw_type_number 0       ; -- raw-type-number
        _wfetch                         ; 16 bits
%endmacro

%macro  _object_set_raw_type_number 0   ; raw-type-number object --
        _wstore
%endmacro

%macro  _this_object_set_raw_type_number 1
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

%macro  _string? 0
        _object_raw_type_number
        _lit OBJECT_TYPE_STRING
        _equal
%endmacro

%macro  _sbuf? 0
        _object_raw_type_number
        _lit OBJECT_TYPE_SBUF
        _equal
%endmacro

%macro  _vector? 0
        _object_raw_type_number
        _lit OBJECT_TYPE_VECTOR
        _equal
%endmacro

%macro  _array? 0
        _object_raw_type_number
        _lit OBJECT_TYPE_ARRAY
        _equal
%endmacro

%macro  _hashtable? 0
        _object_raw_type_number
        _lit OBJECT_TYPE_HASHTABLE
        _equal
%endmacro

%macro  _bignum? 0
        _object_raw_type_number
        _lit OBJECT_TYPE_BIGNUM
        _equal
%endmacro

%macro  _symbol? 0
        _object_raw_type_number
        _lit OBJECT_TYPE_SYMBOL
        _equal
%endmacro

%macro  _vocab? 0
        _object_raw_type_number
        _lit OBJECT_TYPE_VOCAB
        _equal
%endmacro

%macro  _quotation? 0
        _object_raw_type_number
        _lit OBJECT_TYPE_QUOTATION
        _equal
%endmacro

%macro  _curry? 0
        _object_raw_type_number
        _lit OBJECT_TYPE_CURRY
        _equal
%endmacro

%macro  _slice? 0
        _object_raw_type_number
        _lit OBJECT_TYPE_SLICE
        _equal
%endmacro

%macro  _vector_raw_length 0            ; vector -- untagged-length
        _slot1
%endmacro

%macro  _vector_set_raw_length 0        ; untagged-length vector --
        _set_slot1
%endmacro

%define this_vector_raw_length  this_slot1

%macro  _this_vector_raw_length 0       ; -- untagged-length
        _this_slot1
%endmacro

%macro  _this_vector_set_raw_length 0   ; untagged-length --
        _this_set_slot1
%endmacro

%macro  _vector_data 0
        _slot2
%endmacro

%macro  _vector_set_data 0              ; data-address vector --
        _set_slot2
%endmacro

%define this_vector_data        this_slot2

%macro  _this_vector_data 0
        _this_slot2
%endmacro

%macro  _this_vector_set_data 0         ; data-address --
        _this_set_slot2
%endmacro

%macro  _vector_raw_capacity 0          ; vector -- raw-capacity
        _slot3
%endmacro

%macro  _vector_set_raw_capacity 0      ; raw-capacity vector --
        _set_slot3
%endmacro

%macro  _this_vector_raw_capacity 0     ; -- raw-capacity
        _this_slot3
%endmacro

%macro  _this_vector_set_raw_capacity 0 ; raw-capacity --
        _this_set_slot3
%endmacro

%macro  _vector_nth_unsafe 0            ; index vector -- element
        mov     rax, [rbp]              ; untagged index in rax
        lea     rbp, [rbp + BYTES_PER_CELL]
        shl     rax, 3                  ; convert cells to bytes
        _vector_data
        mov     rbx, [rbx + rax]
%endmacro

%macro  _this_vector_nth_unsafe 0       ; index -- element
        mov     rax, this_vector_data
        mov     rbx, [rax + BYTES_PER_CELL * rbx]
%endmacro

%macro  _vector_set_nth_unsafe 0        ; element index vector --
        _vector_data
        _swap
        _cells
        _plus
        _store
%endmacro

%macro  _this_vector_set_nth_unsafe 0   ; element index --
        _cells
        _this_vector_data
        _plus
        _store
%endmacro
