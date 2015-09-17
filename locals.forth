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

\ This is the reference implementation from Forth 200x Draft 14.5

12345 CONSTANT undefined-value

: match-or-end? ( c-addr1 u1 c-addr2 u2 -- f )
    2 PICK 0= >R COMPARE 0= R> OR ;

: scan-args
    \ 0 c-addr1 u1 -- c-addr1 u1 ... c-addrn un n c-addrn+1 un+1
    BEGIN
        2DUP S" |" match-or-end? 0= WHILE
        2DUP S" --" match-or-end? 0= WHILE
        2DUP S" :}" match-or-end? 0= WHILE
        ROT 1+ PARSE-NAME
   AGAIN THEN THEN THEN ;

: scan-locals
    \ n c-addr1 u1 -- c-addr1 u1 ... c-addrn un n c-addrn+1 un+1
    2DUP S" |" COMPARE 0= 0= IF
        EXIT
    THEN
    2DROP PARSE-NAME
    BEGIN
        2DUP S" --" match-or-end? 0= WHILE
        2DUP S" :}" match-or-end? 0= WHILE
        ROT 1+ PARSE-NAME
        POSTPONE undefined-value
    AGAIN THEN THEN ;

: scan-end ( c-addr1 u1 -- c-addr2 u2 )
    BEGIN
        2DUP S" :}" match-or-end? 0= WHILE
        2DROP PARSE-NAME
    REPEAT ;

: define-locals ( c-addr1 u1 ... c-addrn un n -- )
    0 ?DO
        (LOCAL)
    LOOP
    0 0 (LOCAL) ;

: {: ( -- )
    0 PARSE-NAME
    scan-args scan-locals scan-end
    2DROP define-locals
; IMMEDIATE
