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

; ### most-positive-fixnum
code most_positive_fixnum, 'most-positive-fixnum'
        _lit tagged_fixnum(MOST_POSITIVE_FIXNUM)
        next
endcode

; ### most-negative-fixnum
code most_negative_fixnum, 'most-negative-fixnum'
        _lit tagged_fixnum(MOST_NEGATIVE_FIXNUM)
        next
endcode

; ### fixnum?
code fixnum?, 'fixnum?'                 ; x -- ?
        and     ebx, FIXNUM_TAG_MASK
        cmp     ebx, FIXNUM_TAG
        mov     eax, t_value
        mov     ebx, f_value
        cmove   ebx, eax
        next
endcode

; ### verify-fixnum
code verify_fixnum, 'verify-fixnum'     ; fixnum -- fixnum
        _verify_fixnum
        next
endcode

; ### check-fixnum
code check_fixnum, 'check-fixnum'       ; fixnum -- untagged-fixnum
        _check_fixnum
        next
endcode

; ### fixnum-hashcode
code fixnum_hashcode, 'fixnum-hashcode' ; fixnum -- hashcode
        _verify_fixnum
        next
endcode

; ### verify-index
code verify_index, 'verify-index'       ; index -- index
        _verify_index
        next
endcode

; ### check-index
code check_index, 'check-index'         ; non-negative-fixnum -- untagged-fixnum
        _check_index
        next
endcode

; ### index?
code index?, 'index?'                   ; x -- ?
%if FIXNUM_TAG_BITS = 1 && FIXNUM_TAG = 1
        test    ebx, FIXNUM_TAG
        jz      .1
%else
        mov     al, bl
        and     al, FIXNUM_TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
%endif
        test    rbx, rbx
        js      .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### fixnum-min
code fixnum_min, 'fixnum-min'           ; x y -- z
; No type checking.
        _untag_2_fixnums
        popd    rax
        cmp     rax, rbx
        cmovl   rbx, rax
        _tag_fixnum
        next
endcode

; ### fixnum-max
code fixnum_max, 'fixnum-max'           ; x y -- z
; No type checking.
        _untag_2_fixnums
        popd    rax
        cmp     rax, rbx
        cmovg   rbx, rax
        _tag_fixnum
        next
endcode

; ### min
code generic_min, 'min'                 ; x y -- z
        _twodup
        _ generic_le
        _tagged_if .1
        _drop
        _else .1
        _nip
        _then .1
        next
endcode

; ### max
code generic_max, 'max'                 ; x y -- z
        _twodup
        _ generic_ge
        _tagged_if .1
        _drop
        _else .1
        _nip
        _then .1
        next
endcode

; ### between?
code between?, 'between?'               ; n min max -- ?
        _pick
        _ generic_ge
        _tagged_if .1
        _ generic_ge
        _else .1
        _drop
        mov     ebx, f_value
        _then .1
        next
endcode

; ### fixnum-fixnum+
code fixnum_fixnum_plus, 'fixnum-fixnum+'       ; fixnum1 fixnum2 -- sum
        _check_fixnum
        _swap
        _check_fixnum
        add     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _ normalize
        next
endcode

; ### int64-fixnum+
code int64_fixnum_plus, 'int64-fixnum+'         ; int64 fixnum -- sum

        _debug_?enough 2

        _check_fixnum
        _swap
        _ check_int64
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

; ### fixnum-fixnum-
code fixnum_fixnum_minus, 'fixnum-fixnum-'      ; fixnum1 fixnum2 -- difference
        _check_fixnum
        _swap
        _check_fixnum
        sub     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _ normalize
        next
endcode

; ### int64-fixnum-
code int64_fixnum_minus, 'int64-fixnum-'        ; int64 fixnum -- difference
        _check_fixnum
        _swap
        _ check_int64
        _swap
        _ raw_int64_int64_minus
        next
endcode

