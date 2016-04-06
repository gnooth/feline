; Copyright (C) 2015-2016 Peter Graves <gnooth@gmail.com>

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
        _fetch
%endmacro

; Register reserved for 'this' pointer.
%define this_register   r15

%macro  _this 0
        pushd   this_register
%endmacro

%macro  _slot0 0
        _fetch
%endmacro

; Slot 0 is the object header.

; The first word (16 bits) of the object header is the object type.

; Use the first word here and not just the first byte so that the header is
; less likely to be mistaken for the start of a legacy counted string. The
; first byte of a counted string might take on any value at all, but normally
; the second byte won't be zero unless the first byte is also zero. This gives
; us 255 distinct object types (1-255) before we need to set any bits in the
; second byte.

%macro  _object_type 0
        _wfetch                         ; 16 bits
%endmacro

%macro  _object_set_type 0              ; object type --
        _swap
        _wstore
%endmacro

%macro  _this_object_set_type 1
        mov     word [this_register], %1
%endmacro

; The third byte of the object header contains the object flags.

%define OBJECT_FLAGS_BYTE       byte [rbx + 2]

%macro  _object_flags 0
        movzx   rbx, OBJECT_FLAGS_BYTE
%endmacro

%macro  _object_marked? 0               ; object -- 0|1
        test    OBJECT_FLAGS_BYTE, OBJECT_MARKED_BIT
        setnz   bl
        movzx   ebx, bl
%endmacro

%macro  _mark_object 0                  ; object --
        or      OBJECT_FLAGS_BYTE, OBJECT_MARKED_BIT
        poprbx
%endmacro

%macro  _unmark_object 0                ; object --
        and     OBJECT_FLAGS_BYTE, ~OBJECT_MARKED_BIT
        poprbx
%endmacro

%macro  _object_set_flags 0             ; object flags --
        mov     rax, [rbp]              ; object in rax
        mov     [rax + 2], bl
        _2drop
%endmacro

%macro  _this_object_set_flags 1
        mov     byte [this_register + 2], %1
%endmacro

%macro  _object_allocated? 0            ; object -- 0|1
        test    OBJECT_FLAGS_BYTE, OBJECT_ALLOCATED_BIT
        setnz   bl
        movzx   ebx, bl
%endmacro

%macro  _slot1 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL]
%endmacro

%macro  _this_slot1 0                   ; -- x
        pushrbx
        mov     rbx, [this_register + BYTES_PER_CELL]
%endmacro

%macro  _set_slot1 0                    ; object x --
        mov     rax, [rbp]
        mov     [rax + BYTES_PER_CELL], rbx
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _this_set_slot1 0               ; x --
        mov     [this_register + BYTES_PER_CELL], rbx
        poprbx
%endmacro

%macro  _slot2 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 2]
%endmacro

%macro  _set_slot2 0                    ; object x --
        mov     rax, [rbp]
        mov     [rax + BYTES_PER_CELL * 2], rbx
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _this_slot2 0                   ; -- x
        pushrbx
        mov     rbx, [this_register + BYTES_PER_CELL * 2]
%endmacro

%macro  _this_set_slot2 0               ; x --
        mov     [this_register + BYTES_PER_CELL * 2], rbx
        poprbx
%endmacro

%macro  _slot3 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 3]
%endmacro

%macro  _set_slot3 0                    ; object x --
        mov     rax, [rbp]
        mov     [rax + BYTES_PER_CELL * 3], rbx
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _string? 0
        _object_type
        _lit OBJECT_TYPE_STRING
        _equal
%endmacro

%macro  _sbuf? 0
        _object_type
        _lit OBJECT_TYPE_SBUF
        _equal
%endmacro

%macro  _vector? 0
        _object_type
        _lit OBJECT_TYPE_VECTOR
        _equal
%endmacro

%macro  _vector_length 0                ; vector -- length
        _slot1
%endmacro

%macro  _vector_set_length 0            ; vector length --
        _set_slot1
%endmacro

%macro  _this_vector_length 0           ; -- length
        _this_slot1
%endmacro

%macro  _this_vector_set_length 0       ; length --
        _this_set_slot1
%endmacro

%macro  _vector_data 0
        _slot2
%endmacro

%macro  _vector_set_data 0              ; vector data-address --
        _set_slot2
%endmacro

%macro  _this_vector_data 0
        _this_slot2
%endmacro

%macro  _this_vector_set_data 0         ; vector data-address --
        _this_set_slot2
%endmacro

%macro  _vector_capacity 0              ; vector -- capacity
        _slot3
%endmacro

%macro  _vector_set_capacity 0          ; vector capacity --
        _set_slot3
%endmacro

%macro  _vector_nth_unsafe 0            ; index vector -- element
        _vector_data
        _swap
        _cells
        _plus
        _fetch
%endmacro

%macro  _this_vector_nth_unsafe 0       ; index -- element
        _cells
        _this_vector_data
        _plus
        _fetch
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
