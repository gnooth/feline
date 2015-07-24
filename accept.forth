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

0 value bufstart
0 value buflen
0 value number-accepted
0 value done?

$08 constant #bs
$7f constant #del
$0d constant #cr
$0a constant #lf
$1b constant #esc

: do-bs  ( -- )
   number-accepted if
      -1 +to number-accepted
      #bs emit space #bs emit
   then ;

: do-escape  ( -- )
   number-accepted 0 ?do #bs emit loop
   0 to number-accepted ;

: do-enter  ( -- )
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
      else
         do-command
      then
   repeat
   number-accepted ;

' new-accept is accept
