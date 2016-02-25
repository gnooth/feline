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

: locate ( <spaces>name -- )
    ' >view 2@ ?dup if
        .string space .
    else drop then ;

\ : edit ( <spaces>name -- )
\     ' >view 2@ ?dup if
\         swap                    \ -- $addr n
\         $" j +"
\         swap (.) >temp$ $+
\         $"  " $+
\         swap $+
\         count system
\     else drop then ;

0 value build-string

: initialize-build-string ( -- )
    0 local fileid
    0 local buffer
    0 local length

    feline-home "build" path-append string>
    r/o open-file                       \ -- fileid ior
    if
        drop exit
    then                                \ -- fileid
    to fileid
    256 allocate                        \ -- addr ior
    0= if
        to buffer
        buffer 256 fileid read-file     \ -- length ior
        0= if
            to length
            begin
                length 0>
                buffer length 1- + c@ bl < and
            while
                -1 +to length
            repeat
            length 0> if
                \ valid string, save it
                buffer length >simple-string
            else
                \ don't try again!
                -1
            then
            to build-string
        then
        buffer -free
    then
    fileid close-file                   \ -- ior
    drop
;

: .build-impl ( -- )
    build-string 0= if
        initialize-build-string
    then
    build-string -1 <> if ." built " build-string .string then ;

' .build-impl is .build
