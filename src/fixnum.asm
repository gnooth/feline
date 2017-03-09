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

; ### error-not-index
code error_not_index, 'error-not-index' ; x --
        ; REVIEW
        _error "not an index"
        next
endcode

; ### verify-index
code verify_index, 'verify-index'     ; index -- index
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

; ### fixnum-equal?
code fixnum_equal?, 'fixnum-equal?'     ; obj1 obj2 -- ?
        _over
        _ bignum?
        _tagged_if .1
        _ fixnum_to_bignum
        _ bignum_equal?
        _else .1
        _2drop
        _f
        _then .1
        next
endcode

; ### fixnum<
inline fixnum_lt, 'fixnum<'             ; x y -- ?
; No type checking.
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovl   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### <
code feline_lt, '<'                     ; x y -- ?
; FIXME optimize
        _check_fixnum
        _swap
        _check_fixnum
        _swap
        _ fixnum_lt
        next
endcode

; ### fixnum<=
code fixnum_le, 'fixnum<='              ; x y -- ?
; No type checking.
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovle  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### <=
code feline_le, '<='                    ; x y -- ?
; FIXME optimize
        _ check_fixnum
        _swap
        _ check_fixnum
        _swap
        _ fixnum_le
        next
endcode

%macro _fixnum_gt 0
        _untag_fixnum
        _untag_fixnum qword [rbp]
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovg   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

; ### fixnum>
inline fixnum_gt, 'fixnum>'             ; x y -- ?
; No type checking.
        _fixnum_gt
endinline

; ### >
code feline_gt, '>'                     ; x y -- ?
        _verify_fixnum
        _verify_fixnum qword [rbp]
        _fixnum_gt
        next
endcode

%macro  _fixnum_ge 0
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovge  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

; ### fixnum>=
code fixnum_ge, 'fixnum>='              ; x y -- ?
; No type checking.
        _fixnum_ge
        next
endcode

; ### >=
code feline_ge, '>='                    ; x y -- ?
        _verify_fixnum qword [rbp]
        _verify_fixnum
        _fixnum_ge
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
        _ feline_ge
        _tagged_if .1
        _ feline_ge
        _else .1
        _drop
        mov     ebx, f_value
        _then .1
        next
endcode

; ### fixnum-fixnum+
code fixnum_fixnum_plus, 'fixnum-fixnum+'       ; fixnum fixnum -- sum
; no type checking
; both arguments are assumed to be fixnums
        _untag_fixnum
        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _untag_fixnum rax
        add     rbx, rax
        mov     rcx, MOST_POSITIVE_FIXNUM
        cmp     rbx, rcx
        jg      .1
        mov     rdx, MOST_NEGATIVE_FIXNUM
        cmp     rbx, rdx
        jl      .1
        _tag_fixnum
        _return
.1:
        _ signed_to_bignum
        next
endcode

; ### fixnum-fixnum-
code fixnum_fixnum_minus, 'fixnum-fixnum-'      ; fixnum1 fixnum2 -- difference
        _check_fixnum
        _swap
        _check_fixnum
        sub     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _tag_fixnum
        next
endcode

; ### bignum-fixnum+
code bignum_fixnum_plus, 'fixnum-bignum+'       ; bignum fixnum -- sum

        ; second arg must be a fixnum
        _ verify_fixnum
        _ fixnum_to_bignum

        ; first arg must be a bignum
        _over
        _ bignum?
        _tagged_if .1
        _ bignum_bignum_plus
        _return
        _then .1

        _error "not a bignum"

        next
endcode

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
        _over
        _ bignum?
        _tagged_if .2
        _ bignum_fixnum_plus
        _return
        _then .2

        _drop
        _ error_not_number
        next
endcode

; ### fixnum-
inline fixnum_minus, 'fixnum-'          ; x y -- z
; No type checking.
        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        sub     rax, rbx
        add     rax, FIXNUM_TAG
        mov     rbx, rax
endinline

; ### -
code feline_minus, '-'                  ; x y -- z
        _check_fixnum
        _swap
        _check_fixnum
        sub     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _tag_fixnum
        next
endcode

; ### fixnum*
code fixnum_multiply, 'fixnum*'         ; x y -- z
; No type checking.
        _untag_2_fixnums
        _star
        _tag_fixnum
        next
endcode

; ### *
code feline_multiply, '*'               ; x y -- z
        _check_fixnum
        _swap
        _check_fixnum
        _star
        _tag_fixnum
        next
endcode

%macro _divide 0
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rax
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

; ### fixnum/i
code fixnum_divide, 'fixnum/i'          ; n1 n2 -- n3
        _untag_2_fixnums
        _divide
        _tag_fixnum
        next
endcode

; ### /
code feline_divide, '/'
        _ check_fixnum
        _swap
        _ check_fixnum
        _swap
        _divide
        _tag_fixnum
        next
endcode

%unmacro _divide 0

%macro _mod 0
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rdx
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

; ### fixnum-mod
code fixnum_mod, 'fixnum-mod'           ; n1 n2 -- n3
        _untag_2_fixnums
        _mod
        _tag_fixnum
        next
endcode

; ### mod
code feline_mod, 'mod'                  ; n1 n2 -- n3
        _check_fixnum qword [rbp]
        _check_fixnum
        _mod
        _tag_fixnum
        next
endcode

%unmacro _mod 0

; ### negate-fixnum
code negate_fixnum, 'negate-fixnum'     ; n -- -n
; no type checking
        _dup
        _ most_negative_fixnum
        _eq?
        _tagged_if .1
        _ fixnum_to_bignum
        _ negate_bignum
        _else .1
        _untag_fixnum
        _negate
        _tag_fixnum
        _then .1
        next
endcode

; ### negate
code negate, 'negate'   ; n -- -n
        _dup
        _fixnum?
        _if .1
        _ negate_fixnum
        _return
        _then .1

        _dup
        _ bignum?
        _tagged_if .2
        _ negate_bignum
        _return
        _then .2

        _ error_not_number

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
%ifdef WIN64
        popd    r8                      ; buffer
        popd    r9                      ; size
        popd    rdx                     ; untagged-base
        popd    rcx                     ; untagged-fixnum
%else
        popd    rdx                     ; buffer
        popd    rcx                     ; size
        popd    rsi                     ; untagged-base
        popd    rdi                     ; untagged-fixnum
%endif
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
