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

0 value start-ticks
0 value end-ticks

: elapsed-ms ( -- ms )
    end-ticks start-ticks - ;

feline? [if]

0 value start-cycles
0 value end-cycles

: start-timer ( -- )
    0 to end-ticks
    0 to end-cycles
    ticks to start-ticks
    rdtsc to start-cycles ;

: stop-timer ( -- )
    rdtsc to end-cycles
    ticks to end-ticks ;

: elapsed-cycles ( -- cycles )
    end-cycles start-cycles - ;

: .elapsed ( -- )
    cr elapsed-ms     . ." ms "
    cr elapsed-cycles . ." cycles " ;

[else]

\ not Feline, no RDTSC support
: start-timer ( -- )
    ticks to start-ticks ;

: stop-timer ( -- )
    ticks to end-ticks ;

: .elapsed ( -- )
    cr elapsed-ms . ." ms " ;

[then]
