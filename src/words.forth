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

forth!

: traverse-wordlist                     \ xt wid --
\ TOOLS EXT
    local wid
    local xt
    wid @ local nfa
    begin
        nfa
    while
        nfa xt execute
        0= if
            exit
        then
        nfa name>link @ to nfa
    repeat ;

0 value words-pattern
0 value words-count

: process-word ( $addr -- )
    words-pattern if
        dup count words-pattern string>
        search-ignore-case 0= if
            \ not a match
            3drop
            exit
        else
            2drop \ and fall through
        then
    then
    c@ 2+ ?line
    dup
    .id
    1 +to words-count ;

: (words) ( -- )
    0 to words-count
    cr
\     get-context
    0 context-vector vector-nth vocab-wordlist
    begin
        @
        ?dup
    while
        dup
        process-word
        name>link
    repeat
    ?cr
    words-count .
    ." word" words-count 1 <> if 's' emit then ;

: words ( -- )
\ TOOLS
\ "List the definition names in the first word list of the search order."
    parse-name ?dup if >transient-string else drop 0 then to words-pattern
    (words) ;

only forth also root definitions

: words words ;

only forth definitions
