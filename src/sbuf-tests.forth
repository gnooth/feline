require test-framework

0 value s1
0 value s2
0 value s3
0 value s4

test: test1
    256 <sbuf> to s1
    s1 sbuf? check
    s1 string? check-false
    s1 ~sbuf
    s1 sbuf? check-false
;

test1

test: test2
    s" this is a test" >sbuf to s1
    s1 sbuf? check
    s1 string? check-false
    s1 sbuf-length 14 = check
    s1 sbuf-capacity 14 = check
    s1 ~sbuf
    s1 sbuf? check-false
;

test2

test: test3
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

test: test4
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

\ sbuf-char
test: test5
    s" this is a test" >sbuf to s1
    s1 sbuf? check
    s1 string? check-false
    s1 0 sbuf-char 't' = check
    s1 1 sbuf-char 'h' = check

    \ REVIEW index out of range returns 0
    s1 -1 sbuf-char 0= check
    s1 99 sbuf-char 0= check

    s1 ~sbuf
    s1 sbuf? check-false
;

test5

empty

cr .( Reached end of sbuf-tests.forth )
