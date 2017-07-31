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
code error_not_string, 'error-not-string'       ; x --
        _quote "a string"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-symbol
code error_not_symbol, 'error-not-symbol'       ; x --
        _quote "a symbol"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-index
code error_not_index, 'error-not-index'         ; x --
        _quote "an index"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-vector
code error_not_vector, 'error-not-vector'       ; x --
        _quote "a vector"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-hashtable
code error_not_hashtable, 'error-not-hashtable' ; x --
        _quote "a hashtable"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-type
code error_not_type, 'error-not-type'           ; x --
        _quote "a type"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-enough-parameters
code error_not_enough_parameters, 'error-not-enough-parameters'         ; --
        _quote "ERROR: not enough parameters."
        _ error
        next
endcode

; ### error-data-stack-underflow
code error_data_stack_underflow, 'error-data-stack-underflow'           ; --
        ; fix underflow before going any further
        mov     rbp, [sp0_]

        _quote "ERROR: data stack underflow."
        _ error
        next
endcode

; ### error-not-method
code error_not_method, 'error-not-method'       ; x --
        _quote "a method"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-generic-function
code error_not_generic_function, 'error-not-generic-function'   ; x --
        _quote "a generic function"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-sbuf
code error_not_sbuf, 'error-not-sbuf'   ; x --
        _quote "a string buffer"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-uint64
code error_not_uint64, 'error-not-uint64'       ; x --
        _quote "a uint64"
        _ format_type_error
        _ error
        next
endcode

; ### error-not-int64
code error_not_int64, 'error-not-int64' ; x --
        _quote "an int64"
        _ format_type_error
        _ error
        next
endcode
