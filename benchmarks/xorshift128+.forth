\ V8's random number generator
\ http://v8project.blogspot.com/2015/12/theres-mathrandom-and-then-theres.html

\ uint64_t state0 = 1;
\ uint64_t state1 = 2;
\ uint64_t xorshift128plus() {
\   uint64_t s1 = state0;
\   uint64_t s0 = state1;
\   state0 = s0;
\   s1 ^= s1 << 23;
\   s1 ^= s1 >> 17;
\   s1 ^= s0;
\   s1 ^= s0 >> 26;
\   state1 = s1;
\   return state0 + state1;
\ }

include bench.forth

1 value state0
2 value state1

feline? [if]

: xorshift128+ ( -- n )
    state0 local s1
    state1 local s0
    s0 to state0
    s1 23 lshift s1 xor to s1
    s1 17 rshift s1 xor to s1
    s1 s0 xor to s1
    s0 26 rshift s1 xor to s1
    s1 to state1
    state0 state1 +
;

[else]

[defined] {: [if]
: xorshift128+ {: | s0 s1 -- n :}
    state0 to s1
    state1 to s0
    s0 to state0
    s1 23 lshift s1 xor to s1
    s1 17 rshift s1 xor to s1
    s1 s0 xor to s1
    s0 26 rshift s1 xor to s1
    s1 to state1
    state0 state1 +
;
[else]
\ SwiftForth i386-Linux 3.5.7 22-Jan-2015
: xorshift128+ ( -- n )
    state0 state1 locals| s0 s1 |
    s0 to state0
    s1 23 lshift s1 xor to s1
    s1 17 rshift s1 xor to s1
    s1 s0 xor to s1
    s0 26 rshift s1 xor to s1
    s1 to state1
    state0 state1 +
;
[then]

[then]

: test ( -- )
    1 to state0
    2 to state1
    start-timer
    10000000 0 ?do
        xorshift128+ drop
    loop
    .elapsed
    cr ." state0 = " state0 u.
    cr ." state1 = " state1 u.
;