; ### fixnum+
code fixnum_plus, 'fixnum+'             ; number fixnum -- sum

        ; second arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        mov     al, byte [rbp]
        and     al, FIXNUM_TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_fixnum_plus
        _return

.1:
        _over
        _ int64?
        _tagged_if .2
        _ int64_fixnum_plus
        _return
        _then .2

        _over
        _ float?
        _tagged_if .3
        _ fixnum_to_float
        _ float_float_plus
        _return
        _then .3

        _drop
        _ error_not_number
        next
endcode

; ### fixnum-
code fixnum_minus, 'fixnum-'            ; number fixnum -- difference

        ; second arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_fixnum_minus

        cmp     rax, TYPECODE_INT64
        je      int64_fixnum_minus

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ fixnum_to_float
        jmp     float_float_minus

.1:
        _drop
        _ error_not_number
        next
endcode

; ### fixnum-fixnum*
code fixnum_fixnum_multiply, 'fixnum-fixnum*'   ; x y -- z
        _check_fixnum
        _swap
        _check_fixnum
        mov     rax, rbx
        imul    rbx, [rbp]
        jo      .1
        mov     rcx, MOST_POSITIVE_FIXNUM
        cmp     rbx, rcx
        jg      .2
        mov     rdx, MOST_NEGATIVE_FIXNUM
        cmp     rbx, rdx
        jl      .2
        _tag_fixnum
        _nip
        _return

.2:
        _ new_int64
        _nip
        _return

.1:
        mov     rbx, rax
        _ raw_int64_to_float
        _swap
        _ raw_int64_to_float
        _ float_float_multiply
        next
endcode

; ### int64-fixnum*
code int64_fixnum_multiply, 'int64-fixnum*'     ; x y -- z
        _check_fixnum
        _swap
        _ check_int64
        mov     rax, rbx
        imul    qword [rbp]             ; product in rdx:rax
        jo      .1
        mov     rcx, MOST_POSITIVE_FIXNUM
        cmp     rax, rcx
        jg      .2
        mov     rdx, MOST_NEGATIVE_FIXNUM
        cmp     rax, rdx
        jl      .2
        mov     rbx, rax
        _tag_fixnum
        _nip
        _return

.2:
        mov     rbx, rax
        _ new_int64
        _nip
        _return

.1:
        _ raw_int64_to_float
        _swap
        _ raw_int64_to_float
        _ float_float_multiply
        next
endcode

; ### fixnum*
code fixnum_multiply, 'fixnum*'         ; x y -- z

        ; second arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_fixnum_multiply

        cmp     rax, TYPECODE_INT64
        je      int64_fixnum_multiply

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ fixnum_to_float
        jmp     float_float_multiply

.1:
        _drop
        _ error_not_number
        next
endcode

; ### raw_int64_divide_truncate
code raw_int64_divide_truncate, 'raw_int64_divide_truncate', SYMBOL_INTERNAL
; x y -- z
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rax
        lea     rbp, [rbp + BYTES_PER_CELL]

        mov     rax, -MOST_NEGATIVE_FIXNUM
        cmp     rbx, rax
        jne     .1

        _ new_int64
        _return

.1:
        _tag_fixnum
        next
endcode

; ### fixnum-fixnum/i
code fixnum_fixnum_divide_truncate, 'fixnum-fixnum/i'   ; x y -- z
        _check_fixnum
        _swap
        _check_fixnum
        _swap
        _ raw_int64_divide_truncate
        next
endcode

; ### int64-fixnum/i
code int64_fixnum_divide_truncate, 'int64-fixnum/i'     ; x y -- z
        _check_fixnum
        _swap
        _ check_int64
        _swap
        _ raw_int64_divide_truncate
        next
endcode

; ### fixnum/i
code fixnum_divide_truncate, 'fixnum/i' ; x y -- z

        ; second arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx                          ; -- x y

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_fixnum_divide_truncate

        cmp     rax, TYPECODE_INT64
        je      int64_fixnum_divide_truncate

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ fixnum_to_float
        _ float_divide_truncate
        _return

