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

feline!

: copy-file ( src dest -- )
    local dest   \ string
    local src    \ string

    0 local fileid
    0 local filesize
    0 local buffer
    0 local bufsize

    src string> r/o open-file throw to fileid
    fileid file-size throw drop to filesize

    filesize -allocate to buffer
    buffer filesize fileid read-file throw to bufsize
    fileid close-file throw

    dest string> w/o create-file throw to fileid
    buffer bufsize fileid write-file throw
    fileid close-file throw
;

[undefined] editor [if] vocabulary editor [then]

editor definitions

0 value editor-filename

0 value lines                           \ a vector of strings

: #lines lines vector-length ;          \ number of lines in the file being edited

\ 0 value top                             \ zero-based line number of top line of display

0 value cursor-x

0 value cursor-y

: cursor-line# ( -- n )                 \ zero-based index of current line in lines vector
    editor-top-line cursor-y +
;

: cursor-line ( -- sbuf )
    cursor-line# lines vector-nth check-sbuf
;

: cursor-line-length ( -- n )
    cursor-line sbuf-length
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
    windows-ui? 0= if
        0 #rows at-xy
        #cols 20 - spaces
    then
;

: status ( c-addr u -- )
    >string local s
    s .status-text
    s ~string
;

: .status ( -- )
    #cols 20 - #rows at-xy
    ." Line " editor-top-line cursor-y + 1+ .
    ." Col " cursor-x 1+ .
;

: clear-status ( -- )
    0 #rows at-xy
    #cols spaces
;

false value repaint?

: redisplay ( -- )
    repaint? if
        [ windows-ui? ] [if]
            true repaint
            0 to repaint?
            exit
        [then]
        0 0 at-xy
        editor-top-line
        #rows 1 -
        bounds ?do
            i #lines < if
                i lines vector-nth      \ -- sbuf
                \ REVIEW
                sbuf>transient-string
                string>                 \ -- c-addr u
                dup>r
                #cols min type
                #cols r> - spaces
            else
                #cols spaces
            then
            cr \ needed for Windows console app
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
        editor-top-line 0> if
            -1 +to editor-top-line
            true to repaint?
        then
    then
    adjust-cursor-x
;

: do-down ( -- )
    cursor-line# #lines 1- < if
        cursor-y /page < if
            cursor-x cursor-y 1+ set-cursor
        else
            editor-top-line #lines < if
                1 +to editor-top-line
                true to repaint?
            then
        then
        adjust-cursor-x
    then
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
    editor-top-line /page + #lines < if
        /page +to editor-top-line
        true to repaint?
    then
    adjust-cursor-x
;

: do-page-up
    /page negate +to editor-top-line
    editor-top-line 0< if
        0 to editor-top-line
    then
    true to repaint?
    adjust-cursor-x
;

\ FIXME bad name
: do-^home ( -- )
    0 to editor-top-line
    0 0 set-cursor
    0 to goal-x
    true to repaint?    \ not always necessary
;

\ FIXME bad name
: do-^end ( -- )
    lines vector-length 1- dup 0>= if
        to editor-top-line
        0 to cursor-y
        cursor-line-length to cursor-x
        cursor-x to goal-x
        true to repaint?        \ not always necessary
    then
;

: delete-line-separator ( -- )
    cursor-line# #lines 1- < if
        cursor-x cursor-line-length = if
            cursor-line# 1+ lines vector-nth check-sbuf \ -- sbuf
            sbuf>transient-string \ -- string
            cursor-line swap sbuf-append-string
            cursor-line# 1+ lines vector-remove-nth
            true to repaint?
        then
    then
;

: do-delete ( -- )
    cursor-x cursor-line-length > abort" DO-DELETE cursor-x > cursor-line-length"
    cursor-x cursor-line-length < if
        cursor-line cursor-x sbuf-delete-char
        true to repaint?        \ FIXME repaint cursor line only
    else
        \ cursor-x == cursor-line-length
        delete-line-separator
    then
;

: do-backspace ( -- )
    cursor-x 0= if
        cursor-line# 0> if
            -1 +to cursor-y
            cursor-y 0< if
                -1 +to editor-top-line
                0 to cursor-y
            then
            cursor-line-length to cursor-x
            delete-line-separator
        then
    else
        do-left
        do-delete
    then
;


: do-normal-char ( char -- )
    cursor-line check-sbuf              \ -- char sbuf
    cursor-x                            \ -- char sbuf index
    rot                                 \ -- sbuf index char
    sbuf-insert-char                    \ --

    1 +to cursor-x
    cursor-x to goal-x
    true to repaint?
;

\ : insert-line-separator ( -- )
\     cursor-x cursor-line-length <= if
\         cursor-x cursor-line-length cursor-line string-substring        \ -- string
\         cursor-line# 1+ lines vector-insert-nth
\         cursor-x cursor-line string-set-length
\         1 +to cursor-y
\         0 to cursor-x
\         0 to goal-x
\         true to repaint?
\     then
\ ;

\ : make-backup ( -- )
\     editor-filename string-clone local backup-filename
\     '~' backup-filename string-append-char
\     editor-filename backup-filename copy-file
\ ;

\ : do-save ( -- )
\     s" Saving..." status
\     make-backup
\     editor-filename string> w/o create-file throw local fileid
\     #lines 0 ?do
\         i lines vector-nth              \ -- string
\         string>                         \ -- c-addr u
\         fileid                          \ -- c-addr u fileid
\         write-line                      \ -- ior
\         -76 ?throw
\     loop
\     fileid close-file -62 ?throw
\     s" Saving...done" status
\ ;

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
\ $0a ,           ' insert-line-separator ,
\ $13 ,           ' do-save ,                     \ c-s
$11 ,           ' do-quit ,                     \ c-q
0 ,             ' drop ,

: do-command ( x -- )
    keytable switch ;

: edit-loop ( -- )
    0 to editor-top-line
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

        linestart dot over - >sbuf      \ -- sbuf
        lines vector-push

        1 +to dot
        dot to linestart

        dot bufend =
    until

    lines to editor-line-vector
;

: ~lines ( -- )
    lines vector-length 0 ?do
        i lines vector-nth
        dup sbuf? if ~sbuf else ~string then
    loop
    lines ~vector
;

: (edit) ( -- )
    0 local fileid
    0 local filesize
    0 local buffer
    0 local bufsize

    editor-filename string> r/o open-file throw to fileid
    fileid file-size throw drop to filesize
    filesize -allocate to buffer
    buffer filesize fileid read-file throw to bufsize
    fileid close-file throw

    buffer bufsize >lines

    buffer -free

    edit-loop

    0 to editor-line-vector

    ~lines
;

also forth definitions

: edit ( "<spaces>name" -- )
    parse-name
    >string to editor-filename
    (edit)
    clear-status
    #cols #rows 1- at-xy
;

: ed ( -- )
    editor-filename if
        (edit)
        clear-status
        #cols #rows 1- at-xy
    then
;

feline! \ REVIEW
