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

: case ( -- 0 )
    flush-compilation-queue
    0
; immediate

: of
    flush-compilation-queue
    1+ >r
    postpone over
    postpone =
    postpone if
    postpone drop
    r>
; immediate

: endof
    flush-compilation-queue
    >r
    postpone else
    r>
; immediate

: endcase
    flush-compilation-queue
    postpone drop
    0 ?do
        postpone then
    loop
; immediate
