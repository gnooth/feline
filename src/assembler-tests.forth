\ Copyright (C) 2015-2016 Peter Graves <gnooth@gmail.com>

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

only forth also assembler definitions

warning off

: >temp$ ( byte1 byte2 ... byten n -- $addr )
    \ Gather n bytes from the stack and make them into a counted string in
    \ the transient string area. Return the address of the transient string.
    local count
    temp$ local buf
    count buf c!
    count 0 ?do
        count i - buf + c!
    loop
    buf
;

0 value starting-depth

: } ( x1 x2 ... xn -- x1 x2 ... xn n )
    depth starting-depth -
;

: { ( -- )
    depth to starting-depth
;

0 value expected

0 value actual

0 value #errors

: asm ( c-addr u -- $addr )
    reset-assembler
    also assembler
    here-c to actual
    evaluate
    previous
;

: ok? ( c-addr u byte1 ... byten n -- )
    >temp$ to expected                  \ -- c-addr u
    cr 2dup type
    asm
    expected count actual swap mem= 0= if
        ?cr
        red foreground
        ." Error: expected " expected count dump-bytes cr
        ."          actual " actual here-c over - dump-bytes
        white foreground
        1 +to #errors
    then
;

: report-errors ( -- )
    ?cr #errors .
    ." error"
    #errors 1 <> if ." s" then
;

0 to #errors

true to testing?

s" rax -> rbx mov,"             { $48 $89 $c3 } ok?
s" rbx -> rax mov,"             { $48 $89 $d8 } ok?
s" rbx -> [rsp] mov,"           { $48 $89 $1c $24 } ok?
s" rbx -> [rbp -8 +] mov,"      { $48 $89 $5d $f8 } ok?
s" rbx -> [rsp  8 +] mov,"      { $48 $89 $5c $24 $08 } ok?
s" [rbp -8 +] -> rbp lea,"      { $48 $8d $6d $f8 } ok?
s" 42 # -> rax add,"            { $48 $83 $C0 $2A } ok?

false to testing?

report-errors