.1:
        _drop
        _ error_not_number
        next
endcode

; ### fixnum-fixnum/f
code fixnum_fixnum_divide_float, 'fixnum-fixnum/f'      ; x y -- z
        _ fixnum_to_float
        _swap
        _ fixnum_to_float
        _swap
        _ float_float_divide
        next
endcode

; ### int64-fixnum/f
code int64_fixnum_divide_float, 'int64-fixnum/f'        ; x y -- z
        _ fixnum_to_float
        _swap
        _ int64_to_float
        _swap
        _ float_float_divide
        next
endcode

; ### fixnum/f
code fixnum_divide_float, 'fixnum/f'    ; x y -- z

        ; second arg must be a fixnum
        _ verify_fixnum

        ; dispatch on type of first arg
        _over
        _ object_raw_typecode
        mov     rax, rbx
        poprbx

        cmp     rax, TYPECODE_FIXNUM
        je      fixnum_fixnum_divide_float

        cmp     rax, TYPECODE_INT64
        je      int64_fixnum_divide_float

        cmp     rax, TYPECODE_FLOAT
        jne     .1
        _ fixnum_to_float
        _ float_float_divide
        _return

.1:
        _drop
        _ error_not_number
        next
endcode

; ### fixnum-fixnum-mod
code fixnum_fixnum_mod, 'fixnum-fixnum-mod'     ; x y -- z
        _check_fixnum
        _swap
        _check_fixnum
        _swap
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rdx
        lea     rbp, [rbp + BYTES_PER_CELL]
        _tag_fixnum
        next
endcode

; ### int64-fixnum-mod
code int64_fixnum_mod, 'int64-fixnum-mod'       ; x y -- z
        _check_fixnum
        _swap
        _ check_int64
        _swap
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rdx
        lea     rbp, [rbp + BYTES_PER_CELL]
        _tag_fixnum
        next
endcode

; ### fixnum-mod
code fixnum_mod, 'fixnum-mod'           ; x y -- z
        _verify_fixnum

        _over_fixnum?_if .1
        _ fixnum_fixnum_mod
        _return
        _then .1

        _over
        _ int64?
        _tagged_if .2
        _ int64_fixnum_mod
        _return
        _then .2

        _drop
        _ error_not_number

        next
endcode

; ### fixnum-abs
code fixnum_abs, 'fixnum-abs'           ; x -- y
        _check_fixnum
        mov     rax, MOST_NEGATIVE_FIXNUM
        cmp     rbx, rax
        je      .1
        mov     rax, rbx
        sar     rax, 63
        xor     rbx, rax
        sub     rbx, rax
        _tag_fixnum
        _return
.1:
        neg     rbx
        _ new_int64
        next
endcode

; ### fixnum-negate
code fixnum_negate, 'fixnum-negate'     ; n -- -n
        _dup
        _ most_negative_fixnum
        _eq?
        _tagged_if .1
        mov     rbx, MOST_NEGATIVE_FIXNUM
        neg     rbx
        _ new_int64
        _else .1
        _untag_fixnum
        neg     rbx
        _tag_fixnum
        _then .1
        next
endcode

; ### odd?
code odd?, 'odd?'                       ; n -- ?
        _check_fixnum                   ; -- untagged
        mov     eax, t_value
        and     ebx, 1
        mov     ebx, f_value
        cmovnz  ebx, eax
        next
endcode

; ### even?
code even?, 'even?'                     ; n -- ?
        _check_fixnum                   ; -- untagged
        mov     eax, t_value
        and     ebx, 1
        mov     ebx, f_value
        cmovz   ebx, eax
        next
endcode

; ### fixnum>binary
code fixnum_to_binary, 'fixnum>binary'  ; fixnum -- string

        _check_fixnum

        _lit 16
        _ new_sbuf_untagged

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- n

        _begin .1
        test    bl, 1
        jz      .2
        _tagged_char('1')
        _this
        _ sbuf_push
        jmp     .3
