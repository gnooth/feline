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

; ### fixnum?
code fixnum?, 'fixnum?'                 ; x -- t|f
        _fixnum?
        _tag_boolean
        next
endcode

; ### error-not-fixnum
code error_not_fixnum, 'error-not-fixnum' ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not a fixnum"
        next
endcode

; ### check-fixnum
code check_fixnum, 'check-fixnum'       ; fixnum -- untagged-fixnum
        _dup
        _fixnum?
        _if .1
        _untag_fixnum
        _else .1
        _ error_not_fixnum
        _then .1
        next
endcode

; ### fixnum<
code fixnum_lt, 'fixnum<'               ; x y -- t|f
; No type checking.
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovl   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### <
code feline_lt, '<'                     ; x y -- t|f
; FIXME optimize
        _ check_fixnum
        _swap
        _ check_fixnum
        _swap
        _ fixnum_lt
        next
endcode

; ### fixnum>=
code fixnum_ge, 'fixnum>='              ; x y -- t|f
; No type checking.
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovge  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### >=
code feline_ge, '>='                    ; x y -- t|f
; FIXME optimize
        _ check_fixnum
        _swap
        _ check_fixnum
        _swap
        _ fixnum_ge
        next
endcode

; ### fixnum+
code fixnum_plus, 'fixnum+'             ; x y -- x+y
; No type checking.
        _untag_2_fixnums
        _plus
        _tag_fixnum
        next
endcode

; ### +
code feline_plus, '+'                   ; x y -- x+y
        _ check_fixnum
        _swap
        _ check_fixnum
        _plus
        _tag_fixnum
        next
endcode

; ### fixnum-
code fixnum_minus, 'fixnum-'            ; x y -- x-y
; No type checking.
        _untag_2_fixnums
        neg     rbx
        add     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _tag_fixnum
        next
endcode

; ### -
code feline_minus, '-'                  ; x y -- x-y
        _ check_fixnum
        _swap
        _ check_fixnum
        sub     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _tag_fixnum
        next
endcode

; ### fixnum*
code fixnum_multiply, 'fixnum*'         ; x y -- x*y
; No type checking.
        _untag_2_fixnums
        imul    rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _tag_fixnum
        next
endcode

; ### *
code feline_multiply, '*'               ; x y -- x*y
        _ check_fixnum
        _swap
        _ check_fixnum
        imul    rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
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
        _ check_fixnum
        _swap
        _ check_fixnum
        _swap
        _mod
        _tag_fixnum
        next
endcode

%unmacro _mod 0
