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
    check-string local dest   \ string
    check-string local src    \ string

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

false value editing?

0 value editor-filename

0 global lines                          \ a vector of sbufs

: #lines lines vector-length ;          \ number of lines in the file being edited

\ 0 value top                             \ zero-based line number of top line of display

0 value cursor-x

0 value cursor-y

: cursor-line# ( -- n )                 \ zero-based index of current line in lines vector
    editor-top-line cursor-y +
;

: cursor-line ( -- sbuf )
    cursor-line# lines vector-nth
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
        .string
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

: clear-status-line ( -- )
    windows-ui? 0= if
        0 #rows at-xy
        #cols 1- spaces
    then
;

: status ( string -- )
    .status-text
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
            cursor-line# 1+ lines vector-nth \ -- sbuf
            sbuf>transient-string \ -- string
            cursor-line swap sbuf-append-string
            cursor-line# 1+ lines vector-remove-nth
            true to repaint?
        then
    then
;

0 global kill-ring

: kill-line ( -- )
    cursor-x cursor-line-length < if
        kill-ring 0= if
            10 <vector> !> kill-ring
        then
        cursor-line sbuf>transient-string
        cursor-x cursor-line-length string-substring
        kill-ring vector-push
        cursor-x cursor-line sbuf-shorten
        true to repaint?
    then
;

: paste ( -- )
    0 local s
    0 local paste-length
    kill-ring if
        kill-ring vector-length 0> if
            cursor-line sbuf>transient-string !> s
            s 0 cursor-x string-substring
            kill-ring vector-pop
            dup string-length !> paste-length
            concat
            s cursor-x cursor-line-length string-substring concat
            string>sbuf
            cursor-line# lines vector-set-nth
            paste-length +to cursor-x
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
    cursor-line                         \ -- char sbuf
    cursor-x                            \ -- char sbuf index
    rot                                 \ -- sbuf index char
    sbuf-insert-char                    \ --

    1 +to cursor-x
    cursor-x to goal-x
    true to repaint?
;

: insert-line-separator ( -- )
    cursor-x cursor-line-length <= if
        cursor-line                     \ -- sbuf
        sbuf>transient-string           \ -- string
        cursor-x cursor-line-length     \ -- string index1 index2
        string-substring                \ -- substring
        string>sbuf                     \ -- sbuf
        cursor-line# 1+ lines vector-insert-nth
        cursor-x cursor-line sbuf-shorten
        1 +to cursor-y
        0 to cursor-x
        0 to goal-x
        true to repaint?
    then
;

: make-backup ( -- )
    editor-filename string>sbuf local backup-filename
    backup-filename '~' sbuf-append-char
    editor-filename backup-filename sbuf>transient-string copy-file
;

: do-save ( -- )
    "Saving..." status
    make-backup
    editor-filename string> w/o create-file throw local fileid
    #lines 0 ?do
        i lines vector-nth              \ -- string
        sbuf>                           \ -- c-addr u
        fileid                          \ -- c-addr u fileid
        write-line                      \ -- ior
        -76 ?throw
    loop
    fileid close-file -62 ?throw
    "Saving...done" status
;

: ~lines ( -- )
\     lines vector-length 0 ?do
\         i lines vector-nth ~object
\     loop
\     lines ~vector
    0 !> lines
    gc
;

: do-quit
    clear-status-line
    0 to editor-line-vector
    ~lines
    false to editing?
    quit
;

: do-escape ( -- )
    clear-status-line
    quit
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
windows? [if]
$0d ,           ' insert-line-separator ,
[else]
$0a ,           ' insert-line-separator ,
[then]
$0b ,           ' kill-line ,                   \ c-k
$16 ,           ' paste ,                       \ c-v
$1b ,           ' do-escape ,
$13 ,           ' do-save ,                     \ c-s
$11 ,           ' do-quit ,                     \ c-q
0 ,             ' drop ,

: do-command ( x -- )
    keytable switch ;

: edit-loop ( -- )
    page
    editing? if
        cursor-x cursor-y set-cursor
    else
        0 to editor-top-line
        0 0 set-cursor
    then
    true to editing?
    true to repaint?
    begin
        redisplay
        ekey
        clear-status-text
        dup bl $7f within if
            do-normal-char
        else
            do-command
        then
    again
;

: >lines ( buffer bufsize -- )
    local bufsize
    local buffer

    10 <vector> !> lines

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
    editing? if
        edit-loop
    then
;

feline! \ REVIEW
