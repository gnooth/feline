require check

42 constant k1
17 constant k2
57 constant k3

: inner-no-throw ( x y -- )
    local y
    local x
    x k1 k2 + = check
    y k1 k2 - = check
;

: inner-throw ( x y -- )
    local y
    local x
    x k1 k2 + = check
    y k1 k2 - = check
    k3 throw
;

: outer ( x y inner -- )
    local inner
    local y
    local x
    x y +
    x y -
    inner catch
    ?dup if
        k3 = check
        2drop
    then
    depth 0= check
    x k1 = check
    y k2 = check
    x y +
;

: test1 ( -- )
    cr "test1" .string
    k1 k2 ['] inner-no-throw outer k1 k2 + = check
;

test1

: test2 ( -- )
    cr "test2" .string
    k1 k2 ['] inner-throw outer k1 k2 + = check
;

test2

empty

?cr .( Reached end of local-tests.forth )
