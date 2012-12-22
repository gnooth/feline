; Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

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

variable base, 'base', 10

code basefetch, 'base@'                 ; -- n
        pushrbx
        mov     rbx, [base_data]
        next
endcode

code basestore, 'base!'                 ; n --
        mov     [base_data], rbx
        poprbx
        next
endcode

code binary, 'binary'
        mov     qword [base_data], 2
        next
endcode

code decimal, 'decimal'
        mov     qword [base_data], 10
        next
endcode

code hex, 'hex'
        mov     qword [base_data], 16
        next
endcode

value double?, 'double?', 0

code digit, 'digit'                     ; char -- n true  |  char -- false
        _ dup
        _lit '0'
        _lit '9'
        _oneplus
        _ within
        _if digit1
        _lit '0'
        _ minus
        _ dup
        _ basefetch
        _ lt
        _if digit2
        _ true
        _else digit2
        _ drop
        _ false
        _then digit2
        _return
        _then digit1
        _ upc
        _lit 'A'
        _ minus
        _ dup
        _ zlt
        _if digit3
        _ drop
        _ false
        _return
        _then digit3
        _lit 10
        _ plus
        _ dup
        _ basefetch
        _ ge
        _if digit4
        _ drop
        _ false
        _return
        _then digit4
        _ true
        next
endcode

code tonumber, '>number'                ; ud1 c-addr1 u1 -- ud2 c-addr2 u2
; CORE
        _begin tonumber1
        _ dup
        _while tonumber1
        _ over
        _cfetch
        _ digit
        _ zero?
        _if tonumber2
        _return
        _then tonumber2                 ; -- ud1 addr u1 digit
        _tor                            ; -- ud1 addr u1                r: -- digit
        _ twoswap                       ; -- c-addr u1 ud1              r: -- digit
        _rfrom                          ; -- c-addr u1 ud1 digit
        _ swap                          ; -- c-addr u1 lo digit hi
        _ basefetch                     ; -- c-addr u1 lo digit hi base
        _ umstar                        ; -- c-addr u1 lo digit ud
        _ drop                          ; -- c-addr u1 lo digit u
        _ rot
        _ basefetch
        _ umstar
        _ dplus
        _ twoswap
        _ one
        _ slashstring
        _repeat tonumber1
        next
endcode

code missing, 'missing'
        _ count
        _ type
        _dotq ' ?'
        _ cr
        _ source_id
        _ zgt
        _if missing1
        _dotq "line "
        _ source_line_number
        _fetch
        _ dot
        _ cr
        _then missing1
        _ abort
        next
endcode

value negative?, 'negative?', 0

code number?, 'number?'                 ; c-addr u -- d flag
        mov     qword [double?_data], 0
        _ over
        _ cfetch
        _lit '-'
        _ equal
        _if ixnumber1
        mov     qword [negative?_data], -1
        _ one
        _ slashstring
        _else ixnumber1
        mov     qword [negative?_data], 0
        _then ixnumber1
        _ zero
        _ zero
        _ twoswap
        _ tonumber                      ; -- ud c-addr' u'
        _ dup                           ; -- ud c-addr' u' u'
        _ zero?
        _if ixnumber3                   ; -- ud c-addr' u'
        ; no chars left over
        _ twodrop
        _ true
        _return
        _then ixnumber3
        ; one or more chars left over
        _ one
        _ notequal
        _if ixnumber4                   ; -- ud c-addr'
        _ drop
        _ false
        _return
        _then ixnumber4
        _ cfetch                        ; -- ud char
        _lit '.'
        _ equal
        _if ixnumber5
        mov     qword [double?_data], -1
        _ true
        _else ixnumber5
        _ false
        _then ixnumber5
        next
endcode

code number, 'number'                   ; string -- d
        _duptor
        _ count
        _ number?
        _ zero?
        _if xnumber1
        _ rfrom
        _ missing                       ; doesn't return
        _then xnumber1
        _rfromdrop
        _ negative?
        _if xnumber2
        _ dnegate
        _then xnumber2
        next
endcode

code number_in_base, 'number-in-base'   ; base -- number
        _ parse_name
        _ tick_word
        _ place
        _ tick_word
        _ count
        _ plus
        _ blchar
        _ swap
        _ cstore
        _ basefetch
        _ tor
        _ basestore
        _ tick_word
        _ number
        _ drop                          ; REVIEW
        _ rfrom
        _ basestore
        _ statefetch
        _if hexnum1
        _ literal
        _then hexnum1
        next

code binnum, 'b#', IMMEDIATE
        _lit 2
        _ number_in_base
        next
endcode

code decnum, 'd#', IMMEDIATE
        _lit 10
        _ number_in_base
        next
endcode

code hexnum, 'h#', IMMEDIATE
        _lit 16
        _ number_in_base
        next
endcode
