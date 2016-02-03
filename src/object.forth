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

only forth also definitions

\ REVIEW
1 constant VECTOR_TYPE
2 constant STRING_TYPE
3 constant SIMPLE_STRING_TYPE

0 [if]

: object-header ( object -- header )
    @
;

: object-header! ( header object -- )
    !
;

: vector? ( object -- flag )
    ?dup if
        object-header VECTOR_TYPE =
    else
        false
    then
;

: check-vector ( object -- vector )
    dup vector? 0= abort" not a vector"
;

: string? ( object -- flag )
    ?dup if
        object-header STRING_TYPE =
    else
        false
    then
;

: check-string ( object -- string )
    dup string? 0= abort" not a string"
;

[then]

\ include-system-file vector.forth
include-system-file string.forth