.2:
        _tagged_char('0')
        _this
        _ sbuf_push
.3:
        shr     rbx, 1
        jz      .4
        _again .1
.4:
        _drop

        _this
        _ sbuf_reverse_in_place
        _ sbuf_to_string

        pop     this_register
        next
endcode

; ### raw_int64_to_decimal
code raw_int64_to_decimal, 'raw_int64_to_decimal', SYMBOL_INTERNAL      ; raw-int64 -- string

        push    r12
        push    this_register

        _lit 128
        _ new_sbuf_untagged             ; -- raw-int64 handle
        _handle_to_object_unsafe        ; -- raw-int64 sbuf

        mov     this_register, rbx
        poprbx                          ; -- raw-int64

        mov     rax, rbx                ; raw-int64 in rax

        xor     r12, r12
        test    rax, rax
        jns     .1
        mov     r12, 1
        neg     rax

        align   DEFAULT_CODE_ALIGNMENT
.1:
        xor     edx, edx                ; zero-extend rax into rdx:rax

        mov     ecx, 10
        idiv    rcx                     ; quotient in rax, remainder in rdx

        push    rax

        add     edx, '0'
        pushrbx
        mov     ebx, edx

        _ this_sbuf_push_raw_unsafe

        pop     rax

        test    rax, rax
        jnz     .1

        _drop

        test    r12, r12
        jz      .2
        pushrbx
        mov     ebx, '-'
        _ this_sbuf_push_raw_unsafe
.2:

        _ this_sbuf_reverse
        _ this_sbuf_to_string

        pop     this_register
        pop     r12

        next
endcode

; ### fixnum>decimal
code fixnum_to_decimal, 'fixnum>decimal'        ; fixnum -- string
        _check_fixnum
        _ raw_int64_to_decimal
        next
endcode

; ### fixnum>base
code fixnum_to_base, 'fixnum>base'      ; fixnum base -- string

        _check_fixnum
        _swap
        _check_fixnum
        _swap                           ; -- untagged-fixnum untagged-base

; FIXME it's an error if base is not 10 or 16 here

untagged_to_base:

        _lit 256
        _dup
        _ raw_allocate                  ; -- untagged-fixnum untagged-base size buffer
        _duptor
        mov     arg2_register, rbx                              ; buffer
        mov     arg3_register, [rbp]                            ; size
        mov     arg1_register, [rbp + BYTES_PER_CELL]           ; untagged base
        mov     arg0_register, [rbp + BYTES_PER_CELL * 2]       ; untagged fixnum
        _4drop
        xcall   c_fixnum_to_base        ; number of chars printed in rax
        _rfetch                         ; -- buffer
        pushd   rax                     ; -- buffer size
        _ copy_to_string
        _rfrom
        _ raw_free
        next
endcode

; REVIEW
; ### untagged>hex
code untagged_to_hex, 'untagged>hex'    ; untagged -- string
        _lit 16
        _ untagged_to_base
        next
endcode

; ### fixnum>string
code fixnum_to_string, 'fixnum>string'  ; fixnum -- string
        _check_fixnum
        _lit 10
        _ untagged_to_base
        next
endcode

; ### fixnum>hex
code fixnum_to_hex, 'fixnum>hex'        ; fixnum -- string
        _check_fixnum
        _dup
        _zge
        _if .1
        _lit 16
        _ untagged_to_base
        _return
        _then .1

        ; < 0
        ; REVIEW
        _dup
        _lit MOST_NEGATIVE_FIXNUM
        _equal
        _if .2
        _drop
        _quote "-1000000000000000"
        _return
        _then .2

        ; otherwise...
        neg     rbx
        _lit 16
        _ untagged_to_base
        _quote "-"
        _swap
        _ string_append
        next
endcode
