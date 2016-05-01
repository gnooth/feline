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

CONTEXT: forth feline ;
CURRENT: forth

0 value empty-dp
0 value empty-cp
0 value empty-latest
0 value empty-voclink
0 value empty-current

0 global empty-search-order

: get-search-order ( -- vector )
    context-vector vector-clone
;

: set-search-order ( vector -- )
    to context-vector
;

: trim ( wid -- )
    \ headers are in the data area
    \ must be called *after* dp is restored
    dup>r
    begin
        @
        dup dp @ u>
    while
        name>link
    repeat
    r> ! ;

: trim-vocs ( -- )
    \ must be called *after* dp and voclink are restored
    voclink @
    begin
        dup
        trim
        wid>link @ dup 0=
    until
    drop ;

0 value new-gc-roots

: maybe-copy-root ( root -- )
    dup here limit within if
        drop
    else
        new-gc-roots vector-push
    then ;

: trim-gc-roots ( -- )
    \ must be called *after* dp is restored
    gc-roots vector-length <vector> to new-gc-roots
    gc-roots ['] maybe-copy-root vector-each
    new-gc-roots to gc-roots
    0 to new-gc-roots
;

\ save current system state to be restored by EMPTY
: empty! ( -- )
    here to empty-dp
    here-c to empty-cp
    last @ to empty-latest
    voclink @ to empty-voclink
    get-current to empty-current
    get-search-order !> empty-search-order
;

\ restore state saved by EMPTY!
: empty ( -- )
    empty-dp if
        empty-dp dp !
        empty-cp cp !
        empty-latest last !
        empty-voclink voclink !
        empty-current set-current
        empty-search-order set-search-order
        trim-vocs
        trim-gc-roots
        here limit over - erase
        here-c limit-c over - erase
    then ;

\ CORE EXT
: marker ( "<spaces>name" -- )
    here                                \ -- here
    dup ,                               \ save here
    here-c ,                            \ save here-c
    latest ,                            \ save latest
    voclink @ ,                         \ save voclink
    get-current ,                       \ save current

    here gc-add-root
    get-search-order ,

    create ,
    does>
        @                               \ -- addr
        @+ dp !                         \ -- addr
        @+ cp !                         \ -- addr
        @+ last !                       \ -- addr
        @+ voclink !                    \ -- addr
        @+ set-current                  \ -- addr
        @ set-search-order              \ --
        trim-vocs
        trim-gc-roots
        here limit over - erase

\ FIXME The following line causes a crash in the Forth 2012 test suite MARKER tests.
\         here-c limit-c over - erase
;
