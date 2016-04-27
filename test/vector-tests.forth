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

0 global v

test: test7 ( -- )
    10 <vector> !> v
    "foo" v vector-push
    "bar" v vector-push
    "baz" v vector-push

    "foo" v vector-find-string          \ -- index flag
    check
    0 = check

    "baz" v vector-find-string
    check
    2 = check

    "gazonk" v vector-find-string
    check-false
    check-false

    42 v vector-find-string
    check-false
    check-false
;

test7

\ each-integer vector-each-index vector-set-length
test: test8 ( -- )
    10 <vector> !> v
    v vector-length 0 = check
    \ element is index+1
    16 [ 1 + v vector-push ] each-integer
    v vector-length 16 = check
    v [ ( element index -- ) 1 + = check ] vector-each-index
    9 v vector-set-length
    v vector-length 9 = check
    v [ ( element index -- ) 1 + = check ] vector-each-index
    25 v vector-set-length
    v vector-length 25 = check
    9 0 do
        i v vector-nth i 1 + = check
    loop
    25 10 do
        i v vector-nth 0 = check
    loop
    0 v vector-set-length
    v vector-length 0 = check
    42 v vector-push
    87 v vector-push
    19 v vector-push
    v vector-length 3 = check
    0 v vector-nth 42 = check
    1 v vector-nth 87 = check
    2 v vector-nth 19 = check
    0 !> v
;

test8

test: test9
    10 <vector> !> v
    42 0 v vector-set-nth
    v vector-length 1 = check
    0 v vector-nth 42 = check
    87 12 v vector-set-nth
    v vector-length 13 = check
    12 v vector-nth 87 = check
;

test9

empty

?cr .( Reached end of vector-tests.forth )
