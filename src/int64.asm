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

; 2 cells: object header, raw value

%macro  _int64_raw_value 0              ; int64 -- raw-value
        _slot1
%endmacro

%macro  _int64_set_raw_value 0          ; raw-value int64 ->
        _set_slot1
%endmacro

%define __this_int64_raw_value this_slot1

%macro  _this_int64_raw_value 0         ; -> raw-value
        _this_slot1
%endmacro

%macro  _this_int64_set_raw_value 0     ; raw-value ->
        _this_set_slot1
%endmacro

; ### int64?
code int64?, 'int64?'                   ; handle -> ?
        _ deref                         ; -> raw-object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_INT64
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### verify-int64
code verify_int64, 'verify-int64'       ; x -> x
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_INT64
        jne     .error
        _drop
        _return
.error:
        _drop                           ; -> x
        jmp     error_not_int64
        next
endcode

; ### check_int64
code check_int64, 'check_int64'         ; handle -> raw-int64
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_INT64
        jne     .error
        _nip
        _int64_raw_value
        next
.error:
        _drop
        _ error_not_int64
        next
endcode

; ### int64_raw_value
code int64_raw_value, 'int64_raw_value', SYMBOL_INTERNAL
; handle -> raw-int64
        _ deref
        _int64_raw_value
        next
endcode

; ### new_int64
code new_int64, 'new_int64', SYMBOL_INTERNAL ; raw-int64 -> int64

        ; 2 cells: object header, raw value
        mov     arg0_register, 2 * BYTES_PER_CELL

        _ feline_malloc

        mov     qword [rax], TYPECODE_INT64
        mov     [rax + BYTES_PER_CELL], rbx

        ; return handle
        mov     rbx, rax
        _ new_handle

        next
endcode

; ### normalize
code normalize, 'normalize'             ; raw-int64 -> fixnum-or-int64
        mov     rcx, MOST_POSITIVE_FIXNUM
        cmp     rbx, rcx
        jg      new_int64
        mov     rdx, MOST_NEGATIVE_FIXNUM
        cmp     rbx, rdx
        jl      new_int64
        _tag_fixnum
        next
endcode

; ### raw_int64_int64_plus
code raw_int64_int64_plus, 'raw_int64_int64_plus', SYMBOL_INTERNAL
; x y -> z
        _twodup
        add     rbx, [rbp]
        jo      .1
        _3nip
        _ normalize
        _return
.1:
        _2drop
        _ raw_int64_to_float
        _swap
        _ raw_int64_to_float
        _ float_float_plus
        next
endcode

; ### fixnum-int64+
code fixnum_int64_plus, 'fixnum-int64+' ; x y -> z
        _ check_int64
        _swap
        _check_fixnum
        _ raw_int64_int64_plus
        next
endcode

; ### int64-int64+
code int64_int64_plus, 'int64-int64+'   ; x y -> z
        _ check_int64
        _swap
        _ check_int64
        _ raw_int64_int64_plus
        next
endcode

; ### int64+
code int64_plus, 'int64+'               ; x y -> z

        ; second arg must be int64
        _ verify_int64

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        _drop                           ; -> x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_int64_plus

        cmp     rax, TYPECODE_INT64
        je      int64_int64_plus

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ int64_to_float
        jmp     float_float_plus

.1:
        _drop
        _ error_not_number

        next
endcode

; ### raw_int64_int64_minus
code raw_int64_int64_minus, 'raw_int64_int64_minus', SYMBOL_INTERNAL
; x y -> z
        _twodup
        neg     rbx
        add     rbx, [rbp]
        jo      .1
        _3nip
        _ normalize
        _return
.1:
        _2drop
        _ raw_int64_to_float
        _swap
        _ raw_int64_to_float
        _swap
        _ float_float_minus
        next
endcode

; ### fixnum-int64-
code fixnum_int64_minus, 'fixnum-int64-'        ; x y -> z
        _ check_int64
        _swap
        _check_fixnum
        _swap
        _ raw_int64_int64_minus
        next
endcode

; ### int64-int64-
code int64_int64_minus, 'int64-int64-'  ; x y -> z
        _ check_int64
        _swap
        _ check_int64
        _swap
        _ raw_int64_int64_minus
        next
endcode

; ### int64-
code int64_minus, 'int64-'              ; x y -> z

        ; second arg must be int64
        _ verify_int64

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        _drop                           ; -> x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_int64_minus

        cmp     rax, TYPECODE_INT64
        je      int64_int64_minus

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ int64_to_float
        jmp     float_float_minus

.1:
        _drop
        _ error_not_number

        next
endcode

; ### raw_int64_int64_multiply
code raw_int64_int64_multiply, 'raw_int64_int64_multiply', SYMBOL_INTERNAL
; x y -> z
        _twodup
        mov     rax, rbx
        imul    rbx, [rbp]
        jo      .1
        _3nip
        _ normalize
        _return
.1:
        _2drop
        _ raw_int64_to_float
        _swap
        _ raw_int64_to_float
        _ float_float_multiply
        next
endcode

; ### fixnum-int64*
code fixnum_int64_multiply, 'fixnum-int64*'     ; x y -> z
        _ check_int64
        _swap
        _check_fixnum
        _ raw_int64_int64_multiply
        next
endcode

; ### int64-int64*
code int64_int64_multiply, 'int64-int64*'       ; x y -> z
        _ check_int64
        _swap
        _ check_int64
        _ raw_int64_int64_multiply
        next
endcode

; ### int64*
code int64_multiply, 'int64*'           ; x y -> z

        ; second arg must be int64
        _ verify_int64

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        _drop                           ; -> x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_int64_multiply

        cmp     rax, TYPECODE_INT64
        je      int64_int64_multiply

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ int64_to_float
        jmp     float_float_multiply

