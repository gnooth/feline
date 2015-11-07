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

[undefined] [log [if] include-system-file log.forth +log [then]

[undefined] <vector> [if] include-system-file object.forth [then]

[undefined] editor [if] vocabulary editor [then]

only forth also editor definitions

0 value filename

0 value lines                           \ a vector of strings

: #lines lines vector-length ;          \ number of lines in the file being edited

0 value top                             \ zero-based line number of top line of display

0 value cursor-x

0 value cursor-y

: cursor-line# ( -- n )                 \ zero-based index of current line in lines vector
    top cursor-y +
;

: cursor-line ( -- string )
    cursor-line# lines vector-nth
;

: cursor-line-length ( -- n )
    cursor-line string-length
;

: set-cursor ( x y -- )
    local y
    local x
    x to cursor-x
    y to cursor-y
    x y at-xy
;

: .cursor ( -- )
    cursor-x cursor-y at-xy
;

: .status-text ( string -- )
    dup string? if
        0 #rows at-xy
        string> type
    else
        drop
    then
;

: clear-status-text ( -- )
    0 #rows at-xy
    #cols 20 - spaces
;

: status ( c-addr u -- )
    >string local s
    s .status-text
    s ~string
;

: .status ( -- )
    #cols 20 - #rows at-xy
    ." Line " top cursor-y + 1+ .
    ." Col " cursor-x 1+ .
;

: clear-status ( -- )
    0 #rows at-xy
    #cols spaces
;

false value repaint?

: redisplay ( -- )
    repaint? if
        0 0 at-xy
        top
        #rows 1 -
        bounds ?do
            i #lines < if
                i lines vector-nth          \ -- string
                string>                     \ -- c-addr u
                dup>r
                #cols min type
                #cols r> - spaces
            else
                #cols spaces
            then
            cr \ needed for Windows
        loop
        0 to repaint?
    then
    .status
    .cursor
;

: /page ( -- n )
    #rows 2 -
;

0 value goal-x

: adjust-cursor-x ( -- )
    goal-x to cursor-x
    cursor-x cursor-line-length > if
        cursor-line-length to cursor-x
    then
;

: do-up ( -- )
    cursor-y 0> if
        cursor-x cursor-y 1- set-cursor
    else
        top 0> if
            -1 +to top
            true to repaint?
        then
    then
    adjust-cursor-x
;

: do-down ( -- )
    cursor-y /page < if
        cursor-x cursor-y 1+ set-cursor
    else
        top #lines < if
            1 +to top
            true to repaint?
        then
    then
    adjust-cursor-x
;

: do-left ( -- )
    cursor-x 0> if
        -1 +to cursor-x
        cursor-x to goal-x
    then
;

: do-right ( -- )
    cursor-x cursor-line-length < if
        cursor-x 1+ to cursor-x
        cursor-x to goal-x
    then
;

: do-home ( -- )
    cursor-x 0> if
        0 to cursor-x
        cursor-x to goal-x
    then
;

\ REVIEW what about lines too long to fit in the window?
: do-end ( -- )
    cursor-line-length local length
    cursor-x length < if
        length to cursor-x
        cursor-x to goal-x
    then
;

: do-page-down
    top /page + #lines < if
        /page +to top
        true to repaint?
    then
    adjust-cursor-x
;

: do-page-up
    /page negate +to top
    top 0< if
        0 to top
    then
    true to repaint?
    adjust-cursor-x
;

\ FIXME bad name
: do-^home ( -- )
    0 to top
    0 0 set-cursor
    0 to goal-x
    true to repaint?    \ not always necessary
;

\ FIXME bad name
: do-^end ( -- )
    lines vector-length 1- dup 0>= if
        to top
        0 to cursor-y
        cursor-line-length to cursor-x
        cursor-x to goal-x
        true to repaint?        \ not always necessary
    then
;

: do-delete ( -- )
    cursor-x cursor-line-length < if
        cursor-x cursor-line string-delete-char
        true to repaint?        \ FIXME repaint cursor line only
    then
;

: do-backspace ( -- )
    cursor-x 0> if
        do-left
        do-delete
    then
;

: do-normal-char ( char -- )
    cursor-x                            \ -- char index
    cursor-line                         \ -- char index string
    string-insert-nth
    1 +to cursor-x
    cursor-x to goal-x
    true to repaint?
;

: insert-line-separator ( -- )
    cursor-x cursor-line-length <= if
        cursor-x cursor-line-length cursor-line string-substring        \ -- string
        cursor-line# 1+ lines vector-insert-nth
        cursor-x cursor-line string-set-length
        1 +to cursor-y
        0 to cursor-x
        0 to goal-x
        true to repaint?
    then
;

: do-save ( -- )
    s" Saving..." status
    \ FIXME test.out
    s" test.out" w/o create-file throw local fileid
    #lines 0 ?do
        i lines vector-nth              \ -- string
        string>                         \ -- c-addr u
        fileid                          \ -- c-addr u fileid
        write-line                      \ -- ior
        -76 ?throw
    loop
    fileid close-file -62 ?throw
    s" Saving...done" status
;

false value quit?

: do-quit
    true to quit?
;

create keytable

k-up ,          ' do-up ,
k-down ,        ' do-down ,
k-left ,        ' do-left ,
k-right ,       ' do-right ,
k-home ,        ' do-home ,
k-end ,         ' do-end ,
k-prior ,       ' do-page-up ,
k-next ,        ' do-page-down ,
k-^home ,       ' do-^home ,
k-^end ,        ' do-^end ,
k-delete ,      ' do-delete ,
$08 ,           ' do-backspace ,                \ Windows c-h
$7f ,           ' do-backspace ,                \ Linux
$0a ,           ' insert-line-separator ,
$13 ,           ' do-save ,                     \ c-s
$11 ,           ' do-quit ,                     \ c-q
0 ,             ' drop ,

: do-command ( x -- )
    keytable switch ;

: edit-loop ( -- )
    0 to top
    0 0 set-cursor
    true to repaint?
    false to quit?
    begin
        redisplay
        ekey
        clear-status-text
        dup bl $7f within if
            do-normal-char
        else
            do-command
        then
        quit?
    until
;

: >lines ( buffer bufsize -- )
    local bufsize
    local buffer

    10 <vector> to lines

    buffer local dot
    dot local linestart
    buffer bufsize + local bufend

    begin
        begin
            dot bufend u<
            dot c@ $0a <> and
        while
            1 +to dot
        repeat

        linestart dot over - >string    \ -- string
        lines vector-push

        1 +to dot
        dot to linestart

        dot bufend =
    until

    lines vector-length to #lines
;

: ~lines ( -- )
    lines vector-length 0 ?do
        i lines vector-nth check-string ~string
    loop
    lines ~vector
;

: (edit) ( -- )
    0 local fileid
    0 local filesize
    0 local buffer
    0 local bufsize

    filename string> r/o open-file throw to fileid
    fileid file-size throw drop to filesize
    filesize -allocate to buffer
    buffer filesize fileid read-file throw to bufsize
    fileid close-file throw

    buffer bufsize >lines

    buffer -free

    edit-loop

    ~lines
;

only forth also editor also forth definitions

: edit ( "<spaces>name" -- )
    blword
    count
    [log ." edit " 2dup type log]
    >string to filename
    (edit)
    clear-status
    #cols #rows 1- at-xy
;

only forth also definitions
