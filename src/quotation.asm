; Copyright (C) 2016-2017 Peter Graves <gnooth@gmail.com>

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

; 4 cells: object header, array, raw code address, raw code size

%macro  _quotation_array 0              ; quotation -- array
        _slot1
%endmacro

%macro  _this_quotation_array 0         ; -- array
        _this_slot1
%endmacro

%macro  _this_quotation_set_array 0     ; array --
        _this_set_slot1
%endmacro

%macro  _quotation_raw_code_address 0   ; quotation -- raw-code-address
        _slot2
%endmacro

%macro  _quotation_set_raw_code_address 0       ; raw-code-address quotation --
        _set_slot2
%endmacro

%macro  _this_quotation_set_raw_code_address 0  ; raw-code-address --
        _this_set_slot2
%endmacro

%macro  _quotation_raw_code_size 0              ; quotation -- raw-code-size
        _slot3
%endmacro

%macro  _quotation_set_raw_code_size 0          ; raw-code-size quotation --
        _set_slot3
%endmacro

%macro  _this_quotation_set_raw_code_size 0     ; raw-code-size --
        _this_set_slot3
%endmacro

; ### quotation?
code quotation?, 'quotation?'                 ; x -- ?
        _ object_raw_typecode
        _eq? TYPECODE_QUOTATION
        next
endcode

; ### error-not-quotation
code error_not_quotation, 'error-not-quotation' ; x --
        _error "not a quotation"
        next
endcode

; ### verify-unboxed-quotation
code verify_unboxed_quotation, 'verify-unboxed-quotation'       ; quotation -- quotation
        ; make sure address is in the permissible range
        _dup
        _ in_static_data_area?
        _tagged_if_not .1
        ; address is not in the permissible range
        _ error_not_quotation
        _return
        _then .1

        _dup
        _object_raw_typecode
        cmp     rbx, TYPECODE_QUOTATION
        poprbx
        jne .2
        _return
.2:
        _ error_not_quotation
        next
endcode

; ### check-quotation
code check_quotation, 'check-quotation' ; handle-or-quotation -- unboxed-quotation
        _dup
        _ deref                         ; -- x object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_QUOTATION
        jne     .2
        _nip
        _return
.1:
        _drop
        _ verify_unboxed_quotation
        _return
.2:
        _ error_not_quotation
        next
endcode

; ### array>quotation
code array_to_quotation, 'array>quotation'      ; array -- quotation
; 4 cells: object header, array, raw code address, raw code size

        _lit 4
        _ raw_allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_object_set_raw_typecode TYPECODE_QUOTATION

        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _this_quotation_set_array

        _zero
        _this_quotation_set_raw_code_address

        _zero
        _this_quotation_set_raw_code_size

        pushrbx
        mov     rbx, this_register      ; -- quotation

        ; return handle
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### 1quotation
code one_quotation, '1quotation'        ; object -- quotation
        _ one_array
        _ array_to_quotation
        next
endcode

; ### destroy_quotation_unchecked
code destroy_quotation_unchecked, 'destroy_quotation_unchecked', SYMBOL_INTERNAL
; quotation --

        _dup
        _quotation_raw_code_address
        _?dup_if .1
        _ free_executable
        _then .1

        ; zero out object header
        xor     eax, eax
        mov     [rbx], rax

        _ raw_free
        next
endcode

; ### quotation-array
code quotation_array, 'quotation-array' ; quotation -- array
        _ check_quotation
        _quotation_array
        next
endcode

; ### quotation-length
code quotation_length, 'quotation-length'       ; quotation -- length
        _ check_quotation
        _quotation_array
        _ array_length
        next
endcode

; ### quotation-nth
code quotation_nth, 'quotation-nth'     ; index quotation -- element
        _ check_quotation
        _quotation_array
        _ array_nth
        next
endcode

; ### quotation-nth-unsafe
code quotation_nth_unsafe, 'quotation-nth-unsafe'
; index quotation -- element
        _handle_to_object_unsafe
        _quotation_array
        _ array_nth_unsafe
        next
endcode

