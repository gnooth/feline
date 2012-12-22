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
        _begin tonumber1
        _ dup
        _while tonumber1
        _ over
        _ cfetch
        _ digit
        _ zero?
        _if tonumber2
        _return
        _then tonumber2
        _ tor
        _ twoswap
        _ rfrom
        _ swap
        _ basefetch
        _ umstar
        _ drop
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

code convert, 'convert'                 ; n addr1 -- n addr2
        _begin convert0
        _oneplus
        _duptor                         ; -- n addr1+1          r: -- addr1+1
        _cfetch
        _ digit                         ; if successful: -- n n2 true  otherwise: -- n false
        _while convert0                 ; -- n n2
        _ swap
        _ basefetch
        _ star
        _ swap
        _ plus
        _rfrom
        _repeat convert0
        _rfrom
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

code number, 'number'                   ; addr -- n
        _duptor                         ; -- addr               r: -- addr
        _ zero
        _ swap                          ; -- 0 addr
        _ dup                           ; -- 0 addr addr
        _oneplus                        ; -- 0 addr addr+1
        _cfetch                         ; -- 0 addr char
        _lit '-'
        _ equal                         ; -- 0 addr flag
        _duptor                         ; -- 0 addr flag        r: -- addr flag
        _if number0
        _oneplus
        _then number0
        _ convert                       ; -- n addr             r: -- addr flag
        _ swap                          ; -- addr n
        _rfrom                          ; -- addr n flag        r: -- addr
        _if number1
        _ negate
        _then number1                   ; -- addr n
        _ swap                          ; -- n addr
        _rfetch
        _ dup
        _cfetch
        _ plus
        _oneplus
        _ equal
        _if number2
        _rfromdrop
        _else number2
        _rfrom
        _ missing
        _then number2
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
        _ rfrom
        _ basestore
        _ state
        _fetch
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
