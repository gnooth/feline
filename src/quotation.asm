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

; 6 cells: object header, array, raw code address, raw code size, parent, local names
%define QUOTATION_SIZE                          6 * BYTES_PER_CELL

%define QUOTATION_ARRAY_OFFSET                  8
%define QUOTATION_RAW_CODE_ADDRESS_OFFSET       16
%define QUOTATION_RAW_CODE_SIZE_OFFSET          24
%define QUOTATION_PARENT_OFFSET                 32
%define QUOTATION_LOCAL_NAMES_OFFSET            40

%macro  _quotation_array 0              ; quotation -> array
        _slot1
%endmacro

%macro  _this_quotation_array 0         ; -> array
        _this_slot1
%endmacro

%macro  _quotation_raw_code_address 0   ; quotation -> raw-code-address
        _slot2
%endmacro

%macro  _quotation_set_raw_code_address 0 ; raw-code-address quotation -> void
        _set_slot2
%endmacro

%macro  _this_quotation_set_raw_code_address 0 ; raw-code-address -> void
        _this_set_slot2
%endmacro

%macro  _quotation_set_raw_code_size 0  ; raw-code-size quotation -> void
        _set_slot3
%endmacro

%macro  _this_quotation_set_raw_code_size 0 ; raw-code-size -> void
        _this_set_slot3
%endmacro

%macro  _quotation_parent 0             ; ^quotation -> parent
        _slot4
%endmacro

%macro  _quotation_local_names 0        ; ^quotation -> locals
        _slot5
%endmacro

; ### quotation?
code quotation?, 'quotation?'                   ; x -> x/nil
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

; ### check_quotation
code check_quotation, 'check_quotation' ; x -> ^quotation
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

; ### make-quotation
code make_quotation, 'make-quotation'   ; void -> quotation

        mov     arg0_register, QUOTATION_SIZE
        _ feline_malloc                 ; returns address in rax

        mov     qword [rax], TYPECODE_QUOTATION
        mov     byte [rax + OBJECT_FLAGS_BYTE_OFFSET], OBJECT_ALLOCATED_BIT
        mov     qword [rax + QUOTATION_ARRAY_OFFSET], NIL
        mov     qword [rax + QUOTATION_RAW_CODE_ADDRESS_OFFSET], 0
        mov     qword [rax + QUOTATION_RAW_CODE_SIZE_OFFSET], 0
        mov     qword [rax + QUOTATION_PARENT_OFFSET], NIL
        mov     qword [rax + QUOTATION_LOCAL_NAMES_OFFSET], NIL
        _dup
        mov     rbx, rax

        ; return handle
        _ new_handle                    ; -> handle

        next
endcode

; ### array->quotation
code array_to_quotation, 'array->quotation' ; array -> quotation

        mov     arg0_register, QUOTATION_SIZE
        _ feline_malloc                 ; returns address in rax

        mov     qword [rax], TYPECODE_QUOTATION
        mov     byte [rax + OBJECT_FLAGS_BYTE_OFFSET], OBJECT_ALLOCATED_BIT
        mov     qword [rax + QUOTATION_ARRAY_OFFSET], rbx
        mov     qword [rax + QUOTATION_RAW_CODE_ADDRESS_OFFSET], 0
        mov     qword [rax + QUOTATION_RAW_CODE_SIZE_OFFSET], 0
        mov     qword [rax + QUOTATION_PARENT_OFFSET], NIL
        mov     qword [rax + QUOTATION_LOCAL_NAMES_OFFSET], NIL
        mov     rbx, rax

        ; return handle
        _ new_handle                    ; -> handle

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
        mov     rax, [rbx + QUOTATION_RAW_CODE_ADDRESS_OFFSET]
        test    rax, rax
        jz      .1
        _dup
        mov     rbx, rax
        _ raw_free_executable
.1:
        ; zero out object header
        mov     qword [rbx], 0
        _ raw_free
        next
endcode

; ### quotation-array
code quotation_array, 'quotation-array' ; quotation -> array/nil
        _ check_quotation
        _quotation_array
        next
endcode

; ### quotation-set-array
code quotation_set_array, 'quotation-set-array' ; array quotation -> void
        _ check_quotation
        mov     rax, [rbp]
        mov     [rbx + QUOTATION_ARRAY_OFFSET], rax
        _2drop
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
code quotation_set_code_address, 'quotation-set-code-address' ; fixnum quotation -> void
        mov     rax, [rbp]
        test    al, FIXNUM_TAG
        jz      .not_a_fixnum
        sar     qword [rbp], FIXNUM_TAG_BITS
        _ quotation_set_raw_code_address
        next
