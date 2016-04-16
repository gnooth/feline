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

[feline]

test: test1 ( -- )
    100000 local #reps
    10 <vector> local v
    v vector? check
    #reps 0 do
        i v vector-push
    loop
    v vector-length #reps = check
    #reps 0 do
        i v vector-nth i = check
    loop
    v ~vector
    v vector? check-false
;

test1

test: test2 ( -- )
    10000 local #reps
    10 <vector> local v
    v vector? check
    #reps 0 ?do
        i v vector-push
    loop
    v vector-length #reps = check
    #reps 0 ?do
        i v vector-nth i = check
    loop
    #reps 0 ?do
        0 v vector-nth i = check
        0 v vector-remove-nth
    loop
    v ~vector
    v vector? check-false
;

test2

test: test3 ( -- )
    10000 local #reps
    10 <vector> local v
    v vector? check
    #reps 0 do
        i v vector-push
    loop
    v vector-length #reps = check
    #reps 0 do
        v vector-length #reps i - = check
        0 v vector-nth i = check
        0 v vector-remove-nth
    loop
    v ~vector
    v vector? check-false
;

test3

test: test4
    10000 local #reps
    10 <vector> local v
    v vector? check
    #reps 0 do
        i v vector-push
    loop
    v vector-length #reps = check
    #reps 0 do
        v vector-length #reps i - = check
        v vector-length 1 - v vector-pop = check
    loop
    v ~vector
    v vector? check-false
;

test4

test: test5 ( -- )
    10 <vector> local v
    42 v vector-push
    v vector-length 1 = check
    v 0 vector-ref 42 = check

    v -1 ['] vector-ref catch 0<> check 2drop
    v 99 ['] vector-ref catch 0<> check 2drop
    v ~vector
    v vector? check-false
;

test5

test: test6 ( -- )
    10 <vector> local v
    v vector-length 0= check
    13 v vector-push
    v vector-length 1 = check
    v 0 42 vector-set
    v vector-length 1 = check
    v 0 vector-ref 42 = check

    v 1 87 ['] vector-set catch 0<> check 3drop
    v 1 ['] vector-ref catch 0<> check 2drop

    v ~vector
    v vector? check-false
;

test6

empty

?cr .( Reached end of vector-tests.forth )
