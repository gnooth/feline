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

; ### error-out-of-memory
code error_out_of_memory, 'error-out-of-memory' ; --
        _quote "ERROR: out of memory."
        _ error
        next
endcode

; ### find-generic-from-return-address
code find_generic_from_return_address, 'find-generic-from-return-address'
; address -- symbol/f

        _quote "find-word-from-code-address"
        _ feline_vocab
        _ vocab_find_name               ; -- address symbol/string ?
        _tagged_if .1
        _ call_symbol                   ; -- symbol/f
        _return
        _then .1                        ; -- address string

        _drop
        mov     ebx, f_value
        next
endcode

; ### error-no-method
code error_no_method, 'error-no-method' ; object return-address --

        _ find_generic_from_return_address
        _dup
        _tagged_if .1
        _swap
        _quote "ERROR: the generic function `%S` has no method for the value %S."
        _else .1
        _drop
        _quote "ERROR: the generic function has no method for the value %S."
        _then .1

        _ format
        _ error

        next
endcode

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

; ### error-not-vocab
code error_not_vocab, 'error-not-vocab'         ; x --
        _quote "a vocabulary"
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

; ### error-not-tuple-class
code error_not_tuple_class, 'error-not-tuple-class'     ; x --
        _quote "a tuple-class"
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

; ### error-not-integer
code error_not_integer, 'error-not-integer'     ; x --
        _quote "an integer"
        _ format_type_error
        _ error
        next
endcode

; ### error-file-not-found
code error_file_not_found, 'error-file-not-found'
        _quote "ERROR: can't find %s."
        _ format
        _ error
        next
endcode
