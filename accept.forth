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

$08 constant bs
$7f constant del
$1b constant esc

0 value bufstart
0 value buflen
0 value dot
0 value #in
0 value done?

: .full ( -- )
    dot backspaces
    bufstart #in type

    \ FIXME fix display in case we've deleted 1 char in the middle of the line
    space bs emit

    #in backspaces
    bufstart dot type ;

: do-bs ( -- )
    #in 0= if exit then
    dot 0= if exit then
    #in dot = if
        -1 +to #in
        -1 +to dot
        bs emit space bs emit
        exit
    then
    bufstart dot + dup 1- #in dot - cmove
    bs emit
    -1 +to dot
    -1 +to #in
    .full ;

: do-delete ( -- )
    dot #in < if
        -1 +to #in
        dot #in < if
            bufstart dot + dup 1+ swap #in dot - cmove
        then
        .full                           \ REVIEW
    then ;

: clear-line ( -- )
    #in dup backspaces dup spaces backspaces
    0 to #in
    0 to dot ;

: redisplay-line ( -- )
    bufstart #in type ;

\ The number of slots allocated for the history list.
100 constant history-size

\ The current location of the interactive history pointer.
-1 value history-offset

\ The number of strings currently stored in the history list.
0 value history-length

\ An array of history entries.
create history-array  history-size cells allot  history-array history-size cells erase

: current-history ( -- $addr )
    history-array 0= if 0 exit then     \ shouldn't happen
    history-offset 0 history-length within if
        history-array history-offset cells + @
    else
        0
    then ;

\ Return the contents of the first cell in the history array.
: oldest ( -- addr )
    history-array 0= if 0 exit then     \ shouldn't happen
    history-array @ ;

\ Return the contents of the last occupied cell in the history array.
: newest ( -- addr )
    history-array 0= if 0 exit then     \ shouldn't happen
    history-length 0= if 0 exit then
    history-array history-length 1- cells + @ ;

: history ( -- )
    history-array 0= if exit then       \ shouldn't happen
    history-length 0 ?do
        history-array i cells + @
        cr count type
    loop ;

0 value $history-file-pathname

: history-file-pathname ( -- c-addr u )
    $history-file-pathname 0= if
        [ linux? ] [if] s" HOME" [else] s" USERPROFILE" [then]
        getenv \ -- c-addr u
        $buf 1+ zplace
        [ linux? ] [if] s" /" [else] s" \" [then]
        $buf 1+ zappend
        s" .forth_history" $buf 1+ zappend
        $buf 1+ zstrlen $buf c!
\         $buf count >$ to $history-file-pathname
        here $buf count string, to $history-file-pathname
        +$buf
    then
    $history-file-pathname count ;

: save-history ( -- )
    history-array 0= if exit then       \ shouldn't happen
    history-file-pathname w/o create-file
    0= if                               \ -- fileid
        history-length 0 ?do
            dup                         \ -- fileid fileid
            history-array i cells + @
            count                       \ -- fileid fileid c-addr u
            rot                         \ -- fileid c-addr u fileid
            write-line                  \ -- fileid ior
            drop                        \ -- fileid
        loop
        close-file drop
    then ;

create restore-array 10 cells allot

create restore-buffer 258 allot

: read-history-line ( fileid -- c-addr u2 )
    restore-buffer 256 rot read-line    \ -- u2 flag ior
    0= if
        ( flag ) if
            restore-buffer swap
        else
            drop 0 0
        then
    else
        2drop 0 0
    then ;

: allocate-history-entry ( c-addr u -- $addr )
    >$ ;

: restore-history ( -- )
    history-array history-size cells erase
    0 to history-length
    0 to history-offset
    history-file-pathname r/o open-file 0= if
        >r
        begin
            history-offset history-size <
        while
            r@ read-history-line        \ -- c-addr u
            ?dup if
                allocate-history-entry  \ -- alloc-addr
                history-array history-offset cells + !
                1 +to history-offset
                1 +to history-length
            else
                drop
                r> close-file
                drop                    \ REVIEW
                -1 to history-offset
                exit
            then
        repeat
        r> close-file
        drop                            \ REVIEW
        -1 to history-offset
    else
        drop
    then ;

