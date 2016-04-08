[undefined] feline? [if]

false constant feline?

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

: start-timer ( -- )
    ticks to start-ticks ;

: stop-timer ( -- )
    ticks to end-ticks ;

: .elapsed ( -- )
    cr elapsed-ms . ." ms " ;

[then]
