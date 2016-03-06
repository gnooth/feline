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

forth!

[defined] hidden 0= [if] vocabulary hidden [then]

hidden definitions

0 value buffer

0 value bufsize

0 value dot                             \ offset in buffer

: dot-char ( -- c )
    buffer dot + c@
;

: skip-line ( -- )
    begin
        dot bufsize u<
        dot-char $0a <> and
    while
        1 +to dot
    repeat
    1 +to dot
;

: skip-lines ( n -- )
    0 ?do
        skip-line
    loop
;

: looking-at ( string -- flag )
    check-string local s
    s string-length local len
    true local result
    dot len + bufsize <= if
        len 0 ?do
            buffer dot + i + c@
            s i string-char
            <> if
                false to result
                leave
            then
        loop
    else
        false to result
    then
    result
;

0 value termination

: set-termination
    0 to termination
    ": " looking-at if
        ";" to termination
    else
        "code " looking-at if
            "endcode" to termination
        else
            "inline " looking-at if
                "endinline" to termination
            then
        then
    then
;

: termination?
    termination if
        termination check-string looking-at
    else
        dot-char $0a =
    then
;

: finish-line ( -- )
    begin
        dot bufsize u<
    while
        dot-char $0a = if
            exit
        then
        dot-char emit
        1 +to dot
    repeat
;

: (view) ( xt -- )
    \ Locals:
    0 local fileid
    0 local filename
    0 local line#
    0 local filesize

    >view 2@ ?dup if
        to filename
        to line#
    else
        drop
        exit
    then

    filename count r/o open-file throw to fileid
    fileid file-size throw drop to filesize
    filesize -allocate to buffer
    buffer filesize fileid read-file throw to bufsize
    fileid close-file throw

    0 to dot

    line# 1- skip-lines

    set-termination

    cr
    begin
        dot bufsize u<
        termination? 0= and
    while
        dot-char emit
        1 +to dot
    repeat

    finish-line
    buffer -free
    ?cr filename $. ."  line " line# u.
;

also forth definitions

: view ( "<spaces>name" -- )
    ' (view)
;

forth!
