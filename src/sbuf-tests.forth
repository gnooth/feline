require check

0 value s1
0 value s2
0 value s3
0 value s4

: test1
    cr ." test1 "
    256 <sbuf> to s1
    s1 sbuf? check
    s1 string? check-false
    s1 ~sbuf
    s1 sbuf? check-false
;

test1

: test2
    cr ." test2 "
    s" this is a test" >sbuf to s1
    s1 sbuf? check
    s1 string? check-false
    s1 sbuf-length 14 = check
    s1 sbuf-capacity 14 = check
    s1 ~sbuf
    s1 sbuf? check-false
;

test2

: test3
    cr ." test3 "
    s" this is a test " >sbuf to s1
    s1 sbuf? check
    s1 string? check-false
    s1 sbuf-length 15 = check
    s1 sbuf-capacity 15 = check
    s1 s" and this is another test" sbuf-append-chars
    s1 sbuf>string "this is a test and this is another test" string= check
    s1 ~sbuf
    s1 sbuf? check-false
;

test3

: test4
    cr ." test4 "
    s" test" >sbuf to s1
    s1 sbuf? check
    s1 string? check-false
    s1 sbuf-length 4 = check
    s1 sbuf-capacity 4 = check
    s1 's' sbuf-append-char
    s1 sbuf-length 5 = check
    s1 sbuf-capacity 5 >= check
    s1 sbuf>string "tests" string= check
    s1 ~sbuf
    s1 sbuf? check-false
;

test4

empty

cr .( Reached end of sbuf-tests.forth )
