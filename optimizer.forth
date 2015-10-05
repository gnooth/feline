\ Copyright (C) 2015 Peter Graves <gnooth@gmail.com>

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

: compile-dup ( xt -- )
    local xt
\     ?cr ." compile-dup xt = $" xt h.

\     ?cr ." compile-dup cq-second = $" cq-second h.

    cq-flush-literals

    cq-second ['] + = if
        ['] 2* inline-or-call-xt
        2 +to cq-index
        ?cr ." dup + -> 2* "
        exit
    then

    xt inline-or-call-xt
    1 +to cq-index
;

' compile-dup ' dup >comp!

: compile-+ ( xt -- )
    local xt

    cq-#lits 1 = if
        cq-lit1 $ffffffff <= if
            $48 c,c
            $81 c,c
            $c3 c,c
            cq-lit1 l,c
        else
            $48 c,c
            $b8 c,c
            cq-lit1 ,c                  \ mov rax, literal
            $48 c,c
            $01 c,c
            $c3 c,c                     \ add rbx, rax
        then
        ?cr ." lit + -> add rbx, lit "
        0 to cq-#lits
        1 +to cq-index
        exit
    then

    cq-flush-literals

    cq-second ['] dup = if
        ['] +dup copy-code
        2 +to cq-index
        cr ." + dup -> +dup "
        exit
    then

    xt inline-or-call-xt
    1 +to cq-index
;

' compile-+ ' + >comp!

: compile-over ( xt -- )
    local xt

    cq-flush-literals

    cq-second ['] + = if
        ['] over+ inline-or-call-xt
        2 +to cq-index
        ?cr ." over + -> over+ "
        exit
    then

    xt inline-or-call-xt
    1 +to cq-index
;

' compile-over ' over >comp !

: compile-inline-i ( xt -- )
    local xt

    cq-flush-literals

    cq-second ['] + = if
        ['] inline-i+ copy-code
        2 +to cq-index
        ?cr ." i + -> i+ "
        exit
    then

    xt copy-code
    1 +to cq-index
;

' compile-inline-i ' inline-i >comp !

: compile->r ( xt -- )
    drop
    cq-flush-literals
    $53 c,c                             \ push rbx
    pop-tos,
    1 +to cq-index
;

' compile->r ' >r >comp !

: compile-r> ( xt -- )
    drop
    cq-flush-literals
    push-tos,
    $5b c,c                             \ pop rbx
    1 +to cq-index
;

' compile-r> ' r> >comp!
