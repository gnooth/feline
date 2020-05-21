; Copyright (C) 2016-2020 Peter Graves <gnooth@gmail.com>

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

%macro  _quotation_array 0              ; quotation -> array
        _slot1
%endmacro

%macro  _this_quotation_array 0         ; -> array
        _this_slot1
%endmacro

%macro  _this_quotation_set_array 0     ; array ->
        _this_set_slot1
%endmacro

%macro  _quotation_raw_code_address 0   ; quotation -> raw-code-address
        _slot2
%endmacro

%macro  _quotation_set_raw_code_address 0       ; raw-code-address quotation -> void
        _set_slot2
%endmacro

%macro  _this_quotation_set_raw_code_address 0  ; raw-code-address -> void
        _this_set_slot2
%endmacro

%macro  _quotation_raw_code_size 0              ; quotation -> raw-code-size
        _slot3
%endmacro

%macro  _quotation_set_raw_code_size 0          ; raw-code-size quotation -> void
        _set_slot3
%endmacro

%macro  _this_quotation_set_raw_code_size 0     ; raw-code-size -> void
        _this_set_slot3
%endmacro

; ### quotation?
code quotation?, 'quotation?'                   ; x -> x/nil
;         _ object_raw_typecode
;         _eq? TYPECODE_QUOTATION
        cmp     bl, HANDLE_TAG
        jne     .1
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_QUOTATION
        jne     .no
        next
.1:
        cmp     bl, STATIC_QUOTATION_TAG
        jne     .no
        next
.no:
        mov     ebx, NIL
        next
endcode

; ### verify-unboxed-quotation
code verify_unboxed_quotation, 'verify-unboxed-quotation' ; quotation -> quotation
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
        _drop
        jne .2
        _return
.2:
        _ error_not_quotation
        next
endcode

; ### check_quotation
code check_quotation, 'check_quotation' ; x -> ^quotation
;         cmp     bl, HANDLE_TAG
;         jne     .1
;         mov     rax, rbx                ; save x in rax for error reporting
;         shr     rbx, HANDLE_TAG_BITS
;         mov     rbx, [rbx]              ; -> ^object
;         cmp     word [rbx], TYPECODE_QUOTATION
;         jne     .error
;         next
; .1:
;         ; not a handle
;         _ verify_unboxed_quotation
;         next
        cmp     bl, HANDLE_TAG
        jne     .1
        mov     rax, rbx                ; save x in rax for error reporting
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]              ; -> ^quotation
        cmp     word [rbx], TYPECODE_QUOTATION
        jne     .error
        next
.1:
        cmp     bl, STATIC_QUOTATION_TAG
        jne     error_not_quotation
        _untag_static_quotation
        next
.error:
        mov     rbx, rax                ; retrieve x
        _ error_not_quotation
        next
endcode

; ### verify-quotation
code verify_quotation, 'verify-quotation' ; quotation -> quotation
; returns argument unchanged
;         cmp     bl, HANDLE_TAG
;         jne     .1
;         mov     rax, rbx
;         shr     rax, HANDLE_TAG_BITS
;         mov     rax, [rax]
; %ifdef DEBUG
;         test    rax, rax
;         jz      error_empty_handle
; %endif
;         cmp     word [rax], TYPECODE_QUOTATION
;         jne     error_not_quotation
;         next
; .1:
;         _ verify_unboxed_quotation
        cmp     bl, HANDLE_TAG
        jne     .1
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
%ifdef DEBUG
        test    rax, rax
        jz      error_empty_handle
%endif
        cmp     word [rax], TYPECODE_QUOTATION
        jne     error_not_quotation
        next
.1:
        cmp     bl, STATIC_QUOTATION_TAG
        jne     error_not_quotation
        next
endcode

; ### array>quotation
code array_to_quotation, 'array>quotation'      ; array -> quotation
; 4 cells: object header, array, raw code address, raw code size

        _lit 4
        _ raw_allocate_cells

        push    this_register
        mov     this_register, rbx
        _drop

        _this_object_set_raw_typecode TYPECODE_QUOTATION

        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _this_quotation_set_array

        _zero
        _this_quotation_set_raw_code_address

        _zero
        _this_quotation_set_raw_code_size

        _dup
        mov     rbx, this_register      ; -> quotation

        ; return handle
        _ new_handle                    ; -> handle

        pop     this_register
        next
endcode

; ### 1quotation
code one_quotation, '1quotation'        ; x -> quotation
        _ one_array
        _ array_to_quotation
        next
endcode

; ### 2quotation
code two_quotation, '2quotation'        ; x y -> quotation
        _ two_array
        _ array_to_quotation
        next
endcode

; ### destroy_quotation_unchecked
code destroy_quotation_unchecked, 'destroy_quotation_unchecked', SYMBOL_INTERNAL
; quotation -> void

        _dup
        _quotation_raw_code_address
        _?dup_if .1
        _ raw_free_executable
        _then .1

        ; zero out object header
        mov     qword [rbx], 0

        _ raw_free
        next
endcode

; ### quotation-array
code quotation_array, 'quotation-array' ; quotation -> array
        _ check_quotation
        _quotation_array
        next
endcode

; ### quotation-length
code quotation_length, 'quotation-length'       ; quotation -> length
        _ check_quotation
        _quotation_array
        _ array_length
        next
endcode

