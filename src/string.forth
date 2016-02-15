\ Copyright (C) 2015-2016 Peter Graves <gnooth@gmail.com>

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

\ typedef struct string
\ {
\   Cell object_header;
\   Cell length;
\   char * data_address;
\   Cell capacity;
\ } STRING;

\ slot 0 is the object header (see object.forth)

0 [if]
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
[then]

4 cells constant STRING_SIZE            \ size in bytes of a string object (without data)

0 [if]
: string-ensure-capacity ( n string -- )
    local s
    local new-capacity
    s string-capacity local old-capacity
    0 local old-data
    0 local new-data
    new-capacity old-capacity > if
        \ at least double current capacity
        new-capacity old-capacity 2* max to new-capacity
        new-capacity 1+ ( terminal null byte ) chars -allocate to new-data
        new-data new-capacity 1+ chars erase
        \ copy existing data
        s string-data dup to old-data
        new-data s string-length cmove
        \ point existing string at new data
        new-data s string-data!
        \ free old storage
        old-data -free
        \ update capacity slot of existing vector
        new-capacity s string-capacity!
    then
;
[then]

\ constructor
: <string> ( capacity -- string )
    local capacity
    STRING_SIZE -allocate local s
    s STRING_SIZE erase
    OBJECT_TYPE_STRING s object-header!
    capacity chars -allocate s string-data!
    capacity s string-capacity!
    s
;

0 [if]
: >string ( c-addr u -- string )
\ construct a string object from a Forth string descriptor
    local u
    local c-addr
    STRING_SIZE -allocate local s
    s STRING_SIZE erase
    OBJECT_TYPE_STRING s object-header!
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
[then]

: string-clone ( string1 -- string2 )
    local s1
    s1 string-length local len
    STRING_SIZE -allocate local s2
    s2 STRING_SIZE erase
    OBJECT_TYPE_STRING s2 object-header!
    len 1+ ( terminal null byte ) -allocate s2 string-data!
    len s2 string-length!
    len s2 string-capacity!
    s1 string-data s2 string-data len cmove
    0 s2 string-data len + c!           \ terminal null byte
    s2                                  \ return address of string object
;

0 [if]
\ destructor
: ~string ( string -- )
    ?dup if
        dup string-data -free
        -free
    then
;
[then]

: string-set-nth ( char n string -- )
    2dup string-length < if
        string-data + c!
    else
        true abort" string-set-nth index out of range"
    then
;

: string-insert-nth ( char n string -- )
    local s
    local n
    local c
    s string-length s string-capacity > abort" STRING-INSERT-NTH length > capacity"
    s string-length 1+ s string-ensure-capacity
    s string-length s string-capacity < if
        s string-data n +
        dup 1+
        s string-length n - cmove>
        s string-length 1+ s string-length!
        c n s string-set-nth
    else
        true abort" STRING-INSERT-NTH out of room"
    then
;

: string-delete-char ( n string -- )
    local s
    local n
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

: string-set-length ( n string -- )
    local s
    local new-length
    new-length s string-length < if
        new-length s string-length!
        0 s string-data new-length + c!
    else
        \ REVIEW Java AbstractStringBuilder calls ensureCapacityInternal() and appends nulls
        new-length s string-length >
        abort" STRING-SET-LENGTH new length exceeds existing length"
    then
;

: string-substring ( start end string -- substring )
    local s
    local end
    local start
    start 0< abort" substring start < 0"
    end s string-length > abort" STRING-SUBSTRING end > string-length"
    start end > abort" substring start > end"
    s string-data start + end start - >string
;

: string-append-string ( string-to-be-appended string -- )
    local s
    local sappend
    s string-length sappend string-length + s string-ensure-capacity
    sappend string-data                 \ -- src
    s string-data s string-length +     \ -- src dest
    sappend string-length               \ -- src dest n
    cmove
    s string-length sappend string-length + s string-length!
;

0 [if]
: string-append-chars ( addr len string -- )
    local this
    local len
    local addr

    this string-length len + this string-ensure-capacity
    addr                                        \ -- src
    this string-data this string-length +       \ -- dest
    len                                         \ -- src dest len
    cmove
    this string-length len + this string-length!
    0 this string-data this string-length + c!
;
[then]

: string-append-char ( char string -- )
    local this
    local c
    this string-length local len
    len 1+ this string-ensure-capacity
    c this string-data len + c!
    len 1+ this string-length!
    0 this string-data len 1+ + c!
;
