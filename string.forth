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

only forth also definitions

\ slot 0 is the object header (see object.forth)

\ slot 1
: string-length ( string -- length )
    cell+ @
;

: string-length! ( length string -- )
    cell+ !
;

\ slot 2
: string-data ( string -- data-address )
    2 cells + @
;

: string-data! ( data-address string -- )
    2 cells + !
;

\ slot 3
: string-capacity ( string -- capacity )
    3 cells + @
;

: string-capacity! ( capacity string -- )
    3 cells + !
;

4 cells constant STRING_SIZE            \ size in bytes of a string object (without data)

: >string ( c-addr u -- string )
\ construct a string object from a Forth string descriptor
    local u
    local c-addr
    STRING_SIZE -allocate local s
    s STRING_SIZE erase
    STRING_TYPE s object-header!
    u 1+ ( terminal null byte ) -allocate s string-data!
    u s string-length!
    u s string-capacity!
    c-addr s string-data u cmove
    0 s string-data u + c!              \ terminal null byte
    s                                   \ return address of string object
;

: string> ( string -- c-addr u )
    local s
    s string-data
    s string-length
;

\ destructor
: ~string ( string -- )
    ?dup if
        dup string-data -free
        -free
    then
;
