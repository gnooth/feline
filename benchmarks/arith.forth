include bench.forth

: test1
    <
;

: test
    start-timer
    100000000 0 ?do
        1 2 test1 drop
        2 1 test1 drop
    loop
    .elapsed
;
