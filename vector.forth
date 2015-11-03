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

4 cells constant VECTOR_SIZE            \ size in bytes of a vector object (without data)

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

\ destructor
: ~vector ( vector -- )
    ?dup if
        dup vector-data -free
        -free
    then
;

: vector-ensure-capacity ( vector n -- ) \ n is number of elements (not bytes)
    local new
    local v
    v vector-capacity local old
    0 local old-data
    0 local new-data
    new old > if
        \ at least double current capacity
        new old 2* max to new
        [log ." vector-ensure-capacity " old . ." -> " new . log]
        new cells -allocate to new-data
        new-data new cells erase
        \ copy existing data
        v vector-data dup to old-data
        new-data v vector-length cells cmove
        \ point existing vector at new data
        new-data v vector-data!
        \ free old storage
        old-data -free
        \ update capacity slot of existing vector
        new v vector-capacity!
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

: vector-push ( elt vector -- )
    local v
    local elt
\     v vector-length
\     v vector-capacity 1- < if
\         v vector-length 1+ v vector-length!
\         elt v dup vector-length 1- swap vector-set-nth
\     else
\         true abort" vector-push out of room"
\     then
    v vector-length v vector-capacity > abort" vector-push length > capacity"
    v dup vector-length 1+ vector-ensure-capacity
    v vector-length v vector-capacity < if
        v vector-length 1+ v vector-length!
        elt v dup vector-length 1- swap vector-set-nth
    else
        true abort" vector-push out of room"
    then
;
