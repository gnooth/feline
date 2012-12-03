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

: case  ( -- 0 )  0 ; immediate

: of
   1+ >r
   postpone over
   postpone =
   postpone if
   postpone drop
   r> ; immediate

: endof
   >r
   postpone else
   r> ; immediate

: endcase
   postpone drop
   0 ?do
      postpone then
   loop ; immediate
