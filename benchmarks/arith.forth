require bench.forth

: test1
    <>
;

1000 constant #loops

: test
    max-int64 local best-cycles
    1000 0 ?do
        start-timer
        #loops 0 do
            1 1 test1 drop
            1 2 test1 drop
            2 1 test1 drop
            2 2 test1 drop
        loop
        stop-timer
        elapsed-cycles best-cycles min to best-cycles
    loop
    cr
    best-cycles . ." cycles "
    best-cycles #loops / . ." cycles/loop"
;
