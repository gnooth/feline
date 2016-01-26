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

\ DOUBLE gforth
: m*/ ( d1 n2 +n2 -- d2 )
    >r s>d >r abs -rot
    s>d r> xor r> swap >r >r dabs rot tuck um* 2swap um*
    swap >r 0 d+ r> -rot r@ um/mod -rot r> um/mod
    [ 1 -3 mod 0< ] [if]
        -rot r> if if 1. d+ then dnegate else drop then
    [else]
        nip swap r> if dnegate then
    [then] ;

\ DOUBLE EXT gforth
: 2rot ( x1 x2 x3 x4 x5 x6 -- x3 x4 x5 x6 x1 x2 )
    >r >r 2swap r> r> 2swap ;
