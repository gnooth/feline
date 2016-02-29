require check

variable foo
-1 foo !
42 foo w!
foo w@ 42 = check
0 foo !
foo @ 0= check
-3 foo w!
foo w@s -3 = check
foo @ $fffd = check

empty

cr .( Reached end of misc-tests.forth )
