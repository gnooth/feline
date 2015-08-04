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

: ekey ( -- x )                         \ FACILITY EXT
   begin
      key?
   until
   0
   begin
      key?
   while
      8 lshift
      key or
   repeat ;

$1b5b43   constant k-right
$1b5b44   constant k-left
$1b5b41   constant k-up
$1b5b42   constant k-down
$1b5b48   constant k-home
$1b5b46   constant k-end
$1b5b337e constant k-delete
$1b5b357e constant k-prior
$1b5b367e constant k-next

: ekey>char ( x -- x false | char true )
\ FACILITY EXT
   dup 128 u< ;

: ekey>fkey ( x -- x false | u true )
\ FACILITY EXT
   ekey>char 0= ;
