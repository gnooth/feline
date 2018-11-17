; Copyright (C) 2018 Peter Graves <gnooth@gmail.com>

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

; ### make-deferred
code make_deferred, 'make-deferred'     ; symbol -> void
        _dup
        _ symbol_set_deferred_bit       ; -> symbol
        _lit S_error_no_definition
        _ one_array
        _ array_to_quotation            ; -> symbol quotation
        _over
        _ symbol_set_def
        _lit error_no_definition        ; -> symbol raw-code-address
        _over
        _ symbol_set_value
        _ compile_deferred
        next
endcode

; ### defer
code defer, 'defer', SYMBOL_IMMEDIATE
        _ parse_name
        _ make_deferred
        next
endcode

; ### verify-deferred
code verify_deferred, 'verify-deferred' ; symbol -> symbol
        _dup
        _ deferred?
        _tagged_if_not .1
        _ error_not_deferred
        _then .1
        next
endcode

; ### defer!
code defer_store, 'defer!'              ; symbol1 symbol2 -> void
        _ verify_deferred
        cmp     rbx, [rbp]
        jne     .1
        _error "ERROR: the arguments to `defer!` must not be identical."
.1:
        _swap
        _ symbol_raw_code_address
        _swap
        _ symbol_set_value
        next
endcode

; ### error-not-deferred
code error_not_deferred, 'error-not-deferred'   ; symbol ->
        _quote "ERROR: the word `%s` is not deferred."
        _ format
        _ error
        next
endcode

; ### error-no-definition
code error_no_definition, 'error-no-definition' ; void -> void
        _quote "ERROR: no definition for deferred word."
        _ error
        next
endcode