; ### quotation_raw_code_address
code quotation_raw_code_address, 'quotation_raw_code_address', SYMBOL_INTERNAL
; quotation -- raw-code-address
        _ check_quotation
        _quotation_raw_code_address
        next
endcode

; ### quotation-code-address
code quotation_code_address, 'quotation-code-address'
; quotation -- code-address
        _ check_quotation
        _quotation_raw_code_address
        _tag_fixnum
        next
endcode

; ### quotation_set_raw_code_address
code quotation_set_raw_code_address, 'quotation_set_raw_code_address', SYMBOL_INTERNAL
; raw-code-address quotation --

        _ check_quotation

        _dup
        _object_allocated?
        _if .1
        _dup
        _quotation_raw_code_address
        _?dup_if .2
        _ free_executable
        _then .2
        _then .1

        _quotation_set_raw_code_address

        next
endcode

; ### quotation_raw_code_size
code quotation_raw_code_size, 'quotation_raw_code_size', SYMBOL_INTERNAL
; quotation -- raw-code-size
        _ check_quotation
        _quotation_raw_code_size
        next
endcode

; ### quotation-code-size
code quotation_code_size, 'quotation-code-size'
; quotation -- code-size
        _ check_quotation
        _quotation_raw_code_size
        _tag_fixnum
        next
endcode

; ### quotation_set_raw_code_size
code quotation_set_raw_code_size, 'quotation_set_raw_code_size', SYMBOL_INTERNAL
; raw-code-size quotation --
        _ check_quotation
        _quotation_set_raw_code_size
        next
endcode

; ### callable?
code callable?, 'callable?'             ; object -- ?
        _ object_raw_typecode

        cmp     ebx, TYPECODE_QUOTATION
        je      .1

        cmp     ebx, TYPECODE_SYMBOL
        je      .1

        cmp     ebx, TYPECODE_CURRY
        je      .1

        mov     ebx, f_value
        next

.1:
        mov     ebx, t_value
        next
endcode

; ### call
code call_quotation, 'call'             ; callable --
        _dup
        _ curry?
        _tagged_if .1
        _ curry_code_address
        mov     rax, rbx
        poprbx
        call    rax
        _return
        _then .1

        _dup
        _ quotation_raw_code_address
        _dup_if .2
        _nip                            ; -- raw-code-address
        _else .2
        _drop                           ; -- quotation
        _ compile_quotation             ; -- quotation
        _ quotation_raw_code_address
        _then .2
        mov     rax, rbx
        poprbx
        call    rax

        next
endcode

; ### callable_raw_code_address
code callable_raw_code_address, 'callable_raw_code_address', SYMBOL_INTERNAL
; callable -- raw-code-address
        _dup
        _ quotation?
        _tagged_if .1
        _dup
        _ quotation_raw_code_address    ; -- quotation raw-code-address
        _?dup_if .2
        _nip
        _else .2
        _ compile_quotation             ; -- quotation
        _ quotation_raw_code_address
        _then .2
        _return
        _then .1

        _dup
        _ curry?
        _tagged_if .3
        _ curry_code_address
        _return
        _then .3

        _dup
        _ symbol?
        _tagged_if .4
        _ symbol_code_address
        _check_fixnum
        _return
        _then .4

        _error "not a callable"

        next
endcode

; ### quotation>string
code quotation_to_string, 'quotation>string'    ; quotation -- string
        _ quotation_array

        _quote "[ "
        _ string_to_sbuf
        _swap
        _quotation .1
        _ object_to_string
        _over
        _ sbuf_append_string
        _lit tagged_char(32)
        _over
        _ sbuf_push
        _end_quotation .1
        _ array_each
        _tagged_char(']')
        _over
        _ sbuf_push
        _ sbuf_to_string

        next
endcode

; ### .quotation
code dot_quotation, '.quotation'        ; quotation --
        _ quotation_array

        _ check_array

        push    this_register
        mov     this_register, rbx

        _write "[ "
        _array_raw_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe
        _ dot_object
        _ space
        _loop .1
        _write "]"

        pop     this_register
        next
endcode
