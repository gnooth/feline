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

\ sbuf-set-char
test: test6
    s" this is a test" >sbuf to s1
    s1 sbuf? check
    s1 string? check-false
    s1 2 'a' sbuf-set-char
    s1 3 't' sbuf-set-char
    s1 2 sbuf-char 'a' = check
    s1 3 sbuf-char 't' = check
    s1 sbuf>transient-string "that is a test" string= check

    \ index out of range
    s1 -1 'x' ['] sbuf-set-char catch 0<> check
    depth 3 = check 3drop
    s1 99 'x' ['] sbuf-set-char catch 0<> check
    depth 3 = check 3drop

    s1 ~sbuf
    s1 sbuf? check-false
;

test6

\ sbuf-insert-char
test: test7
    s" this is a test" >sbuf to s1
    s1 sbuf? check
    s1 string? check-false
    s1 9 'x' sbuf-insert-char
    s1 sbuf>transient-string "this is ax test" string= check

    s1 ~sbuf
    s1 sbuf? check-false
;

test7

\ sbuf-delete-char
test: test8
    s" this is a test" >sbuf to s1
    s1 sbuf? check
    s1 string? check-false
    s1 sbuf-length 14 = check
    s1 0 sbuf-delete-char
    s1 sbuf>transient-string "his is a test" string= check
    s1 sbuf-length 13 = check
    s1 12 sbuf-delete-char
    s1 sbuf>transient-string "his is a tes" string= check
    s1 sbuf-length 12 = check
    s1 4 sbuf-delete-char
    s1 sbuf>transient-string "his s a tes" string= check
    s1 sbuf-length 11 = check

    s1 sbuf? check
    s1 ~sbuf
    s1 sbuf? check-false
;

test8

empty

?cr .( Reached end of sbuf-tests.forth )
