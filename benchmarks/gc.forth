require bench.forth

20000 constant #objects

: prep ( -- )
    #objects 0 ?do
        s" this is a test" >string drop
    loop
;

: test
    max-int64 local best-cycles
    5 0 ?do
        gc
        prep
        start-timer
        gc
        stop-timer
        elapsed-cycles best-cycles min to best-cycles
    loop
    cr
    best-cycles . ." cycles "
    best-cycles #objects / . ." cycles/object"
;
