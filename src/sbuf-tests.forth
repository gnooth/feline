: assert ( flag -- )
    0=
    if -1000 throw then
;

: assert-false ( flag -- )
    if -1001 throw then
;

0 value s1
0 value s2
0 value s3
0 value s4

: test1
    cr ." test1 "
    256 <sbuf> to s1
    s1 sbuf? assert
    s1 string? assert-false
    s1 ~sbuf
    s1 sbuf? assert-false
;

test1

: test2
    cr ." test2 "
    s" this is a test" >sbuf to s1
    s1 sbuf? assert
    s1 string? assert-false
    s1 sbuf-length 14 = assert
    s1 sbuf-capacity 14 = assert
    s1 ~sbuf
    s1 sbuf? assert-false
;

test2

: test3
    cr ." test3 "
    s" this is a test " >sbuf to s1
    s1 sbuf? assert
    s1 string? assert-false
    s1 sbuf-length 15 = assert
    s1 sbuf-capacity 15 = assert
    s1 s" and this is another test" sbuf-append-chars
    s1 sbuf>string "this is a test and this is another test" string= assert
    s1 ~sbuf
    s1 sbuf? assert-false
;

test3

: test4
    cr ." test4 "
    s" test" >sbuf to s1
    s1 sbuf? assert
    s1 string? assert-false
    s1 sbuf-length 4 = assert
    s1 sbuf-capacity 4 = assert
    s1 's' sbuf-append-char
    s1 sbuf-length 5 = assert
    s1 sbuf-capacity 5 >= assert
    s1 sbuf>string "tests" string= assert
    s1 ~sbuf
    s1 sbuf? assert-false
;

test4

empty

cr .( Reached end of sbuf-tests.forth )
