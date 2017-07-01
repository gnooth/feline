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
        _lit MOST_POSITIVE_FIXNUM
        _tag_fixnum
        next
endcode

; ### most-negative-fixnum
code most_negative_fixnum, 'most-negative-fixnum'
        _lit MOST_NEGATIVE_FIXNUM
        _tag_fixnum
        next
endcode

; ### fixnum?
code fixnum?, 'fixnum?'                 ; x -- ?
        and     ebx, TAG_MASK
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
        mov     al, bl
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .false
        test    rbx, rbx
        js      .false
        mov     ebx, t_value
        _return
.false:
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
code feline_min, 'min'                  ; x y -- z
        _check_fixnum
        _swap
        _check_fixnum
        popd    rax
        cmp     rax, rbx
        jge     .1
        mov     rbx, rax
.1:
        _tag_fixnum
        next
endcode

; ### max
code feline_max, 'max'                  ; x y -- z
        _check_fixnum
        _swap
        _check_fixnum
        popd    rax
        cmp     rax, rbx
        jle     .1
        mov     rbx, rax
.1:
        _tag_fixnum
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
        mov     rcx, MOST_POSITIVE_FIXNUM
        cmp     rbx, rcx
        jg      .1
        mov     rdx, MOST_NEGATIVE_FIXNUM
        cmp     rbx, rdx
        jl      .1
        _tag_fixnum
        _return
.1:

%ifdef FELINE_FEATURE_BIGNUMS
        _ signed_to_bignum
%else
        _ raw_int64_to_float
%endif

        next
endcode

; ### fixnum-fixnum-
code fixnum_fixnum_minus, 'fixnum-fixnum-'      ; fixnum1 fixnum2 -- difference
        _check_fixnum
        _swap
        _check_fixnum
        sub     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     rcx, MOST_POSITIVE_FIXNUM
        cmp     rbx, rcx
        jg      .1
        mov     rdx, MOST_NEGATIVE_FIXNUM
        cmp     rbx, rdx
        jl      .1
        _tag_fixnum
        _return
.1:

%ifdef FELINE_FEATURE_BIGNUMS
        _ signed_to_bignum
%else
        _ raw_int64_to_float
%endif

        next
endcode

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-fixnum+
code bignum_fixnum_plus, 'bignum-fixnum+'       ; bignum fixnum -- sum
        ; second arg must be a fixnum
        _ verify_fixnum
        _ fixnum_to_bignum

        ; first arg must be a bignum
        _swap
        _ verify_bignum

        _ bignum_bignum_plus
        next
endcode

; ### bignum-fixnum-
code bignum_fixnum_minus, 'bignum-fixnum-'      ; bignum fixnum -- difference
        ; second arg must be a fixnum
        _ verify_fixnum
        _ fixnum_to_bignum

        ; first arg must be a bignum
        _swap
        _ verify_bignum
        _swap

        _ bignum_bignum_minus
        next
endcode
%endif

; ### fixnum+
code fixnum_plus, 'fixnum+'           ; number fixnum -- sum

        ; second arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        mov     al, byte [rbp]
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_fixnum_plus
        _return

.1:

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_plus
        _return
        _then .2
%endif

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
        mov     al, byte [rbp]
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_fixnum_minus
        _return

.1:

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_minus
        _return
        _then .2
%endif

        _over
        _ float?
        _tagged_if .3
        _ fixnum_to_float
        _ float_float_minus
        _return
        _then .3

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

%ifdef FELINE_FEATURE_BIGNUMS

.2:
        _ signed_to_bignum
        _nip
        _return
.1:
        mov     rbx, rax
        _ signed_to_bignum
        _swap
        _ signed_to_bignum
        _ bignum_bignum_multiply

%else

.2:
        _ raw_int64_to_float
        _nip
        _return
.1:
        mov     rbx, rax
        _ raw_int64_to_float
        _swap
        _ raw_int64_to_float
        _ float_float_multiply

%endif

        next
endcode

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-fixnum*
code bignum_fixnum_multiply, 'bignum-fixnum*'   ; x y -- z
        _check_fixnum
        _ signed_to_bignum
        _swap
        _ verify_bignum
        _ bignum_bignum_multiply
        next
endcode
%endif

; ### fixnum*
code fixnum_multiply, 'fixnum*'         ; x y -- z

        ; second arg must be a fixnum
        _verify_fixnum

        ; dispatch on type of first arg
        mov     al, byte [rbp]
        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     .1
        _ fixnum_fixnum_multiply
        _return

.1:

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_multiply
        _return
        _then .2
