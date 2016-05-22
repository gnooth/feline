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

LANGUAGE: forth

CONTEXT: forth ;
CURRENT: forth

: [else]  ( -- )
   1                                    \ -- level
   begin
      begin
         parse-name dup
      while                             \ -- level addr len
         2dup s" [if]" istr= if         \ -- level addr len
            2drop 1+                    \ -- level?
         else                           \ -- level addr len
            2dup s" [else]" istr= if    \ -- level addr len
               2drop 1- dup if 1+ then  \ level?
            else                        \ level addr len
               s" [then]" istr= if      \ level
                  1-                    \ level?
               then
            then
         then
         ?dup 0= if exit then
      repeat
      2drop                             \ level
      refill 0=
   until                                \ level
   drop
; immediate

: [if]  ( flag -- )
   0= if postpone [else] then
; immediate

: [then]  ( -- )  ; immediate

: [defined]  ( "<name>" -- flag )
   have ; immediate

: [undefined]  ( "<name>" -- flag)
   have 0= ; immediate
