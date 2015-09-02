; Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

; ### base
variable base, 'base', 10

; ### base@
code basefetch, 'base@'                 ; -- n
        pushrbx
        mov     rbx, [base_data]
        next
endcode

; ### base!
code basestore, 'base!'                 ; n --
        mov     [base_data], rbx
        poprbx
        next
endcode

; ### binary
code binary, 'binary'
        mov     qword [base_data], 2
        next
endcode

; ### decimal
code decimal, 'decimal'
; CORE
        mov     qword [base_data], 10
        next
endcode

; ### hex
code hex, 'hex'
; CORE EXT
        mov     qword [base_data], 16
        next
endcode

; ### double?
value double?, 'double?', 0

; ### digit
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
        _zlt
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

; ### >number
code tonumber, '>number'                ; ud1 c-addr1 u1 -- ud2 c-addr2 u2
; CORE
        _begin tonumber1
        _ dup
        _while tonumber1
        _ over
        _cfetch
        _ digit
        _zeq
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

; ### where
code where, 'where'                     ; --
        _ source_id
        _ zgt
        _if .1
        _ source_filename
        _fetch
        _ ?dup
        _if .2
        _ counttype
        _ space
        _then .2
        _dotq "line "
        _ source_line_number
        _fetch
        _ decdot
        _ cr
        _then .1
        next
endcode

; ### missing
code missing, 'missing'                 ; $addr --
        _cquote ' ?'
        _ appendstring
        _ msg
        _ store
        _lit -13
        _ throw
        next
endcode

; ### negative?
value negative?, 'negative?', 0

; ### number?
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
        _zeq
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

; ### maybe-change-base
code maybe_change_base, 'maybe-change-base'     ; addr u -- addr' u'
        _ twodup                        ; -- addr u addr u
        _if mcb1
        _cfetch
        _ dup
        _lit '$'
        _ equal
        _if mcb2
        _ drop
        _ one
        _ slashstring
        _ hex
        _else mcb2
        _lit '#'
        _ equal
        _if mcb3
        _ one
        _ slashstring
        _ decimal
        _then mcb3
        _then mcb2
        _else mcb1
        _ drop
        _then mcb1
        next
endcode

; ### number
code number, 'number'                   ; string -- d
        _duptor                         ; -- string             r: -- string
        _ count                         ; -- addr u
        _ basefetch
        _ tor
        _ maybe_change_base             ; -- addr' u'
        _ number?                       ; -- d flag
        _ rfrom
        _ basestore
        _zeq
        _if .1
        _ rfrom
        _ missing                       ; doesn't return
        _then .1
        _rfromdrop
        _ negative?
        _if .2
        _ dnegate
        _then .2
        next
endcode

; ### number-in-base
code number_in_base, 'number-in-base'   ; base -- number
        _ parse_name
        _ word_buffer
        _ place
        _ word_buffer
        _ count
        _ plus
        _ blchar
        _ swap
        _ cstore
        _ basefetch
        _ tor
        _ basestore
        _ word_buffer
        _ number
        _ drop                          ; REVIEW
        _ rfrom
        _ basestore
        _ statefetch
        _if hexnum1
        _ literal
        _then hexnum1
        next

; ### b#
code binnum, 'b#', IMMEDIATE
        _lit 2
        _ number_in_base
        next
endcode

; ### d#
code decnum, 'd#', IMMEDIATE
        _lit 10
        _ number_in_base
        next
endcode

; ### h#
code hexnum, 'h#', IMMEDIATE
        _lit 16
        _ number_in_base
        next
endcode