; ### quotation-nth
code quotation_nth, 'quotation-nth'     ; index quotation -> element
        _ check_quotation
        _quotation_array
        _ array_nth
        next
endcode

; ### quotation-nth-unsafe
code quotation_nth_unsafe, 'quotation-nth-unsafe'
; index quotation -> element
        _handle_to_object_unsafe
        _quotation_array
        _ array_nth_unsafe
        next
endcode

; ### quotation_raw_code_address
code quotation_raw_code_address, 'quotation_raw_code_address', SYMBOL_INTERNAL
; quotation -> raw-code-address
        _ check_quotation
        _quotation_raw_code_address
        next
endcode

; ### quotation-code-address
code quotation_code_address, 'quotation-code-address'
; quotation -> code-address
        _ check_quotation
        _quotation_raw_code_address
        _tag_fixnum
        next
endcode

; ### quotation_set_raw_code_address
code quotation_set_raw_code_address, 'quotation_set_raw_code_address', SYMBOL_INTERNAL
; raw-code-address quotation -> void

        _ check_quotation

        _dup
        _object_allocated?
        _if .1
        _dup
        _quotation_raw_code_address
        _?dup_if .2
        _ raw_free_executable
        _then .2
        _then .1

        _quotation_set_raw_code_address

        next
endcode

; ### quotation-set-code-address
code quotation_set_code_address, 'quotation-set-code-address'
; tagged-address quotation -> void
        _swap
        _check_fixnum
        _swap
        _ quotation_set_raw_code_address
        next
endcode

; ### quotation-code-size
code quotation_code_size, 'quotation-code-size'
; quotation -> code-size
        _ check_quotation
        _quotation_raw_code_size
        _tag_fixnum
        next
endcode

; ### quotation-set-code-size
code quotation_set_code_size, 'quotation-set-code-size'
; tagged-size quotation -> void
        _ check_quotation
        _swap
        _check_fixnum
        _swap
        _quotation_set_raw_code_size
        next
endcode

; ### curry
code curry, 'curry'                     ; x quot1 -> quot2
        _tor
        _ literalize
        _rfrom

        _dup
        _ symbol?
        _tagged_if .1
        _ two_array
        _ array_to_quotation
        next
        _then .1

        _ quotation_array
        _ check_array                   ; -> x array

        mov     arg0_register, [rbx + ARRAY_RAW_LENGTH_OFFSET]
        add     arg0_register, 1
        _ allocate_array                ; returns untagged address in rax
        mov     rdx, [rbp]              ; x in rdx
        mov     [rax + ARRAY_DATA_OFFSET], rdx

        lea     arg0_register, [rbx + ARRAY_DATA_OFFSET] ; source
        lea     arg1_register, [rax + ARRAY_DATA_OFFSET + BYTES_PER_CELL] ; destination
        mov     arg2_register, [rbx + ARRAY_RAW_LENGTH_OFFSET] ; count

        push    rax
        _ copy_cells
        pop     rbx

        _nip
        _ new_handle
        _ array_to_quotation
        next
endcode

; ### compose
code compose, 'compose'                 ; quot1 quot2 -> composed
; FIXME handle all callables (symbols as well as quotations)
; FIXME optimize
        _twodup
        _ quotation_length
        _swap
        _ quotation_length
        _ unsafe_fixnum_plus
        _ new_vector                    ; -> quot1 quot2 vector
        _ swapd                         ; -> quot2 quot1 vector
        _tuck                           ; -> quot2 vector quot1 vector
        _ vector_push_all
        _tuck
        _ vector_push_all
        _ vector_to_array
        _ array_to_quotation
        next
endcode

; ### callable?
code callable?, 'callable?'             ; object -> ?
        _ object_raw_typecode
        cmp     ebx, TYPECODE_QUOTATION
        je      .1
        cmp     ebx, TYPECODE_SYMBOL
        je      .1
        mov     ebx, NIL
        next
.1:
        mov     ebx, TRUE
        next
endcode

; ### verify-callable
code verify_callable, 'verify-callable' ; callable -> callable
        _dup
        _ quotation?
        _tagged_if .1
        _return
        _then .1

        _dup
        _ symbol?
        _tagged_if .2
        _return
        _then .2

        _error "not a callable"

        next
endcode

; ### call
code call_quotation, 'call'             ; callable -> void
        _ callable_raw_code_address
        mov     rax, rbx
        _drop
%ifdef DEBUG
        call    rax
        next
%else
        jmp     rax
%endif
endcode

; ### callable_raw_code_address
code callable_raw_code_address, 'callable_raw_code_address', SYMBOL_INTERNAL
; callable -> raw-code-address
        _dup
        _ object_raw_typecode
        mov     rax, rbx
        _drop

        cmp     rax, TYPECODE_SYMBOL
        je      symbol_raw_code_address
        cmp     rax, TYPECODE_QUOTATION
        jne     error_not_callable

        _dup
        _ quotation_raw_code_address    ; -> quotation raw-code-address
        test    rbx, rbx
        jz      .1
        _nip
        next
.1:
        _drop
        _ compile_quotation             ; -> quotation
        _ quotation_raw_code_address
        next
endcode

; ### callable-code-address
code callable_code_address, 'callable-code-address' ; callable -> tagged-code-address
        _ callable_raw_code_address
        _tag_fixnum
        next
endcode

; ### quotation->string
code quotation_to_string, 'quotation->string' ; quotation -> string
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
