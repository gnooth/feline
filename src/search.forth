\ Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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

: search ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 flag )
\ STRING
    local pattern-length
    local pattern                       \ -- c-addr1 u1

    pattern-length 0= if true exit then

    local string-length
    local string                        \ --

    string        local string-remaining
    string-length local string-length-remaining
    pattern c@    local first-char

    begin
        string-remaining string-length-remaining first-char scan \ -- addr len
        to string-length-remaining to string-remaining
        string-length-remaining pattern-length < if
            string string-length false exit
        then
        \ string-length-remaining >= pattern-length
        string-remaining pattern pattern-length mem= if
            string-remaining string-length-remaining true exit
        then
        1 +to string-remaining -1 +to string-length-remaining
    again ;

\ Following adapted from gforth
: string-prefix?-ignore-case ( c-addr1 u1 c-addr2 u2 -- f )
    tuck 2>r min 2r> istr= ;

: search-ignore-case ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 flag )
    2>r 2dup
    begin
	dup r@ >=
    while
	2dup 2r@ string-prefix?-ignore-case if
	    2swap 2drop 2r> 2drop true exit
        then
	1 /string
    repeat
    2drop 2r> 2drop false ;
