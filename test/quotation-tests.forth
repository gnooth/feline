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

require-system-file test-framework

language: feline

context: feline forth ;
current: feline

test: test1 ( -- )
    [ 42 ] execute 42  = check
;

test1

test: test2 ( -- )
    [ 42 local foo 87 local bar foo bar + ] execute 129 = check
;

test2

: foo ( n1 n2 -- n1-n2 n1-n2 n1-n2 )
    local n2
    local n1

    n1 n2 -
    n2 n1 [ swap - ] execute
    n1 n2 -
;

test: test3
    87 42 foo
    45 = check
    45 = check
    45 = check
;

test3

empty

?cr .( Reached end of quotation-tests.forth )
