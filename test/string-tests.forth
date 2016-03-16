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

0 value s1
0 value s2
0 value s3
0 value s4

s" this is a test" >transient-string to s1

test: test1
    s1 object? check
    s1 string? check
    s1 transient? check
    s1 allocated? check-false
    s1 string-length 14 = check
    s1 check-string string-length 14 = check
    s1 string> s" this is a test" str= check
    s1 check-string string> s" this is a test" str= check
;

test1

s" another test" >transient-string to s2

test: test2
    s2 object? check
    s2 string? check
    s2 transient? check
    s2 allocated? check-false
    s2 string-length 12 = check
    s2 check-string string-length 12 = check
    s2 string> s" another test" str= check
    s2 check-string string> s" another test" str= check
;

test2

\ make sure the second string doesn't disturb the first
test1

s"  and " >transient-string to s3

test: test3
    s1 s3 concat to s4
    s4 object? check
    s4 string? check
    s4 transient? check
    s4 allocated? check-false
    s4 string> s" this is a test and " str= check
    s4 ~string
    0 to s4
    s1 s3 concat s2 concat string> s" this is a test and another test" str= check
;

test3

test: test4
    10000 0 do
        s" this is a test" >transient-string to s1
        s" another test" >transient-string to s2
        s"  and " >transient-string to s3
        s1 s3 concat s2 concat to s4
        s4 object? check
        s4 string? check
        s4 transient? check
        s4 allocated? 0= check
        s4 string> s" this is a test and another test" str= check
        s" x" >string s4 over concat ~string ~string
        s1 ~string
        s2 ~string
        s3 ~string
        s4 ~string
        0 to s1
        0 to s2
        0 to s3
        0 to s4
    loop
;

test4

test: test5
    "this is a test" local s
    s 0 string-char 't' = check
    \ index out of range returns 0
    s 42 string-char 0= check
    s -1 string-char 0= check
;

test5

test: test6
    "this is a test" local s1
    "this is a test" local s2
    s1 s2 <> check
    s1 s2 string= check
    s" this is a test" >string local s3
    s1 s3 string= check
    s3 ~string
    s3 string? 0= check
    s" this is a test" >transient-string local s4
    s1 s4 string= check
    s" this is a test" >string local s5
    s1 s5 string= check
    s5 ~string
    s5 string? 0= check
    "this is not a test" local s6
    s1 s6 string= 0= check
    "this is a text" local s7
    s1 s7 string= 0= check
;

test6

test: test7
    "this is a test" to s1
    s1 0 4 string-substring to s2
    s2 string? check
    s2 string-length 4 = check
    s2 "this" string= check

    \ s2 copies its data
    s1 string-data s2 string-data <> check

    \ can't destroy s1 because it's a static string
    s1 ~string
    s1 string? check

    s2 ~string
    s2 string? check-false
;

test7

test: test8
    "this is another test" to s1
    s1 'x' string-index-of -1 = check
    s1 's' string-index-of  3 = check
    s1 'a' string-index-of  8 = check
    s1 'n' string-index-of  9 = check
    s1 't' string-index-of  0 = check
    s1 'e' string-index-of 13 = check

    \ can't destroy s1 because it's a static string
    s1 ~string
    s1 string? check
;

test8

test: test9
    s" this is a test" >string to s1
    s1 string? check-false
    s1 handle? check
    s1 ~string
    s1 handle? check
    s1 to-object check-false
;

test9

empty

cr .( Reached end of string-tests.forth )
