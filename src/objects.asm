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

; ### object-type
inline object_type, 'object-type'       ; object -- type
        _object_type
endinline

%macro  _object_set_type 0              ; object type --
        _swap
        _wstore
%endmacro

; ### object-set-type
inline object_set_type, 'object-set-type' ; object type --
        _object_set_type
endinline

%macro  _this_object_set_type 1
        mov     word [this_register], %1
%endmacro

; The third byte of the object header contains the object flags.

%define OBJECT_FLAGS_BYTE       byte [rbx + 2]

%macro  _object_flags 0
        movzx   rbx, OBJECT_FLAGS_BYTE
%endmacro

; ### object-flags
inline object_flags, 'object-flags'     ; object -- flags
        _object_flags
endinline

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

; ### object-set-flags
inline object_set_flags, 'object-set-flags' ; object flags --
        _object_set_flags
endinline

%macro  _object_allocated? 0            ; object -- 0|1
        test    OBJECT_FLAGS_BYTE, OBJECT_ALLOCATED_BIT
        setnz   bl
        movzx   ebx, bl
%endmacro

; ### allocate-object
code allocate_object, 'allocate-object' ; size -- object
        _ iallocate
        next
endcode

; ### object?
code object?, 'object?'                 ; x -- flag
        _dup
        _ handle?
        _if .0
        _handle_to_object_unsafe
        _zne
        _return
        _then .0

        ; Not allocated. Must be a string or not an object.
        _ string?
        next
endcode

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

%macro _slot3 0                         ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 3]
%endmacro

%macro _set_slot3 0                     ; object x --
        mov     rax, [rbp]
        mov     [rax + BYTES_PER_CELL * 3], rbx
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro _string? 0
        _object_type
        _lit OBJECT_TYPE_STRING
        _equal
%endmacro

%macro _sbuf? 0
        _object_type
        _lit OBJECT_TYPE_SBUF
        _equal
%endmacro

%macro _vector? 0
        _object_type
        _lit OBJECT_TYPE_VECTOR
        _equal
%endmacro

; ### ~object
code destroy_object, '~object'          ; object --
; The argument is known to be the address of a valid heap object, not a
; handle or null. Called only by maybe-collect-handle during gc.
        _dup

        ; Macro is OK here since we have a valid object address.
        _string?

        _if .1
        _ destroy_string_unchecked
        _return
        _then .1

        _dup
        _sbuf?
        _if .2
        _ destroy_sbuf_unchecked
        _return
        _then .2

        _dup
        _vector?
        _if .3
        _ destroy_vector_unchecked
        _return
        _then .3

        ; REVIEW
        _true
        _abortq "unknown object"
        next
endcode

; ### .object
code dot_object, '.object'              ; handle-or-object --
        _dup
        _ string?
        _if .1
        _lit '"'
        _ emit
        _ dot_string
        _lit '"'
        _ emit
        _ space
        _return
        _then .1

        _dup
        _ sbuf?
        _if .2
        _dotq 'SBUF" '
        _ sbuf_from
        _ type
        _dotq '" '
        _return
        _then .2

        _dup
        _ vector?
        _if .3
        _ dot_vector
        _ space
        _return
        _then .3

        ; give up
        _ hdot

        next
endcode
