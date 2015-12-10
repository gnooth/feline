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

0 value saved-dp
0 value saved-cp
0 value saved-latest
0 value saved-voclink

: trim ( wid -- )
    \ headers are in the data area
    \ must be called *after* dp is restored
    dup>r
    begin
        @
        dup dp @ u>
    while
        n>link
    repeat
    r> !
;

: trim-vocs ( -- )
    \ must be called *after* dp and voclink are restored
    voclink @
    begin
        dup
        trim
        wid>link @ dup 0=
    until
    drop
;

\ save current system state to be restored by EMPTY
: empty! ( -- )
    here to saved-dp
    here-c to saved-cp
    last @ to saved-latest
    voclink @ to saved-voclink
;

\ restore state saved by EMPTY!
: empty ( -- )
    saved-dp if
        saved-dp dp !
        saved-cp cp !
        saved-latest last !
        saved-voclink voclink !
        trim-vocs
    then
;

: save-search-order ( -- addr )
    here
    #vocs cells allot
    context swap #vocs cells cmove
;

: restore-search-order ( addr -- )
    context #vocs cells 2dup erase cmove
;

\ CORE EXT
: marker ( "<spaces>name" -- )
    here                                \ -- here
    dup ,                               \ save here
    here-c ,                            \ save here-c
    latest ,                            \ save latest
    voclink @ ,                         \ save voclink
    save-search-order                   \ -- here
    create ,
    does>
        @
        @+ dp !
        @+ cp !
        @+ last !
        @+ voclink !
        trim-vocs
        restore-search-order
;
