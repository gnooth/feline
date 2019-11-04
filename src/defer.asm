; Copyright (C) 2018-2019 Peter Graves <gnooth@gmail.com>

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
        _dup
        _lit S_error_no_definition
        _ curry                         ; -> symbol quotation
        _ compile_quotation
        _dup                            ; -> symbol quotation quotation
        _pick                           ; -> symbol quotation quotation symbol
        _ symbol_set_def                ; -> symbol quotation
        _ quotation_raw_code_address    ; -> symbol raw-code-address
        _over
        _ symbol_set_value
        _ compile_deferred
        next
endcode

; ### defer
code defer, 'defer', SYMBOL_IMMEDIATE
        _lit S_defer
        _ top_level_only

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

; ### is
code is_, 'is', SYMBOL_IMMEDIATE        ; symbol1 ->
        _ must_parse_token              ; -> symbol1 string
        _ must_find_name                ; -> symbol1 symbol2

        _ in_definition?
        _ get
        _tagged_if .1
        _get_accum
        _dup
        _tagged_if .2
        _swap                           ; -> vector symbol2
        _ new_wrapper                   ; -> vector wrapper
        _over                           ; -> vector wrapper vector
        _ vector_push                   ; -> vector
        _lit S_defer_store
        _swap
        _ vector_push
        _else .2
        _drop
        _then .2
        _else .1
        ; not in definition
        _ defer_store
        _then .1

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
code error_no_definition, 'error-no-definition' ; symbol -> void
        _quote "ERROR: no definition for the deferred word `%s`."
        _ format
        _ error
        next
endcode
