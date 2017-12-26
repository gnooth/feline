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

; ### assertion-failed
code assertion_failed, 'assertion-failed'       ; location --
        _debug_?enough 1
        _to_global error_location
        _error "Assertion failed"
        next
endcode

; ### check-assert
code check_assert, 'check-assert'       ; x location --
        _debug_?enough 2
        _swap
        _tagged_if .1
        _drop
        _else .1
        _ assertion_failed
        _then .1
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
code check_assert_eq, 'check-assert-eq'         ; x y location --
        _debug_?enough 3
        _ rrot
        _eq?
        _tagged_if .1
        _drop
        _else .1
        _ assertion_failed
        _then .1
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
        _to_global error_location
        _quote "Assertion failed: %S %S ="
        _ format
        _ error
        _then .1
        next
endcode

; ### +failed+
feline_constant failed, '+failed+', S_failed

; ### check-assert-must-fail
code check_assert_must_fail, 'check-assert-must-fail'   ; quotation location --
        _debug_?enough 2
        _swap
        _quotation .1
        _drop
        _lit S_failed
        _end_quotation .1
        _ recover
        _dup
        _lit S_failed
        _eq?
        _tagged_if .2
        _2drop
        _else .2
        _ assertion_failed
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
        _ location
        _ accum_push
        _lit S_check_assert
        _ accum_push
        _else .1
        ; top level assertion
        _ location
        _ check_assert
        _then .1
        next
endcode

; ### assert-true
code assert_true, 'assert-true', SYMBOL_IMMEDIATE
        _ in_definition?
        _ get
        _tagged_if .1
        _ location
        _ accum_push
        _lit S_check_assert_true
        _ accum_push
        _else .1
        ; top level assertion
        _ location
        _ check_assert_true
        _then .1
        next
endcode

; ### assert-false
code assert_false, 'assert-false', SYMBOL_IMMEDIATE
        _ in_definition?
        _ get
        _tagged_if .1
        _ location
        _ accum_push
        _lit S_check_assert_false
        _ accum_push
        _else .1
        ; top level assertion
        _ location
        _ check_assert_false
        _then .1
        next
endcode

; ### assert-eq
code assert_eq, 'assert-eq', SYMBOL_IMMEDIATE
        _ in_definition?
        _ get
        _tagged_if .1
        _ location
        _ accum_push
        _lit S_check_assert_eq
        _ accum_push
        _else .1
        ; top level assertion
        _ location
        _ check_assert_eq
        _then .1
        next
endcode

; ### assert=
code assert_equal, 'assert=', SYMBOL_IMMEDIATE
        _ in_definition?
        _ get
        _tagged_if .1
        _ location
        _ accum_push
        _lit S_check_assert_equal
        _ accum_push
        _else .1
        ; top level assertion
        _ location
        _ check_assert_equal
        _then .1
        next
endcode

; ### assert-must-fail
code assert_must_fail, 'assert-must-fail', SYMBOL_IMMEDIATE
        _ in_definition?
        _ get
        _tagged_if .1
        _ location
        _ accum_push
        _lit S_check_assert_must_fail
        _ accum_push
        _else .1
        ; top level assertion
        _ location
        _ check_assert_must_fail
        _then .1
        next
endcode