.not_a_fixnum:
        mov     rbx, [rbp]
        _nip
        _ error_not_fixnum
        next
endcode

; ### quotation-code-size
code quotation_code_size, 'quotation-code-size'
; quotation -> code-size
        _ check_quotation
        mov     rbx, [rbx + QUOTATION_RAW_CODE_SIZE_OFFSET]
        _tag_fixnum
        next
endcode

; ### quotation-set-code-size
code quotation_set_code_size, 'quotation-set-code-size' ; fixnum quotation -> void
        _ check_quotation
        mov     rax, [rbp]
        test    al, FIXNUM_TAG
        jz      .not_a_fixnum
        sar     rax, FIXNUM_TAG_BITS
        mov     [rbx + QUOTATION_RAW_CODE_SIZE_OFFSET], rax
        _2drop
        next
.not_a_fixnum:
        mov     rbx, [rbp]
        _nip
        _ error_not_fixnum
        next
endcode

; ### quotation-parent
code quotation_parent, 'quotation-parent' ; quotation -> parent
        _ check_quotation
        mov     rbx, [rbx + QUOTATION_PARENT_OFFSET]
        next
endcode

; ### quotation-set-parent
code quotation_set_parent, 'quotation-set-parent' ; x quotation -> void
        _ check_quotation
        mov     rax, [rbp]
        mov     [rbx + QUOTATION_PARENT_OFFSET], rax
        _2drop
        next
endcode

; ### quotation-local-names
code quotation_local_names, 'quotation-local_names' ; quotation -> hashtable/nil
        _ check_quotation
        mov     rbx, [rbx + QUOTATION_LOCAL_NAMES_OFFSET]
        next
endcode

; ### quotation-set-local-names
code quotation_set_local_names, 'quotation-set-local-names' ; x quotation -> void
        _ check_quotation
        mov     rax, [rbp]
        mov     [rbx + QUOTATION_LOCAL_NAMES_OFFSET], rax
        _2drop
        next
endcode

; ### quotation-add-local-name
code quotation_add_local_name, 'quotation-add-local-name' ; n string quotation -> void
        _dup
        _ quotation_local_names
        cmp     rbx, NIL
        _drop                           ; -> n string quotation
        jne     .1
        _lit tagged_fixnum(8)
        _ new_hashtable
        _over
        _ quotation_set_local_names     ; -> n string quotation
.1:
        _ quotation_local_names
        _ verify_hashtable
        _ hashtable_set_at
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
        cmp     bl, STATIC_SYMBOL_TAG
        je      .static_symbol

        cmp     bl, STATIC_QUOTATION_TAG
        je      .static_quotation

        cmp     bl, HANDLE_TAG
        jne     error_not_callable

        ; -> handle
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_SYMBOL
        je      .symbol

        cmp     word [rax], TYPECODE_QUOTATION
        jne     error_not_callable

        ; rax: ^quotation
        mov     rax, [rax + QUOTATION_RAW_CODE_ADDRESS_OFFSET]  ; rax: raw code address
        test    rax, rax
        jz      .compile_quotation
        mov     rbx, rax
        next

.static_symbol:
        _untag_static_symbol
        mov     rbx, [rbx + SYMBOL_RAW_CODE_ADDRESS_OFFSET]
        next

.static_quotation:
        _untag_static_quotation
        mov     rbx, [rbx + QUOTATION_RAW_CODE_ADDRESS_OFFSET]
        next

.symbol:
        mov     rbx, [rax + SYMBOL_RAW_CODE_ADDRESS_OFFSET]
        next

.compile_quotation:
        ; rbx: handle

;         _quote "callable_raw_code_address calling compile_quotation"
;         _ dprintf
;         _dup
;         _ dot_object

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
        _ quotation_array               ; -> array/nil

        _dup
        _ array?
        _tagged_if .1
        _quote "[ "
        _ string_to_sbuf
        _swap                           ; -> sbuf array/nil
        _quotation .2
        _ object_to_string
        _over
        _ sbuf_append_string
        _lit tagged_char(32)
        _over
        _ sbuf_push
        _end_quotation .2
        _ array_each
        _tagged_char(']')
        _over
        _ sbuf_push
        _ sbuf_to_string
        _else .1
        _drop
        _quote "[ ]"
        _then .1
        next
endcode
