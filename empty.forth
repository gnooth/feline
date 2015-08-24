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
0 value saved-voc-link

: trim ( wid -- )
    \ headers are in the code area
    saved-cp if
        dup>r
        begin
            @
            dup saved-cp u>
        while
            n>link
        repeat
        r> !
    then ;

: trim-vocs ( -- )
    voc-link @
    begin
        dup
        trim
        wid>link @ dup 0=
    until
    drop ;

\ save current system state to be restored by EMPTY
: empty! ( -- )
    here to saved-dp
    here-c to saved-cp
    last @ to saved-latest
    voc-link @ to saved-voc-link ;

\ restore state saved by EMPTY!
: empty ( -- )
    saved-dp if
        saved-dp dp !
        saved-cp cp !
        saved-latest last !
        saved-voc-link voc-link !
        trim-vocs
    then ;
