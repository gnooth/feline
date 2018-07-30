; Copyright (C) 2017-2018 Peter Graves <gnooth@gmail.com>

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

; 5 cells: object header, class name (a symbol), raw typecode, slots, layout

; tuple: foo a b c ;
; layout is the 2array { foo 3 } where `foo` is the tuple class and 3 is the
; number of named slots

%macro  _tuple_class_name 0             ; class -- symbol
        _slot1
%endmacro

%macro  _tuple_class_set_name 0         ; symbol class --
        _set_slot1
%endmacro

%macro  _this_tuple_class_name 0        ; -- symbol
        _this_slot1
%endmacro

%macro  _this_tuple_class_set_name 0    ; symbol --
        _this_set_slot1
%endmacro

%macro  _tuple_class_raw_typecode 0            ; class -- raw-typecode
        _slot2
%endmacro

%macro  _tuple_class_set_raw_typecode 0        ; raw-typecode class --
        _set_slot2
%endmacro

%macro  _this_tuple_class_raw_typecode 0       ; -- raw-typecode
        _this_slot2
%endmacro

%macro  _this_tuple_class_set_raw_typecode 0   ; raw-typecode --
        _this_set_slot2
%endmacro

%macro  _tuple_class_slots 0            ; class -- slots
        _slot3
%endmacro

%macro  _tuple_class_set_slots 0        ; slots class --
        _set_slot3
%endmacro

%macro  _this_tuple_class_slots 0       ; -- slots
        _this_slot3
%endmacro

%macro  _this_tuple_class_set_slots 0   ; slots --
        _this_set_slot3
%endmacro

%macro  _tuple_class_layout 0            ; class -- layout
        _slot4
%endmacro

%macro  _tuple_class_set_layout 0        ; layout class --
        _set_slot4
%endmacro

%macro  _this_tuple_class_layout 0       ; -- layout
        _this_slot4
%endmacro

%macro  _this_tuple_class_set_layout 0   ; layout --
        _this_set_slot4
%endmacro

asm_global last_raw_typecode_, LAST_BUILTIN_TYPECODE + 1

; ### next_raw_typecode
code next_raw_typecode, 'next_raw_typecode'     ; -- raw-typecode
        pushrbx
        mov     rbx, [last_raw_typecode_]
        add     qword [last_raw_typecode_], 1
        next
endcode

; ### tuple-class?
code tuple_class?, 'tuple-class?'       ; x -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_TUPLE_CLASS
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check_tuple_class
code check_tuple_class, 'check_tuple_class', SYMBOL_INTERNAL
; handle -- tuple-class
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_TUPLE_CLASS
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_tuple_class
        next
endcode

; ### make-tuple-class
code make_tuple_class, 'make-tuple-class'
; name slots -- tuple-class

        _swap
        _ verify_symbol
        _swap

        _lit 5
        _ raw_allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- name slots

        _this_object_set_raw_typecode TYPECODE_TUPLE_CLASS

        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _ next_raw_typecode
        _this_tuple_class_set_raw_typecode      ; -- name slots

        _this_tuple_class_set_slots     ; -- name

        _this_tuple_class_set_name      ; --

        pushrbx
        mov     rbx, this_register      ; raw address in rbx

        _ new_handle                    ; handle in rbx

        ; layout is the 2-array { tuple-class number-of-named-slots }
        _dup
        _this_tuple_class_slots
        _ array_length
        _ two_array
        _this_tuple_class_set_layout

        pop     this_register

        next
endcode

; ### tuple-class-name
code tuple_class_name, 'tuple-class-name'               ; class -- symbol
        _ check_tuple_class
        _tuple_class_name
        next
endcode

; ### tuple-class-typecode
code tuple_class_typecode, 'tuple-class-typecode'       ; class -- typecode
        _ check_tuple_class
        _tuple_class_raw_typecode
        _tag_fixnum
        next
endcode

; ### tuple-class-slots
code tuple_class_slots, 'tuple-class-slots'             ; class -- slots
        _ check_tuple_class
        _tuple_class_slots
        next
endcode

; ### tuple-class-layout
code tuple_class_layout, 'tuple-class-layout'           ; class -- layout
        _ check_tuple_class
        _tuple_class_layout
        next
endcode

; ### tuple-class>string
code tuple_class_to_string, 'tuple-class>string'        ; class -- string
        _ tuple_class_name
        _ symbol_name
        next
endcode

; ### make-instance
code make_instance, 'make-instance'     ; class -- instance

        _ verify_type

        _dup
        _ type_layout
        _ array_raw_length

        ; slot 0 is object header, slot 1 is layout
        add     rbx, 2

        _cells
        _ raw_allocate                  ; -- class address

        _tor                            ; -- class

        _dup
        _ type_typecode
        _untag_fixnum                   ; -- class raw-typecode

        ; store raw typecode in object header
        _rfetch
        _store                          ; -- class

        ; store layout in slot 1
        _dup
        _ type_layout
        _rfetch
        add     rbx, BYTES_PER_CELL
        _store

        _ type_layout
        _ array_raw_length

        mov     rcx, rbx                ; number of slots in rcx
        poprbx

        jrcxz   .2

        mov     eax, f_value

        _rfetch
        add     rbx, BYTES_PER_CELL * 2

        mov     rdx, rbx
        poprbx

 .1:
        mov     [rdx], rax
        add     rdx, BYTES_PER_CELL
        dec     rcx
        jnz     .1

.2:
        _rfrom

        _ new_handle

        next
endcode
