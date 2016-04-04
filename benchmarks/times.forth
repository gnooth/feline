require bench.forth

: test1
    100000 ['] noop times
;

: test2
    100000 0 do noop loop
;

: test3
    100000 0 do ['] noop execute loop
;

: test ( -- )
    ' local xt
    max-int64 local best-cycles
    1000 0 ?do
        start-timer
        xt execute
        stop-timer
        elapsed-cycles best-cycles min to best-cycles
    loop
    cr
    best-cycles . ." cycles "
;
