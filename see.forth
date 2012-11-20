\ Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

\ This program is free software: you can redistribute it and/or modify
\ it under the terms of the GNU General Public License as published by
\ the Free Software Foundation, either version 3 of the License, or
\ (at your option) any later version.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
\ GNU General Public License for more details.

\ You should have received a copy of the GNU General Public License
\ along with this program.  If not, see <http://www.gnu.org/licenses/>.

variable ip
variable prefix
variable opcode
variable modrm-byte
variable done?
variable literal?

: .2  ( ub -- )
    0 <# # # #> type ;

: .3  ( ub -- )
    0 <# # # # #> type ;

: modrm-mod  ( modrm-byte -- mod )
    [ binary ] 11000000 and
    [ decimal ] 6 rshift
;

: modrm-reg  ( modrm-byte -- reg )
    [ binary ] 00111000 and
    [ decimal ] 3 rshift
;

: modrm-rm  ( modrm-byte -- rm )
    [ binary ] 00000111 and
    [ decimal ]
;

: .modrm  ( modrm-byte -- )
    base @ >r binary
    ?cr
    ." mod: " dup modrm-mod .2 space
    cr ." reg: " dup modrm-reg .3 space
    cr ."  rm: " modrm-rm .3 space
    r> base !
;

: .reg64  ( +n -- )
    s" raxrcxrdxrbxrsprbprsirdi"        ( +n addr len )
    drop                                ( +n addr )
    swap                                ( addr +n )
    3 * + 3 type
;

decimal

create handlers  256 cells allot  handlers 256 cells 0 fill

: handler  ( opcode -- handler )
    cells handlers + @
;

: >pos  ( +n -- )
    #out @ - 1 max spaces ;

: .bytes ( u -- )
    base @ >r
    hex
    ?dup if 0 do ip @ i + c@ .2 space loop then
    r> base !
\     40 #out @ - 1 max spaces
    40 >pos
;

: unsupported  ( -- )
    ." unsupported opcode " opcode @ h.
\     done? on
;

: .name ( code-addr -- )
    find-code ?dup if
\         [ decimal ] 64 #out @ - 1 max spaces
        64 >pos
        count type
    then ;

: .ip  ( -- )
    ?cr ip @ h.
;

: .literal  ( -- )
    .ip
    8 .bytes
    64 >pos
    ." $"
    ip @ @ h.
    8 ip +!
;

: .call  ( -- )
\     5 0 do ip @ i + c@ .2 space loop
\     40 #out @ - spaces
    5 .bytes
    ." call"
    48 >pos
    ip @ 1+ sl@           \ signed 32-bit displacement
    ip @ 5 + + dup h.
\     find-code ?dup if count type then
    dup >r
    .name
    5 ip +!
    r@ ['] (lit) >code = if
        .literal
    then
    r@ ['] (do) >code = if
        .literal
    then
    r@ ['] (?do) >code = if
        .literal
    then
    r@ ['] (loop) >code = if
        .literal
    then
    r> drop
    ;

: .jmp  ( -- )
    5 .bytes
    ." jmp"
    48 >pos
    ip @ 1+ sl@           \ signed 32-bit displacement
    ip @ 5 + + dup h.
\     find-code ?dup if count type then
    .name
    5 ip +! ;

: .pop  ( -- )
    1 .bytes
    ." pop"
    48 >pos
    opcode @ [ hex ] 58 [ decimal ] - .reg64
    1 ip +!
;

: .ret  ( -- )
\     ip @ c@ .2 space
\     40 #out @ - spaces
    1 .bytes
    ." ret"
    1 ip +!
    done? on ;

: .85  ( -- )
    ip @ prefix @ if 2 else 1 then + c@         \ modrm-byte
    dup modrm-mod 3 = if                        \ register operands
        dup modrm-reg 0= if
            prefix @ if 3 else 2 then .bytes
            ." test"
            48 >pos
            dup modrm-reg .reg64 ." , " modrm-rm .reg64
            prefix @ if 3 else 2 then ip +!
            exit
        then
    then
    1 .bytes
    unsupported
    1 ip +!
    ;

: .89  ( -- )
    ip @ prefix @ if 2 else 1 then + c@         \ modrm-byte
    dup modrm-mod 3 = if
        prefix @ if 3 else 2 then .bytes
        ." mov "

    then
;

: modrm-byte  ( -- )
    ip @ prefix @ if 2 else 1 then + c@ ;

: .8b  ( -- )
\     cr ." .8b called" cr
\     ip @ prefix @ if 2 else 1 then + c@         \ modrm-byte
    modrm-byte
\     dup cr ." modrm-byte = " h. cr
\     dup modrm-mod 3 = if                        \ register operands
\         dup modrm-reg 0= if
\             prefix @ if 3 else 2 then .bytes
\             ." mov"
\             48 >pos
\             dup modrm-reg .reg64 ." , " modrm-rm .reg64
\             prefix @ if 3 else 2 then ip +!
\             exit
\         then
\     then
    dup modrm-mod 1 = if                \ 1-byte displacement
        prefix @ if 3 else 2 then .bytes
        ." mov" 48 >pos
        dup modrm-reg .reg64 ." , "
        ." [" modrm-rm .reg64
        ip @ prefix @ if 3 else 2 then + c@
        ?dup if ."  + " .2 then ." ]"
        prefix @ if 4 else 3 then ip +!
        exit
    then
    drop
    1 .bytes
    unsupported
    1 ip +!
    ;

: install-handler  ( xt opcode -- )
    cells handlers + !
;

hex
' .call e8 install-handler
' .jmp  e9 install-handler
' .ret  c3 install-handler
' .pop  58 install-handler
' .pop  59 install-handler
' .pop  5a install-handler
' .pop  5b install-handler
' .pop  5d install-handler
' .85   85 install-handler
\ ' .89   handlers 89 cells + !
' .8b   8b install-handler
decimal

: .opcode  ( -- )
    opcode @ handler ?dup
    if
        execute
    else
        prefix @ if 2 else 1 then .bytes
        unsupported
        prefix @ if 2 else 1 then ip +!
    then
;

: decode  ( -- )  ( decode one instruction )
    ip @ c@
    dup [ hex ] 48 [ decimal ] = if
        prefix !
        ip @ 1+ c@ opcode !
    else
        opcode !
        prefix off
    then
\    cr ." decode " opcode @ h.
    .ip
    .opcode
;

: disasm  ( code-addr -- )
    ip !
    done? off
    begin
        done? @ 0=
    while
        decode
    repeat ;

: disassemble  ( cfa -- )
    >code disasm ;

: see  ( -- )
    ' disassemble ;
