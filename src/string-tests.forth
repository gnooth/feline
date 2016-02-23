: assert ( flag -- )
    0=
\     abort" assertion failed"
    if -1000 throw then
;

0 value s1
0 value s2
0 value s3
0 value s4

s" this is a test" >transient-string to s1

: test1
    s1 simple-string? assert
    s1 string? assert
    s1 transient? assert
    s1 allocated? 0= assert
    s1 string-length 14 = assert
    s1 check-string string-length 14 = assert
    s1 simple-string> s" this is a test" str= assert
    s1 check-string simple-string> s" this is a test" str= assert
;

test1

s" another test" >transient-string to s2

: test2
    s2 simple-string? assert
    s2 string? assert
    s1 transient? assert
    s1 allocated? 0= assert
    s2 string-length 12 = assert
    s2 check-string string-length 12 = assert
    s2 simple-string> s" another test" str= assert
    s2 check-string simple-string> s" another test" str= assert
;

test2

\ make sure the second string doesn't disturb the first
test1

s"  and " >transient-string to s3

: test3
    s1 s3 concat to s4
    s4 string? assert
    s4 simple-string? assert
    s4 transient? assert
    s4 allocated? 0= assert
    s4 string> s" this is a test and " str= assert
    s4 ~string
    0 to s4
    s1 s3 concat s2 concat string> s" this is a test and another test" str= assert
;

test3

: test4
    10000 0 do
\         cr i 6 .r space tsb-next h.
        s" this is a test" >transient-string to s1
        s" another test" >transient-string to s2
        s"  and " >transient-string to s3
        s1 s3 concat s2 concat to s4
        s4 string? assert
        s4 simple-string? assert
        s4 transient? assert
        s4 allocated? 0= assert
        s4 string> s" this is a test and another test" str= assert
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

: test5
    "this is a test" local s
    0 s string-nth 't' = assert
    \ index out of range returns 0
    42 s string-nth 0= assert
    -1 s string-nth 0= assert
;

test5

: test6
    s" two short" >string local s
    s string-length 9 = assert
    s growable-string? assert
    s 's' string-append-char
    s string-length 10 = assert
    s string> s" two shorts" str= assert
    s allocated? assert
    s ~string
;

test6

: test7
    256 <string> local s
    s "this is a test" string> string-append-chars
    s string-length 14 = assert
    s string> s" this is a test" str= assert
    s " of the emergency broadcasting system" string> string-append-chars
    s string> s" this is a test of the emergency broadcasting system" str= assert
    s ~string
    s string? 0= assert
;

test7

: test8
    s" this" >string local s
    s string> "this" string> str= assert
    s " is a test" string-append
    s string> "this is a test" string> str= assert
    s ~string
    s string? 0= assert
;

test8

cr .( Reached end of string-tests.forth )