%endif

        _over
        _ float?
        _tagged_if .3
        _ fixnum_to_float
        _ float_float_multiply
        _return
        _then .3

        _drop
        _ error_not_number
        next
endcode

; ### fixnum-fixnum/i
code fixnum_fixnum_divide_truncate, 'fixnum-fixnum/i'   ; x y -- z
        _check_fixnum
        _swap
        _check_fixnum
        _swap

        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rax
        lea     rbp, [rbp + BYTES_PER_CELL]

        mov     rax, -MOST_NEGATIVE_FIXNUM
        cmp     rbx, rax
        jne     .1

%ifdef FELINE_FEATURE_BIGNUMS
        _ signed_to_bignum
%else
        _ raw_int64_to_float
%endif

        _return

.1:
        _tag_fixnum
        next
endcode

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-fixnum/i
code bignum_fixnum_divide_truncate, 'bignum-fixnum/i'   ; x y -- z
        _ fixnum_to_bignum
        _swap
        _ verify_bignum
        _swap
        _ bignum_bignum_divide_truncate
        next
endcode
%endif

; ### fixnum/i
code fixnum_divide_truncate, 'fixnum/i' ; x y -- z
        _ verify_fixnum

        _over_fixnum?_if .1
        _ fixnum_fixnum_divide_truncate
        _return
        _then .1

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_divide_truncate
        _return
        _then .2
%endif

        _over
        _ float?
        _tagged_if .3
        _ fixnum_to_float
        _ float_float_divide
        _ float_to_integer
        _return
        _then .3

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

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-fixnum/f
code bignum_fixnum_divide_float, 'bignum-fixnum/f'      ; x y -- z
        _ fixnum_to_float
        _swap
        _ bignum_to_float
        _swap
        _ float_float_divide
        next
endcode
%endif

; ### fixnum/f
code fixnum_divide_float, 'fixnum/f'    ; x y -- z
        _ verify_fixnum

        _over_fixnum?_if .1
        _ fixnum_fixnum_divide_float
        _return
        _then .1

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_divide_float
        _return
        _then .2
%endif

        _over
        _ float?
        _tagged_if .3
        _ fixnum_to_float
        _ float_float_divide
        _return
        _then .3

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

%ifdef FELINE_FEATURE_BIGNUMS
; ### bignum-fixnum-mod
code bignum_fixnum_mod, 'bignum-fixnum-mod'     ; x y -- z
        _ fixnum_to_bignum
        _swap
        _ verify_bignum
        _swap
        _ bignum_bignum_mod
        next
endcode
%endif

; ### fixnum-mod
code fixnum_mod, 'fixnum-mod'                   ; x y -- z
        _verify_fixnum

        _over_fixnum?_if .1
        _ fixnum_fixnum_mod
        _return
        _then .1

%ifdef FELINE_FEATURE_BIGNUMS
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_mod
        _return
        _then .2
%endif

        _drop
        _ error_not_number

        next
endcode

; ### fixnum-negate
code fixnum_negate, 'fixnum-negate'     ; n -- -n
        _dup
        _ most_negative_fixnum
        _eq?
        _tagged_if .1
%ifdef FELINE_FEATURE_BIGNUMS
        _ fixnum_to_bignum
        _ bignum_negate
%else
        ; REVIEW
        mov     rbx, MOST_NEGATIVE_FIXNUM
        neg     rbx
        _ raw_int64_to_float
%endif
        _else .1
        _untag_fixnum
        neg     rbx
        _tag_fixnum
        _then .1
        next
endcode

; ### fixnum-bitand
code fixnum_bitand, 'fixnum-bitand'     ; n1 n2 -- n3
        _untag_2_fixnums
        _and
        _tag_fixnum
        next
endcode

; ### bitand
code bitand, 'bitand'   ; n1 n2 -- n3
        _check_fixnum
        _check_fixnum qword [rbp]
        _and
        _tag_fixnum
        next
endcode

; ### bitor
code bitor, 'bitor'     ; n1 n2 -- n3
        _check_fixnum
        _check_fixnum qword [rbp]
        _or
        _tag_fixnum
        next
endcode

; ### bitnot
code bitnot, 'bitnot'   ; x -- y
        _check_fixnum
        not     rbx
        _tag_fixnum
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
code raw_int64_to_decimal, 'raw_int64_to_decimal', SYMBOL_INTERNAL      ; int64 -- string

        _lit 128
        _ new_sbuf_untagged             ; handle

        push    r12
        push    this_register

        mov     this_register, [rbx]    ; raw address
        poprbx                          ; -- int64

        mov     rax, rbx                ; int64 in rax

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
        _ concat
        next
endcode
