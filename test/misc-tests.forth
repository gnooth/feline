\ Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

require-system-file test-framework

variable foo

test: test1 ( -- )
    -1 foo !
    42 foo w!
    foo w@ 42 = check
    0 foo !
    foo @ 0= check
    -3 foo w!
    foo w@s -3 = check
    foo @ $fffd = check
;

test1

empty

?cr .( Reached end of misc-tests.forth )
