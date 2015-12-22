[undefined] feline? [if] false constant feline? [then]

s" iforth" environment? [if]
drop
: ticks ?ms ;
[then]

s" win32forth" environment? [if]
drop
: ticks ms@ ;
[then]

s" gforth" environment? [if]
2drop
: ticks utime 1000 um/mod nip ; \ gforth
[then]

[undefined] ticks [if]
: ticks counter ; \ SwiftForth
[then]

\ VFX Forth defines TICKS

0 value start-time

feline? [if]

0 value cycles

: start-timer ( -- )
    rdtsc to cycles
    ticks to start-time ;

: elapsed ( -- cycles ms )
    rdtsc cycles -
    ticks start-time - ;

: .elapsed ( -- )
    elapsed cr . ." ms " . ." cycles " ;

[else]

\ not Feline, no RDTSC support
: start-timer ( -- )
    ticks to start-time ;

: elapsed ( -- cycles ms )
    ticks start-time - ;

: .elapsed ( -- )
    elapsed cr . ." ms " ;

[then]

0 [if]
\ Individual benchmarks should define a TEST function like this:
: test ( -- )
    start-timer
    ( number of repetitions ) 0 ?do
        ( code to be tested )
    loop
    .elapsed
;
[then]
