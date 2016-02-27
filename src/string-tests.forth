require check

0 value s1
0 value s2
0 value s3
0 value s4

s" this is a test" >transient-string to s1

: test1
    s1 string? check
    s1 transient? check
    s1 allocated? 0= check
    s1 string-length 14 = check
    s1 check-string string-length 14 = check
    s1 string> s" this is a test" str= check
    s1 check-string string> s" this is a test" str= check
;

test1

s" another test" >transient-string to s2

: test2
    s2 string? check
    s1 transient? check
    s1 allocated? 0= check
    s2 string-length 12 = check
    s2 check-string string-length 12 = check
    s2 string> s" another test" str= check
    s2 check-string string> s" another test" str= check
;

test2

\ make sure the second string doesn't disturb the first
test1

s"  and " >transient-string to s3

: test3
    s1 s3 concat to s4
    s4 string? check
    s4 transient? check
    s4 allocated? 0= check
    s4 string> s" this is a test and " str= check
    s4 ~string
    0 to s4
    s1 s3 concat s2 concat string> s" this is a test and another test" str= check
;

test3

: test4
    10000 0 do
\         cr i 6 .r space tsb-next h.
        s" this is a test" >transient-string to s1
        s" another test" >transient-string to s2
        s"  and " >transient-string to s3
        s1 s3 concat s2 concat to s4
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

: test5
    "this is a test" local s
    s 0 string-char 't' = check
    \ index out of range returns 0
    s 42 string-char 0= check
    s -1 string-char 0= check
;

test5

: test6
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

: test7
    "this is a test" local s1
    s1 8 string-char 'a' = check
;

test7

empty

cr .( Reached end of string-tests.forth )
