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

0 [if]

\ slot 0 is the object header (see object.forth)

\ slot 1
: vector-length ( vector -- length )
    cell+ @
;

: vector-length! ( length vector -- )
    cell+ !
;

\ slot 2
: vector-data ( vector -- data-address )
    2 cells + @
;

: vector-data! ( data-address vector -- )
    2 cells + !
;

\ slot 3
: vector-capacity ( vector -- capacity )
    3 cells + @
;

: vector-capacity! ( capacity vector -- )
    3 cells + !
;

[then]

4 cells constant VECTOR_SIZE            \ size in bytes of a vector object (without data)

0 [if]

\ constructor
: <vector> ( capacity -- vector )
    local capacity
    VECTOR_SIZE -allocate local v
    v VECTOR_SIZE erase
    VECTOR_TYPE v object-header!
    capacity cells -allocate v vector-data!
    capacity v vector-capacity!
\     0 v vector-length!
    v
;

[then]

\ destructor
: ~vector ( vector -- )
    ?dup if
        dup vector-data -free
        -free
    then
;

: vector-ensure-capacity ( n vector -- )        \ n is number of elements (not bytes)
    local v
    local new-capacity
    v vector-capacity local old-capacity
    0 local new-data
    new-capacity old-capacity > if
        \ at least double current capacity
        new-capacity old-capacity 2* max to new-capacity

        \ resize data area
        v vector-data new-capacity cells resize throw to new-data

        \ point existing vector at new data
        new-data v vector-data!

        \ update capacity slot
        new-capacity v vector-capacity!
    then
;

: vector-nth ( n vector -- elt )
    2dup vector-length < if
        vector-data                     \ -- n vector-data
        swap cells + @
    else
        true abort" vector-nth index out of range"
    then
;

: vector-set-nth ( elt n vector -- )
    2dup vector-length < if
        vector-data
        swap cells + !
    else
        true abort" vector-set-nth index out of range"
    then
;

: vector-insert-nth ( elt n vector -- )
    local v
    local n
    local elt

    \ this should never happen!
    v vector-length v vector-capacity > abort" VECTOR-INSERT-NTH length > capacity"
    n v vector-length > abort" VECTOR-INSERT-NTH n > length"
    v vector-length 1+ v vector-ensure-capacity
    v vector-length v vector-capacity < if
        v vector-data n cells +
        dup cell+
        v vector-length n - cells cmove>
        v vector-length 1+ v vector-length!
        elt n v vector-set-nth
    else
        true abort" VECTOR-INSERT-NTH out of room"
    then
;

: vector-remove-nth ( n vector -- )
    local v
    local n

    \ this should never happen!
    v vector-length v vector-capacity > abort" VECTOR-REMOVE-NTH length > capacity"
    n v vector-length 1- > abort" VECTOR-REMOVE-NTH n > length - 1"
    n 0< abort" VECTOR-REMOVE-NTH n < 0"
    v vector-data n 1+ cells +
    dup cell-
    v vector-length 1- cells cmove
    0 v vector-data v vector-length 1- cells + !
    v vector-length 1- v vector-length!
;

: vector-push ( elt vector -- )
    local v
    local elt

    v vector-length v vector-capacity > abort" VECTOR-PUSH length > capacity"
    v vector-length 1+ v vector-ensure-capacity
    v vector-length v vector-capacity < if
        v vector-length 1+ v vector-length!
        elt v dup vector-length 1- swap vector-set-nth
    else
        true abort" VECTOR-PUSH out of room"
    then
;

: vector-each ( xt vector -- )
    local v
    local xt

    v vector-length 0 ?do
        i v vector-nth
        xt execute
    loop
;
