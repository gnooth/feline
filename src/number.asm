; Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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
; CORE
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

; ### digit
code digit, 'digit'                     ; char -- n true  |  char -- false
        _dup
        _lit '0'
        _lit '9'
        _ between
        _if .1
        _lit '0'
        _minus
        _dup
        _ basefetch
        _ lt
        _if .2
        _true
        _else .2
        _drop
        _false
        _then .2
        _return
        _then .1
        _ upc
        _lit 'A'
        _minus
        _dup
        _zlt
        _if .3
        _drop
        _false
        _return
        _then .3
        _lit 10
        _plus
        _dup
        _ basefetch
        _ ge
        _if .4
        _drop
        _false
        _return
        _then .4
        _true
        next
endcode

; ### >number
code tonumber, '>number'                ; ud1 c-addr1 u1 -- ud2 c-addr2 u2
; CORE
        _begin .1
        _dup
        _while .1
        _over
        _cfetch
        _ digit
        _zeq_if .2
        _return
        _then .2                        ; -- ud1 addr u1 digit
        _tor                            ; -- ud1 addr u1                r: -- digit
        _ twoswap                       ; -- c-addr u1 ud1              r: -- digit
        _rfrom                          ; -- c-addr u1 ud1 digit
        _swap                           ; -- c-addr u1 lo digit hi
        _ basefetch                     ; -- c-addr u1 lo digit hi base
        _ umstar                        ; -- c-addr u1 lo digit ud
        _drop                           ; -- c-addr u1 lo digit u
        _ rot
        _ basefetch
        _ umstar
        _ dplus
        _ twoswap
        _lit 1
        _slashstring
        _repeat .1
        next
endcode

; ### missing
code missing, 'missing'                 ; $addr --
        _count
        _ copy_to_string
        _quote " ?"
        _ concat
        _to msg
        _lit -13                        ; "undefined word" Forth 2012 Table 9.1
        _ throw
        next
endcode

; ### double?
value double?, 'double?', 0

; ### negative?
value negative?, 'negative?', 0

; ### number?
code number?, 'number?'                 ; c-addr u -- d flag
        _clear double?
        _over
        _cfetch
        _lit '-'
        _equal
        _if .1
        _lit -1
        _to negative?
        _lit 1
        _slashstring
        _else .1
        _clear negative?
        _then .1
        _zero
        _zero
        _ twoswap
        _ tonumber                      ; -- ud c-addr' u'
        _dup                            ; -- ud c-addr' u' u'
        _zeq_if .2                      ; -- ud c-addr' u'
        ; no chars left over
        _2drop
        _true
        _return
        _then .2
        ; one or more chars left over
        _lit 1
        _notequal
        _if .3                          ; -- ud c-addr'
        _drop
        _false
        _return
        _then .3
        _cfetch                         ; -- ud char
        _lit '.'
        _equal
        _if .4
        _lit -1
        _to double?
        _true
        _else .4
        _false
        _then .4
        next
endcode

; ### maybe-change-base
code maybe_change_base, 'maybe-change-base'     ; c-addr1 u1 -- c-addr2 u2
        test    rbx, rbx
        jnz     .1
        ret
.1:
        _ over                          ; -- c-addr1 u1 c-addr1
        _cfetch                         ; -- c-addr1 u1 char

        cmp     bl, '$'
        jne     .2
        _ hex
        jmp     .5
.2:
        cmp     bl, '%'
        jne     .3
        _ binary
        jmp     .5
.3:
        cmp     bl, '#'
        jne     .4
        _ decimal
        jmp     .5
.4:
        _drop
        ret
.5:
        mov     ebx, 1
        _slashstring
        next
endcode

; ### number
code number, 'number'                   ; $addr -- d
; not in standard
        _duptor                         ; -- $addr              r: -- $addr
        _ count                         ; -- c-addr1 u1
        _ basefetch
        _tor
        _ maybe_change_base             ; -- c-addr2 u2
        _ number?                       ; -- d flag
        _rfrom
        _ basestore
        _zeq_if .1
        _rfrom
        _ missing                       ; doesn't return
        _then .1
        _rdrop
        _ negative?
        _if .2
        _ dnegate
        _then .2
        next
endcode
