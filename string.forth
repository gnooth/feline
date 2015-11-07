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

: string-ensure-capacity ( string n -- )
    local new
    local s
    s string-capacity local old
    0 local old-data
    0 local new-data
    new old > if
        \ at least double current capacity
        new old 2* max to new
        [log ." string-ensure-capacity " old . ." -> " new . log]
        new 1+ ( terminal null byte ) chars -allocate to new-data
        new-data new 1+ chars erase
        \ copy existing data
        s string-data dup to old-data
        new-data s string-length cmove
        \ point existing string at new data
        new-data s string-data!
        \ free old storage
        old-data -free
        \ update capacity slot of existing vector
        new s string-capacity!
    then
;

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

: string-set-nth ( char n string -- )
    2dup string-length < if
        string-data + c!
    else
        true abort" string-set-nth index out of range"
    then
;

: string-insert-nth ( char string n -- )
    local n
    local s
    local c
    s string-length s string-capacity > abort" string-insert-nth length > capacity"
    s dup string-length 1+ string-ensure-capacity
    s string-length s string-capacity < if
        s string-data n +
        dup 1+
        s string-length n - cmove>
        s string-length 1+ s string-length!
        c n s string-set-nth
    else
        true abort" string-insert-nth out of room"
    then
;

: string-delete-char ( string n -- )
    local n
    local s
    s string-length local len
    0 local src
    0 local dst
    n len < if
        s string-data n + 1+ to src
        src 1- to dst
        src dst len n - 1- cmove
        0 s string-data len 1- + c!
        len 1- s string-length!
    then
;

: string-set-length ( string n -- )
    local n
    local s
    n s string-length < if
        n s string-length!
    else
        \ REVIEW Java AbstractStringBuilder calls ensureCapacityInternal() and appends nulls
        n s string-length > abort" string-set-length new length exceed existing length"
    then
;

: string-substring ( string start end -- string )
    local end
    local start
    local s
    start 0< abort" substring start < 0"
    end s string-length > abort" substring end > string-length"
    start end > abort" substring start > end"
    s string-data start + end start - >string
;
