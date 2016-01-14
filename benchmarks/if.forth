require bench.forth

: test1
    ?dup if drop then
;

1000 constant #loops

: test
    max-int64 local best-cycles
    1000 0 ?do
        start-timer
        #loops 0 do
            0 test1
            1 test1
        loop
        stop-timer
        elapsed-cycles best-cycles min to best-cycles
    loop
    cr
    best-cycles . ." cycles "
    best-cycles #loops / . ." cycles/loop"
;
