; Copyright (C) 2017 Peter Graves <gnooth@gmail.com>

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

; ### format-type-error
code format_type_error, 'format-type-error'     ; object expected-type -- string
        _quote "ERROR: the value %S is not %s."
        _ format
        _ error
        next
endcode

; ### error-not-number
code error_not_number, 'error-not-number'       ; x --
        _quote "a number"
        _ format_type_error
        next
endcode

; ### error-not-fixnum
code error_not_fixnum, 'error-not-fixnum'       ; x --
        _quote "a fixnum"
        _ format_type_error
        next
endcode

; ### error-not-bignum
code error_not_bignum, 'error-not-bignum'       ; x --
        _quote "a bignum"
        _ format_type_error
        next
endcode

; ### error-not-float
code error_not_float, 'error-not-float'         ; x --
        _quote "a float"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-char
code error_not_char, 'error-not-char'           ; x --
        _quote "a character"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-string
code error_not_string, 'error-not-string' ; x --
        _quote "a string"
        _ format_type_error
        _ error
        next
endcode
