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

decimal

: defer   ( "<spaces>name" -- )
   \ Forth 200x CORE EXT
   header
   align
   here-c latest name> !
   here
   ['] abort >code ,
   $48 c,c $b8 c,c ,c   \ mov rax, addr
   $ff c,c $20 c,c      \ jmp [rax]
   $c3 c,c              \ ret
   ;

: defer!  ( xt2 xt1 -- )
   \ Forth 200x CORE EXT
   \ "Set the word xt1 to execute xt2."
   >code 2+ @ swap >code swap ! ;

: is
   \ Forth 200x CORE EXT
   state @ if
      postpone ['] postpone defer!
   else
      ' defer!
   then ; immediate
