\ Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

\ Adapted from GForth.

: string-prefix? ( c-addr1 u1 c-addr2 u2 -- f ) \ gforth
    \ Is the second string a prefix of the first?
    tuck 2>r min 2r> str= ;

: search  ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 flag )
\ STRING
    2>r 2dup
    begin
	dup r@ >=
    while
	2dup 2r@ string-prefix? if
	    2swap 2drop 2r> 2drop true exit
        then
	1 /string
    repeat
    2drop 2r> 2drop false ;
