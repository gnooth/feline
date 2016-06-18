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

; ### compile-object
code compile_object, 'compile-object'   ; object --
        _ ?cr
        _dotq "compile-object "
        _dup
        _ dot_object
        _ cr

        _dup
        _ symbol?
        _tagged_if .1
        _ symbol_xt
        _ inline_or_call_xt
        _then .1
        next
endcode

; ### compile-quotation
code compile_quotation, 'compile_quotation' ;  quotation --
        _ ?cr
        _dotq "entering compile-quotation"
        _ cr

        _ align_code

        ; FIXME transitional
        _ here_c
        _ last_code
        _store

        _dup
        _ quotation_array
        _lit compile_object_xt
        _ each
        _ccommac $0c3

        _ last_code
        _fetch
        _swap
        _ quotation_set_code

        next
endcode

; ### compile-word
code compile_word, 'compile-word'       ; symbol --
        _ symbol_def
        _dup
        _ quotation?
        _tagged_if .1
        _ compile_quotation
        _else .1
        _error "not a quotation"
        _then .1
        next
endcode
