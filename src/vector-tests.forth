: assert ( flag -- )
    0= abort" assertion failed"
;

: test1 ( -- )
    100000 local #reps
    10 <vector> check-vector local v
    v vector? assert
    #reps 0 do
        i v vector-push
    loop
    #reps 0 do
        i v vector-nth i = assert
    loop
    v ~vector
    v vector? 0= assert
;

: test2 ( -- )
    10000 local #reps
    10 <vector> check-vector local v
    v vector? assert
    #reps 0 ?do
        i v vector-push
    loop
    v vector-length #reps = assert
    #reps 0 ?do
        0 v vector-nth i = assert
        0 v vector-remove-nth
    loop
    v ~vector
    v vector? 0= assert
;

: test3 ( -- )
    10000 local #reps
    10 <vector> check-vector local v
    v vector? assert
    #reps 0 do
        i v vector-push
    loop
    v vector-length #reps = assert
    #reps 0 do
        v vector-length #reps i - = assert
        0 v vector-nth i = assert
        0 v vector-remove-nth
    loop
    v ~vector
    v vector? 0= assert
;

: test4
    10000 local #reps
    10 <vector> check-vector local v
    v vector? assert
    #reps 0 do
        i v vector-push
    loop
    v vector-length #reps = assert
    #reps 0 do
        v vector-length #reps i - = assert
        v vector-length 1- v vector-pop = assert
    loop
    v ~vector
    v vector? 0= assert
;

test1 test2 test3 test4

?cr .( Reached end of vector-tests.forth )