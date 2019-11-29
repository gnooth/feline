; Copyright (C) 2016-2018 Peter Graves <gnooth@gmail.com>

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

; ### unsafe-fixnum-bitand
inline unsafe_fixnum_bitand, 'unsafe-fixnum-bitand' ; x y -> z
        and     rbx, qword [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### bitand
code bitand, 'bitand'                   ; x y -> z
        _check_fixnum
        _check_fixnum qword [rbp]
        _and
        _tag_fixnum
        next
endcode

; ### integer_to_raw_bits
code integer_to_raw_bits, 'integer_to_raw_bits', SYMBOL_INTERNAL
; x -- y

        test    bl, FIXNUM_TAG
        jz      .1
        _untag_fixnum
        _return

.1:
        ; not a fixnum
        cmp     bl, HANDLE_TAG
        jne     error_not_integer

        _handle_to_object_unsafe

        test    rbx, rbx
        jz      error_empty_handle

        _object_raw_typecode_eax

        cmp     eax, TYPECODE_INT64
        je      .2
        cmp     eax, TYPECODE_UINT64
        je      .3

        _ error_not_integer
        _return

.2:
        _int64_raw_value
        _return

.3:
        _uint64_raw_value
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
        test    ebx, FIXNUM_TAG
        jz      .1
        test    qword [rbp], FIXNUM_TAG
        jz      .1
        ; x and y are both fixnums
        xor     rbx, [rbp]
        _nip
        or      rbx, 1
        next
.1:
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
        _ integer_to_raw_bits
        not     rbx
        _ normalize
        next
endcode

; ### lshift
code lshift, 'lshift'                   ; x n -- y
; shifts integer x to the left by n bits

        ; n must be >= 0
        _check_index

        ; "When the destination is 64 bits wide, the processor masks the upper
        ; two bits of the count, providing a count in the range of 0 to 63."
        cmp     rbx, 63
        ja      .error

        mov     ecx, ebx
        poprbx

        _ integer_to_raw_bits

        test    rbx, rbx
        jns     .unsigned
        shl     rbx, cl
        _ normalize
        _return

.unsigned:
        shl     rbx, cl
        _ normalize_unsigned
        _return

.error:
        ; REVIEW julia and lua return 0 in this situation
        _nip
        mov     ebx, tagged_zero
        next
endcode

; ### lshift-signed
code lshift_signed, 'lshift-signed'     ; x n -- y
; shifts fixnum x to the left by n bits
; n must be >= 0
        _check_index
        _swap
        _ integer_to_raw_bits
        _swap
        mov     ecx, ebx
        poprbx
        shl     rbx, cl
        _ normalize
        next
endcode

; ### rshift
code rshift, 'rshift'                   ; x n -- y
; shifts integer x to the right by n bits

        ; n must be >= 0
        _check_index

        mov     ecx, ebx                ; n (untagged) in ecx
        poprbx                          ; -- x
        test    bl, FIXNUM_TAG
        jz      .not_a_fixnum

        ; x is a fixnum
        sar     rbx, cl
        or      rbx, FIXNUM_TAG
        next

.not_a_fixnum:

        cmp     bl, HANDLE_TAG
        jne     error_not_integer

        _handle_to_object_unsafe

        test    rbx, rbx
        jz      error_empty_handle

        _object_raw_typecode_eax

        cmp     eax, TYPECODE_INT64
        je      .int64
        cmp     eax, TYPECODE_UINT64
        je      .uint64

        _ error_not_integer
        _return

.int64:
        _int64_raw_value
        sar     rbx, cl
        jmp     normalize

.uint64:
        _uint64_raw_value
        shr     rbx, cl
        jmp     normalize_unsigned

        ; not reached
        next
endcode
