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

$08 constant #bs
$7f constant #del
$0d constant #cr
$0a constant #lf
$1b constant #esc

0 value bufstart
0 value buflen
0 value number-accepted
0 value done?

: do-bs  ( -- )
   number-accepted if
      -1 +to number-accepted
      #bs emit space #bs emit
   then ;

: clear-line  ( -- )
   number-accepted dup backspaces dup spaces backspaces
   0 to number-accepted ;

: redisplay-line  ( -- )
   bufstart number-accepted type ;

: do-escape  ( -- )
   clear-line ;

\ The number of slots allocated for the history list.
100 constant history-size

\ The current location of the interactive history pointer.
0 value history-offset

\ The number of strings currently stored in the history list.
0 value history-length

\ An array of history entries.
create history-array  history-size cells allot  history-array history-size cells erase

: current-history  ( -- addr )
   history-array 0= if 0 exit then      \ shouldn't happen
   history-offset 0 history-length within if
      history-array history-offset cells + @
   else
      0
   then ;

\ Returns the address of the first (i.e. zeroth) cell in the history array.
: first-history  ( -- addr )
   history-array 0= if 0 exit then      \ shouldn't happen
   history-array ;

\ Returns the address of the last cell in the history array.
: last-history  ( -- addr )
   history-array 0= if 0 exit then      \ shouldn't happen
   history-array history-size 1- cells + ;

: history  ( -- )
   history-array 0= if 0 exit then      \ shouldn't happen
   history-length 0 ?do
      history-array history-length 1- i - cells + @
      cr count type
   loop ;

: add-history  ( -- )
   number-accepted if
      last-history @ ?dup if free drop then
      history-array dup cell+ history-size 1- cells cmove>
      number-accepted 1+ allocate 0= if
         dup first-history !
         bufstart number-accepted rot place
         history-length history-size < if
            1 +to history-length
         then
      then
   then ;

: do-previous
   history-offset history-length < if
      1 +to history-offset
      current-history
      ?dup if
         clear-line
         count dup to number-accepted
         bufstart swap cmove
         redisplay-line
      else
         -1 +to history-offset
      then
   then ;

: do-next  ( -- )
   history-offset 0> if
      -1 +to history-offset
      current-history
      ?dup if
         clear-line
         count dup to number-accepted
         bufstart swap cmove
         redisplay-line
      then
   then ;

: do-enter  ( -- )
   add-history
   space
   true to done? ;

: do-command  ( n -- )
   case
      #lf of \ Linux
         do-enter
      endof
      #cr of \ Windows
         do-enter
      endof
      #bs of \ Windows
         do-bs
      endof
      #del of \ Linux
         do-bs
      endof
      #esc of
         do-escape
         -1 to history-offset
      endof
      $10 of
        do-previous
      endof
      $0e of
        do-next
      endof
   endcase ;

: new-accept  ( c-addr +n1 -- +n2 )
   to buflen
   to bufstart
   false to done?
   0 to number-accepted
   begin
      number-accepted buflen <
      done? 0= and
   while
      key
      dup bl $7f within if
         dup emit
         bufstart number-accepted + c!
         1 +to number-accepted
         -1 to history-offset
      else
         do-command
      then
   repeat
   number-accepted ;

line-input? 0= [if] ' new-accept is accept [then]
