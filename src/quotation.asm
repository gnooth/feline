; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

; 3 cells: object header, array, raw code address

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

; ### quotation?
code quotation?, 'quotation?'                 ; x -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object/0
        _?dup_if .2
        _object_type                    ; -- object-type
        _eq? OBJECT_TYPE_QUOTATION
        _return
        _then .2
        ; Empty handle.
        _f
        _return
        _then .1

        ; Not a handle. Make sure address is in a permissible range.
        _dup
        _ in_static_data_area?
        _zeq_if .3
        ; Address is not in a permissible range.
        ; -- x
        mov     ebx, f_value
        _return
        _then .3

        ; -- object
        _object_type                    ; -- object-type
        _eq? OBJECT_TYPE_QUOTATION

        next
endcode

; ### error-not-quotation
code error_not_quotation, 'error-not-quotation' ; x --
        _error "not a quotation"
        next
endcode

; ### verify_unboxed_quotation
subroutine verify_unboxed_quotation     ; quotation -- quotation
        ; Make sure address is in a permissible range.
        _dup
        _ in_static_data_area?
        _zeq_if .1
        ; Address is not in a permissible range.
        _ error_not_quotation
        _return
        _then .1

        _dup
        _object_type                    ; -- object object-type
        cmp     rbx, OBJECT_TYPE_QUOTATION
        poprbx
        jne .2
        _return
.2:
        _ error_not_quotation
        next
endsub

; ### check_quotation
subroutine check_quotation              ; handle-or-quotation -- unboxed-quotation
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object/0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_QUOTATION
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _ error_not_quotation
        _then .1

        ; Not a handle.
        _ verify_unboxed_quotation

        ret
endsub

; ### array>quotation
code array_to_quotation, 'array>quotation' ; array -- quotation
; 3 cells: object header, array, code address

        _lit 3
        _ allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_object_set_type OBJECT_TYPE_QUOTATION

        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _this_quotation_set_array

        _zero
        _this_quotation_set_raw_code_address

        pushrbx
        mov     rbx, this_register      ; -- quotation

        ; Return handle.
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

; ### ~quotation
code destroy_quotation, '~quotation'    ; handle --
        _ check_quotation               ; -- quotation
        _ destroy_quotation_unchecked
        next
endcode

; ### ~quotation-unchecked
code destroy_quotation_unchecked, '~quotation-unchecked' ; quotation --
        _dup
        _quotation_raw_code_address
        _?dup_if .1
        _ free_executable
        _then .1

        _ in_gc?
        _zeq_if .2
        _dup
        _ release_handle_for_object
        _then .2

        ; Zero out the object header so it won't look like a valid object
        ; after it has been destroyed.
        xor     eax, eax
        mov     [rbx], rax

        _ ifree

        next
endcode

; ### quotation-array
code quotation_array, 'quotation-array' ; quotation -- array
        _ check_quotation
        _quotation_array
        next
endcode

; ### quotation_raw_code_address
subroutine quotation_raw_code_address   ; quotation -- raw-code-address
        _ check_quotation
        _quotation_raw_code_address
        ret
endsub

; ### quotation_set_raw_code_address
subroutine quotation_set_raw_code_address       ; raw-code-address quotation --
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

        ret
endsub

; ### callable?
code callable?, 'callable?'             ; object -- ?
        _dup
        _ quotation?
        _tagged_if .1
        mov     ebx, t_value
        _return
        _then .1
        _ curry?
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
        _drop
        _ compile_quotation             ; -- code-address code-size
        _drop
        _untag_fixnum
        _then .2
        mov     rax, rbx
        poprbx
        call    rax

        next
endcode

; ### callable-code-address
code callable_code_address, 'callable-code-address' ; callable -- code-address
; Returned value is untagged.
        _dup
        _ quotation?
        _tagged_if .1
        _dup
        _ quotation_raw_code_address    ; -- quotation raw-code-address
        _?dup_if .2
        _nip
        _else .2
        _ compile_quotation             ; -- code-address code-size
        _drop
        _untag_fixnum
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