: clear-history ( -- )
    history-array history-size cells erase
    0 to history-length
    -1 to history-offset ;

: (free-history) ( -- )
    history-size 0 ?do
        history-array i cells + @
        ?dup if
            -free
        then
    loop ;

: add-history ( -- )
    #in if
        newest ?dup if
            count bufstart #in str= if exit then
        then
        history-length history-size > if true abort" add-history: shouldn't happen" then
        history-length history-size = if
            \ we need to make room
            oldest ?dup if
                -free
            then
            history-array dup cell+ swap history-size 1- cells move
            -1 +to history-length

            history-offset -1 <> if
                -1 +to history-offset
            then

        then
        history-length history-size < if
            bufstart #in
            allocate-history-entry history-array history-length cells + !
            1 +to history-length
\             -1 to history-offset
        then
    then ;

: do-escape ( -- )
    clear-line
    -1 to history-offset ;

: get-current-history ( -- )
    current-history
    ?dup if
        clear-line
        count dup to #in dup to dot
        bufstart swap cmove
        redisplay-line
    then
;

: do-previous ( -- )
    history-length 0= if exit then
    history-offset 0< if
        \ most recent entry is at highest offset
        history-length to history-offset
    then
    history-offset 0> if
        -1 +to history-offset
    then
    history-offset history-length < if
        get-current-history
    then ;

: do-next ( -- )
    history-length 0= if exit then
    history-offset 0< if exit then
    history-offset history-length 1- < if
        1 +to history-offset
        get-current-history
    else
        clear-line
        -1 to history-offset
    then ;

: do-enter ( -- )
    dot #in < if
        bufstart dot + #in dot - type
    then
    add-history
    save-history
    space
    -1 to history-offset
    true to done? ;

: accept-line-and-down-history ( -- )
    dot #in < if
        bufstart dot + #in dot - type
    then
    add-history
    save-history
    space
\     -1 to history-offset
    true to done? ;

: do-home ( -- )
    dot backspaces
    0 to dot ;

: do-end ( -- )
    bufstart dot + #in dot - type
    #in to dot ;

: do-right ( -- )
    dot #in < if
        bufstart dot + c@ emit
        1 +to dot
    then ;

: do-left ( -- )
    dot 0 > if
        bs emit
        -1 +to dot
    then ;

create keytable

$0a ,          ' do-enter ,             \ Linux
$0d ,          ' do-enter ,             \ Windows
bs ,           ' do-bs ,                \ Windows
del ,          ' do-bs ,                \ Linux
esc ,          ' do-escape ,
3 ,            ' bye ,                  \ control c
$10 ,          ' do-previous ,          \ control p
$0e ,          ' do-next ,              \ control n
k-up ,         ' do-previous ,
k-down ,       ' do-next ,
k-left ,       ' do-left ,
k-right ,      ' do-right ,
k-home ,       ' do-home ,
k-end ,        ' do-end ,
k-delete ,     ' do-delete ,
$0f ,          ' accept-line-and-down-history ,
0 ,            ' drop ,                 \ REVIEW

: do-command ( x -- )
    keytable switch ;

: do-normal-char ( c -- )
    dot #in < if
        bufstart dot + dup 1+ #in dot - cmove>
    then
    dup emit
    bufstart dot + c!
    1 +to dot
    1 +to #in
    -1 to history-offset
    .full ;

: new-accept ( c-addr +n1 -- +n2 )
    to buflen
    to bufstart
    false to done?
    yellow foreground
    history-offset -1 <> if
        1 +to history-offset
        get-current-history
    else
        0 to #in
        0 to dot
    then
    begin
        #in buflen <
        done? 0= and
    while
        ekey
        dup bl $7f within if
            do-normal-char
        else
            do-command
        then
    repeat
    white foreground
    #in ;

line-input? 0= [if]
restore-history
' (free-history) is free-history
' new-accept is accept
true to color?
[then]
