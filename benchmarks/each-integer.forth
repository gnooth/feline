require bench.forth

: test1
    100000 ['] drop each-integer
;

: test2
    100000 0 do i drop loop
;

: test3
    100000 0 do i ['] drop execute loop
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