.1:
        _drop
        _ error_not_number

        next
endcode

; ### fixnum-int64/i
code fixnum_int64_divide_truncate, 'fixnum-int64/i'     ; x y -> z
        _ check_int64
        _swap
        _check_fixnum
        _swap
        _ raw_int64_divide_truncate
        next
endcode

; ### int64-int64/i
code int64_int64_divide_truncate, 'int64-int64/i'       ; x y -> z
        _ check_int64
        _swap
        _ check_int64
        _swap
        _ raw_int64_divide_truncate
        next
endcode

; ### int64/i
code int64_divide_truncate, 'int64/i'   ; x y -> z

        ; second arg must be int64
        _ verify_int64

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        _drop                           ; -> x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_int64_divide_truncate

        cmp     rax, TYPECODE_INT64
        je      int64_int64_divide_truncate

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ int64_to_float
        _ float_divide_truncate
        _return

.1:
        _drop
        _ error_not_number
        next
endcode

; ### fixnum-int64/f
code fixnum_int64_divide_float, 'fixnum-int64/f'        ; x y -> z
        _ int64_to_float
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_divide
        next
endcode

; ### int64-int64/f
code int64_int64_divide_float, 'int64-int64/f'  ; x y -> z
        _ int64_to_float
        _swap
        _ int64_to_float
        _swap
        _ float_float_divide
        next
endcode

; ### int64/f
code int64_divide_float, 'int64/f'      ; x y -> z

        ; second arg must be int64
        _ verify_int64

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        _drop

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_int64_divide_float

        cmp     rax, TYPECODE_INT64
        je      int64_int64_divide_float

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ int64_to_float
        _ float_float_divide
        _return

.1:
        _drop
        _ error_not_number
        next
endcode

; ### fixnum>int64
code fixnum_to_int64, 'fixnum>int64'    ; fixnum -> int64
        _check_fixnum
        _ new_int64
        next
endcode

; ### int64-negate
code int64_negate, 'int64-negate'       ; n -> -n
        _ check_int64
        mov     rax, MOST_POSITIVE_FIXNUM + 1
        cmp     rbx, rax
        jne     .0
        mov     rbx, MOST_NEGATIVE_FIXNUM
        _tag_fixnum
        _return
.0:
        mov     rax, MOST_NEGATIVE_INT64
        cmp     rbx, rax
        je      .1
        neg     rbx
        _ new_int64
        _return
.1:
        neg     rbx
        _ new_uint64
        next
endcode

; ### fixnum-int64-mod
code fixnum_int64_mod, 'fixnum-int64-mod'       ; x y -> z
        _ check_int64
        _swap
        _check_fixnum
        _swap
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rdx
        lea     rbp, [rbp + BYTES_PER_CELL]
        _ normalize
        next
endcode

; ### int64-int64-mod
code int64_int64_mod, 'int64-int64-mod' ; x y -> z
        _ check_int64
        _swap
        _ check_int64
        _swap
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rdx
        lea     rbp, [rbp + BYTES_PER_CELL]
        _ normalize
        next
endcode

; ### int64-mod
code int64_mod, 'int64-mod'             ; x y -> z
        _ verify_int64

        _over_fixnum?_if .1
        _ fixnum_int64_mod
        _return
        _then .1

        _over
        _ int64?
        _tagged_if .2
        _ int64_int64_mod
        _return
        _then .2

        _drop
        _ error_not_number

        next
endcode

; ### int64-abs
code int64_abs, 'int64-abs'             ; x -> y
        _ check_int64
        mov     rax, MOST_NEGATIVE_INT64
        cmp     rbx, rax
        je      .1
        mov     rax, rbx
        sar     rax, 63
        xor     rbx, rax
        sub     rbx, rax
        _ new_int64
        _return
.1:
        mov     rbx, MOST_POSITIVE_INT64
        _ raw_int64_to_float
        next
endcode

; ### raw_int64_to_hex
code raw_int64_to_hex, 'raw_int64_to_hex', SYMBOL_INTERNAL ; raw-int64 -> string

        push    r12
        push    this_register

        _lit 32
        _ new_sbuf_untagged             ; -> raw-int64 handle
        _handle_to_object_unsafe        ; -> raw-int64 sbuf

        mov     this_register, rbx
        _drop                           ; -> raw-int64

        mov     r12, rbx                ; raw int64 in r12
        _drop                           ; ->

        align   DEFAULT_CODE_ALIGNMENT
.1:
        mov     edx, r12d
        and     edx, 0xf

        mov     rcx, hexchars
        mov     dl, [rcx + rdx]

        _dup
        movzx   ebx, dl
        _ this_sbuf_push_raw_unsafe

        shr     r12, 4

        test    r12, r12
        jnz     .1

        _ this_sbuf_reverse
        _ this_sbuf_to_string

        pop     this_register
        pop     r12

        next
endcode

; ### int64>string
code int64_to_string, 'int64>string'    ; int64 -> string
        _ check_int64
        _ raw_int64_to_decimal
        next
endcode

; ### int64>hex
code int64_to_hex, 'int64>hex'          ; int64 -> string
        _ check_int64
        _ raw_int64_to_hex
        next
endcode

; ### most-positive-int64
code most_positive_int64, 'most-positive-int64'
        _lit MOST_POSITIVE_INT64
        _ new_int64
        next
endcode

; ### most-negative-int64
code most_negative_int64, 'most-negative-int64'
        _lit MOST_NEGATIVE_INT64
        _ new_int64
        next
endcode
