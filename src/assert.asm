; Copyright (C) 2016-2020 Peter Graves <gnooth@gmail.com>

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

; ### assertion-failed
code assertion_failed, 'assertion-failed'       ; location --
        _debug_?enough 1
        _ set_error_location
        _error "Assertion failed"
        next
endcode

; ### check-assert
code check_assert, 'check-assert'       ; x location ->
        _debug_?enough 2
        cmp     qword [rbp], NIL
        je      .1
        _2drop
        next
.1:
        _nip
        _ assertion_failed
        next
endcode

; ### check-assert-true
code check_assert_true, 'check-assert-true'     ; x location --
        _debug_?enough 2
        _swap
        _t
        _eq?
        _tagged_if .1
        _drop
        _else .1
        _ assertion_failed
        _then .1
        next
endcode

; ### check-assert-false
code check_assert_false, 'check-assert-false'   ; x location --
        _debug_?enough 2
        _swap
        _f
        _eq?
        _tagged_if .1
        _drop
        _else .1
        _ assertion_failed
        _then .1
        next
endcode

; ### check-assert-eq
code check_assert_eq, 'check-assert-eq'         ; x y location ->
        _debug_?enough 3
        mov     rax, [rbp]
        cmp     rax, [rbp + BYTES_PER_CELL]
        jne     .1
        _3drop
        next
.1:
        _ set_error_location
        _quote "Assertion failed: %S %S assert-eq"
        _ format
        _ error
        next
endcode

; ### check-assert=
code check_assert_equal, 'check-assert='        ; x y location --
        _debug_?enough 3
        _ feline_2over
        _ feline_equal
        _tagged_if .1
        _3drop
        _else .1
        _ set_error_location
        _quote "Assertion failed: %S %S assert="
        _ format
        _ error
        _then .1
        next
endcode

; ### +failed+
; feline_constant failed, '+failed+', S_failed
inline failed, '+failed+'                 ; -> symbol
        _symbol failed
endinline

code check_assert_must_fail_recover, 'check_assert_must_fail_recover'
        _drop
        _symbol failed
        next
endcode

; ### check-assert-must-fail
code check_assert_must_fail, 'check-assert-must-fail' ; quotation location -> void
        _debug_?enough 2
        _swap
;         _symbol drop
;         _symbol failed
;         _ two_quotation
        _tick check_assert_must_fail_recover
        _ recover
        _dup
        _symbol failed
        _eq?
        _tagged_if .2
        ; The expected failure did occur. This is not an error!
        _2drop
        ; Forget saved error location.
        _nil
        _ set_error_location
        _else .2
        ; The expected failure did not occur. This is disappointing,
        ; since we were hoping for a failure, but we don't want to
        ; call recover here since the try quotation did not throw.
        _quote "Assertion failed"
        _ do_error1
        _ reset
        _then .2
        next
endcode

; ### accum-push
code accum_push, 'accum-push'   ; object --
        _ accum
        _ get
        _ vector_push
        next
endcode

; ### assert
code assert, 'assert', SYMBOL_IMMEDIATE
        _ in_definition?
        _ get
        _tagged_if .1
        _ current_lexer_location
        _ accum_push
        _symbol check_assert
        _ accum_push
        _else .1
        ; top level assertion
        _ current_lexer_location
        _ check_assert
        _then .1
        next
endcode

; ### assert-true
code assert_true, 'assert-true', SYMBOL_IMMEDIATE
        _ in_definition?
        _ get
        _tagged_if .1
        _ current_lexer_location
        _ accum_push
        _symbol check_assert_true
        _ accum_push
        _else .1
        ; top level assertion
        _ current_lexer_location
        _ check_assert_true
        _then .1
        next
endcode

; ### assert-false
code assert_false, 'assert-false', SYMBOL_IMMEDIATE
        _ in_definition?
        _ get
        _tagged_if .1
        _ current_lexer_location
        _ accum_push
        _symbol check_assert_false
        _ accum_push
        _else .1
        ; top level assertion
        _ current_lexer_location
        _ check_assert_false
        _then .1
        next
endcode

; ### assert-eq
code assert_eq, 'assert-eq', SYMBOL_IMMEDIATE
        _ in_definition?
        _ get
        _tagged_if .1
        _ current_lexer_location
        _ accum_push
        _symbol check_assert_eq
        _ accum_push
        _else .1
        ; top level assertion
        _ current_lexer_location
        _ check_assert_eq
        _then .1
        next
endcode

; ### assert=
code assert_equal, 'assert=', SYMBOL_IMMEDIATE
        _ in_definition?
        _ get
        _tagged_if .1
        _ current_lexer_location
        _ accum_push
        _symbol check_assert_equal
        _ accum_push
        _else .1
        ; top level assertion
        _ current_lexer_location
        _ check_assert_equal
        _then .1
        next
endcode

; ### assert-must-fail
code assert_must_fail, 'assert-must-fail', SYMBOL_IMMEDIATE
        _ in_definition?
        _ get
        _tagged_if .1
        _ current_lexer_location
        _ accum_push
        _symbol check_assert_must_fail
        _ accum_push
        _else .1
        ; top level assertion
        _ current_lexer_location
        _ check_assert_must_fail
        _then .1
        next
endcode
