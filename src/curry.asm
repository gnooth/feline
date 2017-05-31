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

%macro  _curry_object 0                 ; curry -- object
        _slot1
%endmacro

%macro  _this_curry_object 0            ; -- object
        _this_slot1
%endmacro

%macro  _this_curry_set_object 0        ; object --
        _this_set_slot1
%endmacro

%macro  _curry_callable 0               ; curry -- callable
        _slot2
%endmacro

%macro  _this_curry_callable 0          ; -- callable
        _this_slot2
%endmacro

%macro  _curry_set_callable 0           ; callable curry --
        _set_slot2
%endmacro

%macro  _this_curry_set_callable 0      ; callable --
        _this_set_slot2
%endmacro

%macro  _curry_code_address 0           ; curry -- code-address
        _slot3
%endmacro

%macro  _this_curry_set_code_address 0  ; code-address --
        _this_set_slot3
%endmacro

; ### curry?
code curry?, 'curry?'                   ; handle -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_raw_typecode
        _eq? TYPECODE_CURRY
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-curry
code error_not_curry, 'error-not-curry' ; x --
        ; REVIEW
        _error "not a curry"
        next
endcode

; ### verify-curry
code verify_curry, 'verify-curry'       ; handle -- handle
        _dup
        _ curry?
        _tagged_if .1
        _return
        _then .1

        _ error_not_curry
        next
endcode

; ### check-curry
code check_curry, 'check-curry'         ; x -- curry
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- raw-object/0
        _dup_if .2
        _dup
        _object_raw_typecode
        _eq? TYPECODE_CURRY
        _tagged_if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_curry
        next
endcode

; ### curry-object
code curry_object, 'curry-object'       ; curry -- object
        _ check_curry
        _curry_object
        next
endcode

; ### curry-callable
code curry_callable, 'curry-callable'   ; curry -- callable
        _ check_curry
        _curry_callable
        next
endcode

; ### curry-code-address
code curry_code_address, 'curry-code-address' ; curry -- code-address
        _ check_curry
        _curry_code_address
        next
endcode

; ### verify-callable
code verify_callable, 'verify-callable' ; callable -- callable
        _dup
        _ quotation?
        _tagged_if .1
        _return
        _then .1

        _dup
        _ curry?
        _tagged_if .2
        _return
        _then .2

        _dup
        _ symbol?
        _tagged_if .3
        _return
        _then .3

        _error "not a callable"

        next
endcode

; ### curry
code curry, 'curry'                     ; object callable -- curry
; 4 cells: object header, object, callable, code address

        _lit 4
        _ raw_allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- object callable

        _this_object_set_raw_typecode TYPECODE_CURRY

        _ verify_callable

        _dup
        _ symbol?
        _tagged_if .1
        _ one_array
        _ array_to_quotation
        _then .1

        _this_curry_set_callable

        _ literalize
        _this_curry_set_object

        ; compile curry
        _lit 64
        _ allocate_executable
        _dup
        _this_curry_set_code_address
        mov     [pc_], rbx
        poprbx
        _this_curry_object
        _ compile_literal
        _this_curry_callable
        _ compile_literal
        _lit call_quotation
        _ compile_call
        _lit $0c3
        _ emit_byte

        pushrbx
        mov     rbx, this_register      ; -- curry
        pop     this_register

        ; return handle
        _ new_handle                    ; -- handle

        next
endcode

; ### ~curry
code destroy_curry, '~curry'            ; handle --
        _ check_curry                   ; -- curry
        _ destroy_curry_unchecked
        next
endcode

; ### ~curry-unchecked
code destroy_curry_unchecked, '~curry-unchecked' ; curry --
        _dup
        _curry_code_address
        _?dup_if .1
        _ free_executable
        _then .1

        _ in_gc?
        _tagged_if_not .2
        _dup
        _ release_handle_for_object
        _then .2

        ; Zero out the object header so it won't look like a valid object
        ; after it has been destroyed.
        xor     eax, eax
        mov     [rbx], rax

        _ raw_free

        next
endcode

; ### curry-length
code curry_length, 'curry-length'       ; curry -- length
        _ check_curry
        _curry_callable
        _ length
        _untag_fixnum
        add     rbx, 1
        _tag_fixnum
        next
endcode

; ### curry-nth-unsafe
code curry_nth_unsafe, 'curry-nth-unsafe'       ; index curry -- element
        _handle_to_object_unsafe
        cmp     qword [rbp], tagged_zero
        jne     .1
        _nip
        _curry_object
        _return
.1:
        ; non-zero index
        _swap
        _lit tagged_fixnum(1)
        _ fixnum_minus
        _swap
        _curry_callable
        _ nth_unsafe
        next
endcode

; ### curry-nth
code curry_nth, 'curry-nth'             ; index curry -- element
        _verify_index qword [rbp]
        _ check_curry
        cmp     qword [rbp], tagged_zero
        jne     .1
        _nip
        _curry_object
        _return
.1:
        ; non-zero index
        _swap
        _lit tagged_fixnum(1)
        _ fixnum_minus
        _swap
        _curry_callable
        _ nth
        next
endcode

; ### curry>string
code curry_to_string, 'curry>string'            ; curry -- string
        _ verify_curry
        _quote "[ "
        _ string_to_sbuf
        _swap                           ; -- sbuf curry
        _dup
        _ curry_length
        _untag_fixnum
        _register_do_times .1
        _tagged_loop_index
        _over
        _ curry_nth_unsafe
        _ object_to_string
        _pick
        _ sbuf_append_string
        _lit tagged_char(32)
        _pick
        _ sbuf_push
        _loop .1
        _drop
        _lit tagged_char(']')
        _over
        _ sbuf_push
        _ sbuf_to_string
        next
endcode

; ### .curry-internal
code dot_curry_internal, '.curry-internal'      ; curry --
        _ verify_curry
        _dup
        _ curry_object
        _ dot_object
        _ space
        _ curry_callable
        _dup
        _ quotation?
        _tagged_if .1
        _ quotation_array
        _quotation .2
        _ dot_object
        _ space
        _end_quotation .2
        _ each
        _else .1
        ; must be a curry
        _ dot_curry_internal
        _then .1
        next
endcode

; ### .curry
code dot_curry, '.curry'                ; curry --
        _write "[ "
        _ dot_curry_internal
        _write "]"
        next
endcode
