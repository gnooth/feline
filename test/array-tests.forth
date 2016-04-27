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
    10 42 <array> local a
    a object? check
    a array? check
    a array-length 10 = check
    10 0 do
        i a array-nth 42 = check
    loop
    a ~array
    a array? check-false
    a object? check-false
\     a handle? check
;

test1

test: test2 ( -- )
    10 0 <array> local a
    10 0 do
        i (.) >string i a array-set-nth
    loop
    10 0 do
        i a array-nth string? check
        i a array-nth i (.) >transient-string string= check
    loop
    gc
    10 0 do
        i a array-nth string? check
        i a array-nth i (.) >transient-string string= check
    loop
    0 !> a
    gc
;

test2

test: test3 ( -- )
    42 17 2array local a
    a object? check
    a array? check
    a array-length 2 = check
    a array-first 42 = check
    a array-second 17 = check
    gc
    a array-length 2 = check
    a array-first 42 = check
    a array-second 17 = check
    0 !> a
    gc
;

test3

empty

?cr .( Reached end of array-tests.forth )
