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

decimal

: defer   ( "<spaces>name" -- )
   \ Forth 200x CORE EXT
   header
   here-c latest name> !
   ['] abort >code ,jmp
   $c3 c,c ;

: defer!  ( xt2 xt1 -- )
   \ Forth 200x CORE EXT
   \ "Set the word xt1 to execute xt2."
   cp @ >r
   >code cp !
   >code ,jmp
   r> cp ! ;

: is
   \ Forth 200x CORE EXT
   state @ if
      postpone ['] postpone defer!
   else
      ' defer!
   then ; immediate
