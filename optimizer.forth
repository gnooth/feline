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
    ?cr ." compile-dup xt = $" xt h.

    ?cr ." compile-dup cq-second = $" cq-second h.

    cq-second ['] + = if
        ['] 2* inline-or-call-xt
        2 +to cq-index
        exit
    then

    xt inline-or-call-xt
    1 +to cq-index
;

' compile-dup ' dup >comp!

: compile-+ ( xt -- )
    local xt

    cq-second ['] dup = if
        ['] +dup copy-code
        2 +to cq-index
        cr ." + dup => +dup"
        exit
    then

    xt inline-or-call-xt
    1 +to cq-index
;

' compile-+ ' + >comp!

: compile-over ( xt -- )
    local xt
    cq-second ['] + = if
        ['] over+ inline-or-call-xt
        2 +to cq-index
        exit
    then

    xt inline-or-call-xt
    1 +to cq-index
;

' compile-over ' over >comp !

: compile-inline-i ( xt -- )
    local xt
    cq-second ['] + = if
        ['] inline-i+ copy-code
        2 +to cq-index
        exit
    then

    xt copy-code
    1 +to cq-index
;

' compile-inline-i ' inline-i >comp !
