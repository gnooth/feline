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

; ### fixnum-bitand
code fixnum_bitand, 'fixnum-bitand'     ; x y -- z
        _untag_2_fixnums
        _and
        _tag_fixnum
        next
endcode

; ### bitand
code bitand, 'bitand'                   ; x y -- z
        _check_fixnum
        _check_fixnum qword [rbp]
        _and
        _tag_fixnum
        next
endcode

; ### integer_to_raw_bits
code integer_to_raw_bits, 'integer_to_raw_bits', SYMBOL_INTERNAL        ; x -- y
        _dup
        _ fixnum?
        _tagged_if .1
        _untag_fixnum
        _return
        _then .1

        _dup
        _ int64?
        _tagged_if .2
        _ int64_raw_value
        _return
        _then .2

        _dup
        _ uint64?
        _tagged_if .3
        _ uint64_raw_value
        _return
        _then .3

        _ error_not_integer
        next
endcode

; ### bitor
code bitor, 'bitor'                     ; x y -- z
        _check_fixnum
        _check_fixnum qword [rbp]
        _or
        _tag_fixnum
        next
endcode

; ### bitxor
code bitxor, 'bitxor'                   ; x y -- z
        _ integer_to_raw_bits
        _swap
        _ integer_to_raw_bits
        xor     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _ normalize_unsigned
        next
endcode

; ### bitnot
code bitnot, 'bitnot'                   ; x -- y
        _check_fixnum
        not     rbx
        _tag_fixnum
        next
endcode

; ### lshift
code lshift, 'lshift'                   ; x n -- y
; shifts fixnum x to the left by n bits
; n must be >= 0
        _check_index
        _swap
        _ integer_to_raw_bits
        _swap
        mov     ecx, ebx
        poprbx
        shl     rbx, cl
        _ normalize_unsigned
        next
endcode

; ### rshift
code rshift, 'rshift'                   ; x n -- y
; shifts fixnum x to the right by n bits
; n must be >= 0
        _check_index
        _swap
        _ integer_to_raw_bits
        _swap
        mov     ecx, ebx
        poprbx
        shr     rbx, cl
        _ normalize_unsigned
        next
endcode
