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

; REVIEW type, read-only
; 3 cells: object header, raw index, name

%macro  _slot_raw_index 0               ; slot -> raw-index
        _slot1
%endmacro

%macro  _slot_set_raw_index 0           ; raw-index slot ->
        _set_slot1
%endmacro

%macro  _this_slot_set_raw_index 0      ; raw-index ->
        _this_set_slot1
%endmacro

%macro  _slot_name 0                    ; slot -> name
        _slot2
%endmacro

%macro  _slot_set_name 0                ; name slot ->
        _set_slot2
%endmacro

%macro  _this_slot_set_name 0           ; name ->
        _this_set_slot2
%endmacro

; ### slot?
code slot?, 'slot?'                     ; handle -> ?
        _ deref                         ; -> raw-object/0
        test    rbx, rbx
        jz      .1
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_SLOT
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check_slot
code check_slot, 'check_slot', SYMBOL_INTERNAL  ; handle -> slot
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_SLOT
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_slot
        next
endcode

; ### verify-slot
code verify_slot, 'verify-slot'         ; handle -> handle
; returns argument unchanged
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_SLOT
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_slot
        next
endcode

; ### slot-name
code slot_name, 'slot-name'             ; slot -> name
        _ check_slot
        _slot_name
        next
endcode

; ### slot-index
code slot_index, 'slot-index'           ; slot -> index
        _ check_slot
        _slot_raw_index
        _tag_fixnum
        next
endcode

; ### make-slot
code make_slot, 'make-slot'             ; name index -> slot
        _check_index
        _swap
        _ verify_string                 ; -> raw-index string

        _lit 3
        _ raw_allocate_cells
        _object_set_raw_typecode TYPECODE_SLOT
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> raw-index string

        ; name
        _this_slot_set_name

        ; index
        _this_slot_set_raw_index

        pushrbx
        mov     rbx, this_register
        _ new_handle
        pop     this_register
        next
endcode

; ### slot->string
code slot_to_string, 'slot->string'     ; slot -> string

        _ verify_slot

        _quote "<slot "
        _ string_to_sbuf                ; -> slot sbuf

        _over

        _ slot_index
        _ fixnum_to_decimal
        _over
        _ sbuf_append_string

        _lit tagged_char(' ')
        _over
        _ sbuf_push

        _swap
        _ slot_name
        _ quote_string
        _over
        _ sbuf_append_string

        _lit tagged_char('>')
        _over
        _ sbuf_push

        _ sbuf_to_string

        next
endcode
