\ Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

feline!

: do-check ( flag addr -- )
    0 local message
    swap
    if
        drop
    else
        "check failed" string>sbuf !> message
        2@ ?dup if
            message bl sbuf-append-char
            message swap count sbuf-append-chars
            message " line " sbuf-append-string
            message swap (.) sbuf-append-chars
        else
            drop
        then
        message sbuf>string to msg
        -256 throw
    then
;

: check ( -- )
    here
    source-filename ,
    source-line# ,
    postpone literal
    postpone do-check
; immediate

: check-false ( -- )
    postpone 0=
    postpone check
; immediate
