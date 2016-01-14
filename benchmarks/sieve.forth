require bench.forth

decimal

8190 constant size

variable flags  size allot

: primes  ( -- )
   flags size 1 fill
   0
   size 0 do
      flags i + c@
      if
         i dup + 3 + dup i +
         begin
            dup size <
         while
            0 over flags + c! over +
         repeat
         2drop 1+
      then
   loop
   drop ;

: test ( -- )
    start-timer
    10000 0 ?do
        primes
    loop
    stop-timer
    .elapsed
;
