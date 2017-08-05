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
        _check_fixnum
        _check_fixnum qword [rbp]
        xor     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _tag_fixnum
        next
endcode

; ### bitnot
code bitnot, 'bitnot'                   ; x -- y
        _check_fixnum
        not     rbx
        _tag_fixnum
        next
endcode
