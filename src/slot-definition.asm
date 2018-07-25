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

%macro  _slot_definition_raw_index 0            ; slot-definition -> raw-index
        _slot1
%endmacro

%macro  _slot_definition_set_raw_index 0        ; raw-index slot-definition ->
        _set_slot1
%endmacro

%macro  _this_slot_definition_set_raw_index 0   ; raw-index ->
        _this_set_slot1
%endmacro

%macro  _slot_definition_name 0                 ; slot-definition -> name
        _slot2
%endmacro

%macro  _slot_definition_set_name 0             ; name slot-definition ->
        _set_slot2
%endmacro

%macro  _this_slot_definition_set_name 0        ; name ->
        _this_set_slot2
%endmacro

; ### slot-definition?
code slot_definition?, 'slot-definition?'       ; handle -> ?
        _ deref                         ; -> raw-object/0
        test    rbx, rbx
        jz      .1
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_SLOT_DEFINITION
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check_slot_definition
code check_slot_definition, 'check_slot_definition', SYMBOL_INTERNAL    ; handle -> slot-definition
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_SLOT_DEFINITION
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_slot_definition
        next
endcode

; ### verify-slot-definition
code verify_slot_definition, 'verify-slot-definition'   ; handle -> handle
; returns argument unchanged
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_SLOT_DEFINITION
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_slot_definition
        next
endcode

; ### slot-definition-name
code slot_definition_name, 'slot-definition-name'       ; slot-definition -> name
        _ check_slot_definition
        _slot_definition_name
        next
endcode

; ### slot-definition-index
code slot_definition_index, 'slot-definition-index'     ; slot-definition -> index
        _ check_slot_definition
        _slot_definition_raw_index
        _tag_fixnum
        next
endcode

; ### make-slot-definition
code make_slot_definition, 'make-slot-definition'       ; name index -> slot
        _check_index
        _swap
        _ verify_string                 ; -> raw-index string

        _lit 3
        _ raw_allocate_cells
        _object_set_raw_typecode TYPECODE_SLOT_DEFINITION
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> raw-index string

        ; name
        _this_slot_definition_set_name

        ; index
        _this_slot_definition_set_raw_index

        pushrbx
        mov     rbx, this_register
        _ new_handle
        pop     this_register
        next
endcode

; ### slot-definition>string
code slot_definition_to_string, 'slot-definition>string'        ; slot -> string

        _ verify_slot_definition

        _quote "<slot "
        _ string_to_sbuf                ; -> slot sbuf

        _over

        _ slot_definition_name
        _ quote_string
        _over
        _ sbuf_append_string

        _lit tagged_char(' ')
        _over
        _ sbuf_push

        _swap
        _ slot_definition_index
        _ fixnum_to_decimal
        _over
        _ sbuf_append_string

        _lit tagged_char('>')
        _over
        _ sbuf_push

        _ sbuf_to_string

        next
endcode
