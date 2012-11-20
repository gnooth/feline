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

: dump-line  ( addr len -- addr' len')
   over                                 \ -- addr len addr
   12 u.r  2 spaces                     \ -- addr len
   2dup                                 \ -- addr len addr len
   16 min bounds do                     \ -- addr len
      i c@ .2 space
   loop
   63 >pos
   2dup                                 \ -- addr len addr len
   16 min bounds do
      i c@ dup bl 128 within if emit else drop [char] . emit then
   loop
   cr                                   \ -- addr len
   dup 16 min /string                   \ -- addr+16 len-16
;

: dump  ( addr len -- )
\ TOOLS
   base @ >r hex
   ?cr
   14 spaces
   over 16 bounds do i 15 and 2 .r space loop cr        \ -- addr len
   begin
      dump-line
      dup 0 <=
   until
   2drop
   r> base ! ;
