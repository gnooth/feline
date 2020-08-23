; Copyright (C) 2017-2020 Peter Graves <gnooth@gmail.com>

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

; REVIEW code address, code size
; 4 slots: object header, raw typecode, generic function, callable
%define METHOD_SIZE                             4 * BYTES_PER_CELL

%define METHOD_RAW_TYPECODE_OFFSET              8
%define METHOD_GENERIC_FUNCTION_OFFSET          16
%define METHOD_CALLABLE_OFFSET                  24

%macro  _method_raw_typecode 0          ; method -> raw-typecode
        _slot1
%endmacro

%macro  _method_set_raw_typecode 0      ; raw-typecode method ->
        _set_slot1
%endmacro

%macro  _this_method_raw_typecode 0     ; -> raw-typecode
        _this_slot1
%endmacro

%macro  _this_method_set_raw_typecode 0 ; raw-typecode ->
        _this_set_slot1
%endmacro

%macro  _method_generic_function 0      ; method -> generic-function
        _slot2
%endmacro

%macro  _method_set_generic_function 0  ; generic-function method ->
        _set_slot2
%endmacro

%macro  _this_method_generic_function 0 ; -> generic-function
        _this_slot2
%endmacro

%macro  _this_method_set_generic_function 0     ; generic-function ->
        _this_set_slot2
%endmacro

%macro  _method_callable 0              ; method -> callable
        _slot3
%endmacro

%macro  _method_set_callable 0          ; callable method ->
        _set_slot3
%endmacro

%macro  _this_method_callable 0         ; -> callable
        _this_slot3
%endmacro

%macro  _this_method_set_callable 0     ; callable ->
        _this_set_slot3
%endmacro

; ### method?
code method?, 'method?'                 ; x -> x/nil
; If x is a method, returns x unchanged. If x is not a method, returns nil.
        cmp     bl, HANDLE_TAG
        jne     .not_a_method
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_METHOD
        jne     .not_a_method
        next
.not_a_method:
        mov     ebx, NIL
        next
endcode

; ### check_method
code check_method, 'check_method'       ; method -> ^method
        cmp     bl, HANDLE_TAG
        jne     error_not_method
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]              ; rbx: ^method
        cmp     word [rbx], TYPECODE_METHOD
        jne     .error
        next
.error:
        mov     rbx, rax
        jmp     error_not_method
endcode

; ### verify-method
code verify_method, 'verify-method'     ; method -> method
; Returns argument unchanged.
        cmp     bl, HANDLE_TAG
        jne     error_not_method
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_METHOD
        jne     error_not_method
        next
endcode

; ### error-not-method
code error_not_method, 'error-not-method' ; x ->
        _quote "a method"
        _ format_type_error
        next
endcode

; ### make-method
code make_method, 'make-method'          ; typecode gf callable -> method
        _lit 4
        _ raw_allocate_cells

        push    this_register
        mov     this_register, rbx
        _drop                           ; -> typecode gf callable

        _this_object_set_raw_typecode TYPECODE_METHOD

        ; REVIEW
        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _dup
        _ callable?
        _tagged_if_not .1
        _error "not a callable"
        _then .1

        _this_method_set_callable       ; -> typecode gf

        _ verify_generic_function
        _this_method_set_generic_function

        _check_index
        _this_method_set_raw_typecode

        _dup
        mov     rbx, this_register

        _ new_handle                    ; -> method

        pop     this_register

        next
endcode

; ### method-typecode
code method_typecode, 'method-typecode' ; method -> typecode
        _ check_method
        _method_raw_typecode
        _tag_fixnum
        next
endcode

; ### method-generic-function
code method_generic_function, 'method-generic-function' ; method -> generic-function
        _ check_method
        _method_generic_function
        next
endcode

; ### method-callable
code method_callable, 'method-callable' ; method -> callable
        _ check_method
        _method_callable
        next
endcode

; ### method-set-callable
code method_set_callable, 'method-set-callable' ; callable method ->
        _ check_method
        _swap
        _ verify_callable
        _swap
        _method_set_callable
        next
endcode

; ### method->string
code method_to_string, 'method->string' ; method -> string
        _duptor
        _ method_typecode
        _ typecode_to_type
        _ type_name
        _rfetch
        _ method_generic_function
        _ generic_function_name
        _ symbol_name
        _rfrom
        _ object_address
        _ to_hex
        _quote `<method \"%s %s\" 0x%s>`
        _ format
        next
endcode
