\ Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

\ This program is free software: you can redistribute it and/or modify
\ it under the terms of the GNU General Public License as published by
\ the Free Software Foundation, either version 3 of the License, or
\ (at your option) any later version.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
\ GNU General Public License for more details.

\ You should have received a copy of the GNU General Public License
\ along with this program.  If not, see <http://www.gnu.org/licenses/>.

forth!

[undefined] disassembler [if] vocabulary disassembler [then]

[defined] see [if] warning off [then]   \ temporary

[undefined] x86-64 [if] include-system-file x86-64.forth [then]

forth! x86-64 also disassembler definitions

decimal

: find-code-in-wordlist ( code-addr wid -- nfa | 0 )
    local wid
    local code-addr
    wid @ dup if
        begin                           \ -- nfa
            dup name>code code-addr = if
                exit
            then                        \ -- nfa
            name>link @ dup 0=
        until
    then ;

: find-code ( code-addr -- nfa | 0 )
   >r                                   \ --            r: -- code-addr
   voclink @                            \ -- wid        r: -- code-addr
   begin
      r@ over find-code-in-wordlist
      ?dup if
         rdrop
         nip
         exit
      then
      wid>link @ dup 0=
   until
   rdrop ;

0 value start-address
0 value end-address
0 value #insts
0 value instruction-start
0 value ip
0 value prefix
0 value operand-size-prefix
0 value opcode
0 value modrm-byte
0 value sib-byte

0 value size

variable done?

: .sep  ( -- )  ." , " ;

\ REVIEW Forth also defines >POS (io.asm)
: >pos ( u -- )
    #out 1+ over u> if cr then
    #out - 1 max spaces
;

0 value mnemonic

: .bytes ( u -- )
   ?dup if
      instruction-start swap bounds do i c@ .hexbyte space loop
   then ;

: next-byte ( -- byte )
    ip c@
    1 +to ip ;

: next-signed-byte ( -- signed-byte )
    ip c@s
    1 +to ip ;

: next-uint16 ( -- int16 )
    ip w@
    2 +to ip ;

: next-int32 ( -- int32 )
    ip l@s
    4 +to ip ;

: next-uint32 ( -- uint32 )
    ip l@
    4 +to ip ;

: next-uint64 ( -- uint64 )
    ip @
    8 +to ip ;

: (modrm-mod)  ( modrm-byte -- mod )  %11000000 and 6 rshift ;
: (modrm-reg)  ( modrm-byte -- reg )  %00111000 and 3 rshift ;
: (modrm-rm)   ( modrm-byte -- rm  )  %00000111 and ;

0 value modrm-mod
0 value modrm-reg
0 value modrm-rm

\ REGOP is a synonym of MODRM-REG
0 value regop   \ REGister or OPcode extension (depending on the instruction)

: !modrm-byte ( -- )
    next-byte dup to modrm-byte
    dup (modrm-mod) to modrm-mod
    dup (modrm-reg) to modrm-reg
    (modrm-rm) to modrm-rm
    modrm-reg to regop
;

: register-reg ( n1 -- n2 )
    prefix 4 rshift $4 = if
        prefix rex.r and if
            8 or
        then
    then
;

: register-rm ( n1 -- n2 )
    prefix 4 rshift $4 = if
        prefix rex.b and if
            8 or
        then
    then
;

: .2 ( ub -- ) 0 <# # # #>   type ;
: .3 ( ub -- ) 0 <# # # # #> type ;

: .modrm ( modrm-byte -- )
   base@ >r binary
   ?cr ." mod: " dup (modrm-mod) .2 space
   cr  ." reg: " dup (modrm-reg) .3 space
   cr  ."  rm: "      (modrm-rm) .3 space
   r> base!
;

: !sib-byte ( -- ) next-byte to sib-byte ;

: (sib-scale)  ( sib -- scale )  %11000000 and 6 rshift ;
: (sib-index)  ( sib -- index )  %00111000 and 3 rshift ;
: (sib-base)   ( sib -- base  )  %00000111 and ;

: sib-scale  ( -- scale )  sib-byte (sib-scale) ;
: sib-index  ( -- index )  sib-byte (sib-index) ;
: sib-base   ( -- base  )  sib-byte (sib-base)  ;

: .sib  ( sib -- )
   base@ >r binary
   ?cr ." scale: " dup (sib-scale) .2 space
   cr  ." index: " dup (sib-index) .3 space
   cr  ."  base: "     (sib-base)  .3 space
   r> base! ;

create reg8-names 4 cells allot         \ REVIEW 4

: init-reg8-names ( -- )
    "al" reg8-names 0 cells + !
    "cl" reg8-names 1 cells + !
    "dl" reg8-names 2 cells + !
    "bl" reg8-names 3 cells + !
;

init-reg8-names

: reg8-name ( register-number -- $addr )
    dup 0 3 between if
        cells reg8-names + @
    else
        drop
        true abort" reg8-name index out of range"
    then
;

create reg16-names 8 cells allot

: init-reg16-names ( -- )
    "ax" reg16-names  0 cells + !
    "cx" reg16-names  1 cells + !
    "dx" reg16-names  2 cells + !
    "bx" reg16-names  3 cells + !
    "sp" reg16-names  4 cells + !
    "bp" reg16-names  5 cells + !
    "si" reg16-names  6 cells + !
    "di" reg16-names  7 cells + !
;

init-reg16-names

: reg16-name ( register-number -- string )
    dup 0 7 between if
        cells reg16-names + @
    else
        drop
        true abort" reg16-name index out of range"
    then
;

create reg32-names 8 cells allot

: init-reg32-names ( -- )
    "eax" reg32-names  0 cells + !
    "ecx" reg32-names  1 cells + !
    "edx" reg32-names  2 cells + !
    "ebx" reg32-names  3 cells + !
    "esp" reg32-names  4 cells + !
    "ebp" reg32-names  5 cells + !
    "esi" reg32-names  6 cells + !
    "edi" reg32-names  7 cells + !
;

init-reg32-names

: reg32-name ( register-number -- $addr )
    dup 0 7 between if
        cells reg32-names + @
    else
        drop
        true abort" reg32-name index out of range"
    then
;

create reg64-names 16 cells allot

: init-reg64-names ( -- )
    "rax" reg64-names  0 cells + !
    "rcx" reg64-names  1 cells + !
    "rdx" reg64-names  2 cells + !
    "rbx" reg64-names  3 cells + !
    "rsp" reg64-names  4 cells + !
    "rbp" reg64-names  5 cells + !
    "rsi" reg64-names  6 cells + !
    "rdi" reg64-names  7 cells + !
    "r8"  reg64-names  8 cells + !
    "r9"  reg64-names  9 cells + !
    "r10" reg64-names 10 cells + !
    "r11" reg64-names 11 cells + !
    "r12" reg64-names 12 cells + !
    "r13" reg64-names 13 cells + !
    "r14" reg64-names 14 cells + !
    "r15" reg64-names 15 cells + !
;

init-reg64-names

: reg64-name ( register-number -- string )
    dup 0 15 between if
        cells reg64-names + @
    else
        cr ." reg64-name register-number = " .
        true abort" reg64-name index out of range"
    then
;

: .register-name ( register-number size -- )
    local size
    local n
    size 64 = if
        n reg64-name .string
        exit
    then
    size 32 = if
        n reg32-name .string
        exit
    then
    size 16 = if
        n reg16-name .string
        exit
    then
    size 8 = if
        n reg8-name .string
        exit
    then
    true abort" .register-name unsupported case"
;

: .reg64  ( +n -- )
    reg64-name .string
;

0 value relative-size                   \ string or 0

: .relative ( base index scale disp -- )
    local disp
    local scale
    local index
    local base

    [ false ] [if]

    relative-size ?dup if
        .string space
        0 to relative-size
    then

    ." [" base .reg64
    index -1 <> if
        ." +"
        index .reg64
    then
    disp if
        disp 0> if
            ." +"
        else
            ." -"
            disp negate to disp
        then
        disp 0 .r
    then
    ." ]"

    [else]
    \ faster!
    260 <sbuf> local buffer

    relative-size ?dup if
        coerce-to-string
        buffer swap sbuf-append-string
        buffer $20 ( space ) sbuf-append-char
        0 to relative-size
    then

    buffer '[' sbuf-append-char
    buffer base reg64-name sbuf-append-string
    index -1 <> if
        buffer '+' sbuf-append-char
        buffer index reg64-name sbuf-append-string
        scale if
            buffer '*' sbuf-append-char
            buffer 1 scale lshift (.) sbuf-append-chars
        then
    then
    disp if
        disp 0> if
            buffer '+' sbuf-append-char
        else
            buffer '-' sbuf-append-char
            disp negate to disp
        then
        buffer disp (.) sbuf-append-chars
    then
    buffer ']' sbuf-append-char

    buffer .string
    buffer ~sbuf

    [then]
;

: .memory-operand ( disp -- )
    relative-size ?dup if
        .string space
        0 to relative-size
    then
    ." [" 0 h.r ." ]"
;

0 value immediate-operand?
0 value immediate-operand
0 value signed?

0 value register-direct?
0 value memory-operand?
-1 value sreg   \ source register
64 value ssize  \ source operand size
-1 value sbase  \ source base register
-1 value sindex \ source index register
 0 value sscale \ source scaling factor
 0 value sdisp  \ source displacement
-1 value dreg   \ destination register
64 value dsize  \ destination operand size
-1 value dbase  \ destination base register
-1 value dindex \ destination index register
 0 value dscale \ destination scaling factor
 0 value ddisp  \ destination displacement

-1 value #operands

: reset-disassembler
    0 to prefix
    0 to operand-size-prefix

    ip to instruction-start
    0 to mnemonic

    false to immediate-operand?
    false to signed?
    false to register-direct?
    false to memory-operand?

    -1 to sreg
    -1 to dreg
    64 to ssize
    64 to dsize
    -1 to sbase
    -1 to dbase
    -1 to sindex
    -1 to dindex
     0 to sscale
     0 to dscale
     0 to sdisp
     0 to ddisp

    -1 to #operands
;

: .mnemonic ( -- )
   mnemonic if
      40 >pos
      mnemonic .string
   then ;

: .instruction-bytes ( -- )
   ip instruction-start - .bytes ;

: .dest ( -- )
    48 >pos
    dreg -1 <> if
        dreg dsize .register-name
        exit
    then
    dbase -1 <> if
        dbase dindex dscale ddisp .relative
        exit
    then
    memory-operand? if
        ddisp .memory-operand
        0 to memory-operand?
        exit
    then
    true abort" .dest"
;

: .source ( -- )
     immediate-operand? if
        .sep
        \ REVIEW
        immediate-operand signed? if . else h. then
        exit
    then
    sbase -1 <> if
        .sep
        sbase sindex sscale sdisp .relative
        exit
    then
    memory-operand? if
        .sep
        sdisp .memory-operand
        exit
    then
    sreg 0>= if
        .sep
        sreg ssize .register-name
        exit
    then
    true abort" .source"
;

: .inst ( -- )
    .instruction-bytes
    .mnemonic
    #operands 0= if
        exit
    then
    .dest
    #operands 1 = if
        exit
    then
    .source
;

create handlers  256 cells allot  handlers 256 cells 0 fill

: handler ( opcode -- handler )    cells handlers + @ ;

: install-handler ( xt opcode -- ) cells handlers + ! ;

: unsupported  ( -- )
    ?cr ." unsupported instruction at " instruction-start h.
    instruction-start 16 dump
    abort ;

: .name ( code-address -- )
    find-code ?dup if 64 >pos .id then ;

: .ip ( -- ) ?cr ip h. ;

: .literal  ( -- )
   .ip
   cell .bytes
   64 >pos
   ." #"
   ip @ dec.
   ip @ h.
   cell +to ip ;

: .call  ( -- )
   "call" to mnemonic
   next-int32 ip + local code-address

   .instruction-bytes
   .mnemonic
   48 >pos
   code-address h.
   code-address .name
;

: .e9  ( -- )
   "jmp" to mnemonic
   next-int32 ip + local code-address
   .instruction-bytes
   .mnemonic
   48 >pos
   code-address h.
;

latest-xt $e9 install-handler

: set-instruction-size ( -- )
    operand-size-prefix $66 = if
        16 dup to dsize to ssize
    else
        prefix $40 and if
            64
        else
            32
        then dup to dsize to ssize
    then
;

: /r-r/m-reg ( -- )
    \ /r
    \ source is r32/64
    \ dest is r/m32/64
    set-instruction-size
    !modrm-byte
    modrm-reg register-reg to sreg
    modrm-mod 0= if
        modrm-rm 4 = if
            !sib-byte
            sib-base 5 = if             \ base == rbp means no base register (when mod == 0)
                next-int32 to ddisp
                true to memory-operand?
                .inst
                exit
            then
        then
        modrm-rm register-rm to dbase
        .inst
        exit
    then
    modrm-mod 1 = if
        next-signed-byte to ddisp
        modrm-rm register-rm to dbase
        modrm-reg register-reg to sreg
        .inst
        exit
    then
    modrm-mod 3 = if
        modrm-rm register-rm to dreg
        modrm-reg register-reg to sreg
        .inst
        exit
    then
    unsupported
;

: /r-reg-r/m ( -- )
    \ /r
    \ source is r/m32/64
    \ dest is r32/64
    set-instruction-size
    !modrm-byte
    modrm-reg register-reg to dreg
    modrm-mod 0= if
        modrm-rm 4 = if
            !sib-byte
            sib-base 4 = if
                sib-byte $24 = if       \ index == rsp means no index
                    sib-base to sbase
                    .inst
                    exit
                then
            then
            sib-base 5 = if             \ base == rbp means no base register (when mod == 0)
                next-int32 to sdisp
                true to memory-operand?
                .inst
                exit
            then
        else
            \ no sib
            modrm-rm register-rm to sbase
            .inst
            exit
        then
    then
    modrm-mod 1 = if
        \ disp8
        modrm-rm 4 = if
            !sib-byte
            next-signed-byte to sdisp
            sib-byte $24 = if
                sib-base to sbase
            else
                sib-base to sbase
                sib-index to sindex
                sib-scale to sscale
            then
        else
            modrm-rm register-rm to sbase
            next-signed-byte to sdisp
        then
        .inst
        exit
    then
    modrm-mod 3 = if
        \ register-direct
        modrm-rm register-rm to sreg
        .inst
        exit
    then
    unsupported
;

: .00 ( -- )
    "add" to mnemonic
    \ source is r8
    \ dest is r/m8
    !modrm-byte
    modrm-reg to sreg
    8 to ssize
    modrm-mod 0= if
        modrm-rm register-rm to dbase
        "byte" to relative-size       \ REVIEW
        .inst
        exit
    then
    modrm-mod 1 = if
        \ 1-byte displacement
        modrm-rm register-rm to dbase
        next-signed-byte to ddisp
        .inst
        exit
    then
    unsupported
;

latest-xt $00 install-handler

: .01 ( -- )                            \ ADD reg/mem64, reg64
    "add" to mnemonic
    /r-r/m-reg
;

latest-xt $01 install-handler

\ $03 handler
: .03 ( -- )                            \ ADD reg64, reg/mem64
    \ /r
    \ source is r/m32/64
    \ dest is r32/64
    "add" to mnemonic
    /r-reg-r/m
;

latest-xt $03 install-handler

: .09 ( -- )
    \ /r
    \ ModR/M byte contains both a register and an r/m operand
    \ source is r32/64
    \ dest is r/m32/64
    !modrm-byte
    "or" to mnemonic
    modrm-mod 3 = if
        \ register-direct
        modrm-reg register-reg to sreg
        modrm-rm  register-rm  to dreg
        .inst
        exit
    then
    unsupported
;

latest-xt $09 install-handler

: .0b ( -- )
    \ /r
    \ ModR/M byte contains both a register and an r/m operand
    \ source is r/m32/64
    \ dest is r32/64
    "or" to mnemonic
    /r-reg-r/m
;

latest-xt $0b install-handler

: .jcc32 ( $mnemonic -- )
    to mnemonic
    next-int32 ip + local jump-target

\     jump-target to immediate-operand
\     true to immediate-operand?
\     1 to #operands

\     .inst
\     ip +                \ jump target

    .instruction-bytes
    .mnemonic
    48 >pos jump-target h.

    jump-target end-address > if
        jump-target to end-address
    then
\     h.
;

create cmovcc-mnemonic-table 16 cells allot

: initialize-cmovcc-mnemonic-table ( -- )
    cmovcc-mnemonic-table local t
    "cmovo"  t  0 cells +  !
    "cmovno" t  1 cells +  !
    "cmovc"  t  2 cells +  !
    "cmovnc" t  3 cells +  !
    "cmovz"  t  4 cells +  !
    "cmovnz" t  5 cells +  !
    "cmovna" t  6 cells +  !
    "cmova"  t  7 cells +  !
    "cmovs"  t  8 cells +  !
    "cmovns" t  9 cells +  !
    "cmovpe" t 10 cells +  !
    "cmovpo" t 11 cells +  !
    "cmovl"  t 12 cells +  !
    "cmovge" t 13 cells +  !
    "cmovle" t 14 cells +  !
    "cmovg"  t 15 cells +  !
;

: cmovcc-mnemonic ( byte2 -- )
    $0f and cells cmovcc-mnemonic-table + @
;

initialize-cmovcc-mnemonic-table

create setcc-mnemonic-table 16 cells allot

: initialize-setcc-mnemonic-table ( -- )
    setcc-mnemonic-table local t
    "seto"  t  0 cells +  !
    "setno" t  1 cells +  !
    "setc"  t  2 cells +  !
    "setnc" t  3 cells +  !
    "setz"  t  4 cells +  !
    "setnz" t  5 cells +  !
    "setna" t  6 cells +  !
    "seta"  t  7 cells +  !
    "sets"  t  8 cells +  !
    "setns" t  9 cells +  !
    "setpe" t 10 cells +  !
    "setpo" t 11 cells +  !
    "setl"  t 12 cells +  !
    "setge" t 13 cells +  !
    "setle" t 14 cells +  !
    "setg"  t 15 cells +  !
;

initialize-setcc-mnemonic-table

: setcc-mnemonic ( byte2 -- )
    $0f and cells setcc-mnemonic-table + @
;

: .0f ( -- )
    next-byte local byte2
    byte2 $f0 and $40 = if
        byte2 cmovcc-mnemonic to mnemonic
        !modrm-byte
        modrm-mod 3 = if
            modrm-rm register-rm to sreg
            modrm-reg register-reg to dreg
            .inst
        else
            unsupported
        then
        exit
    then
    byte2 $31 = if
        "rdtsc" to mnemonic
        0 to #operands
        .inst
        exit
    then
    byte2 $81 = if
        "jno" .jcc32
        exit
    then
    byte2 $84 = if
        "jz" .jcc32
        exit
    then
    byte2 $85 = if
        "jne" .jcc32
        exit
    then
    byte2 $8d = if
        "jge" .jcc32
        exit
    then
    byte2 $f0 and $90 = if
        byte2 setcc-mnemonic to mnemonic
        !modrm-byte
        modrm-mod 3 = if
            modrm-rm to dreg
            8 to dsize
            1 to #operands
            .inst
            exit
        then
        unsupported
    then
    byte2 $af = if
        "imul" to mnemonic
        /r-reg-r/m
        exit
    then
    byte2 $b6 = if
        \ ModR/M byte contains both a register and an r/m operand
        \ source is r/m8
        \ dest is r32/64
        "movzx" to mnemonic
        !modrm-byte
        modrm-mod 0= if
            modrm-rm register-rm to sbase
            modrm-reg register-reg to dreg
            "byte" to relative-size
            .inst
            exit
        then
        modrm-mod 1 = if
            modrm-rm register-rm to sbase
            next-signed-byte to sdisp
            modrm-reg register-reg to dreg
            "byte" to relative-size
            .inst
            exit
        then
        modrm-mod 3 = if
            true to register-direct?
            modrm-rm register-rm to sreg
            8 to ssize
            modrm-reg register-reg to dreg
            prefix if 64 else 32 then to dsize
            .inst
            exit
        then
    then
    byte2 $b7 = if
        \ ModR/M byte contains both a register and an r/m operand
        \ source is r/m16
        \ dest is r32/64
        "movzx" to mnemonic
        !modrm-byte
        modrm-mod 0= if
            modrm-rm register-rm to sbase
            modrm-reg register-reg to dreg
            "word" to relative-size
            .inst
            exit
        then
        modrm-mod 1 = if
            modrm-rm register-rm to sbase
            next-signed-byte to sdisp
            modrm-reg register-reg to dreg
            "word" to relative-size
            .inst
            exit
        then
        modrm-mod 3 = if
            true to register-direct?
            modrm-rm register-rm to sreg
            16 to ssize
            modrm-reg register-reg to dreg
            .inst
            exit
        then
    then
    byte2 $be = if
        "movsx" to mnemonic
        !modrm-byte
        modrm-mod 0= if
            modrm-rm register-rm to sbase
            8 to ssize
            "byte" to relative-size   \ REVIEW shouldn't need to do this if we've set ssize
            modrm-rm register-reg to dreg
            .inst
            exit
        then
        modrm-reg to sreg
        8 to ssize
        modrm-rm register-rm to dreg
        .inst
        exit
    then
    byte2 $bf = if
        "movsx" to mnemonic
        !modrm-byte
        modrm-mod 0= if
            modrm-rm register-rm to sbase
            16 to ssize
            "word" to relative-size   \ REVIEW shouldn't need to do this if we've set ssize
            modrm-rm register-reg to dreg
            .inst
            exit
        then
        modrm-reg to sreg
        16 to ssize
        modrm-rm register-rm to dreg
        .inst
        exit
    then
    unsupported ;

latest-xt $0f install-handler

: .push  ( -- )
    "push" to mnemonic
    opcode $50 - register-rm to dreg
    1 to #operands
    .inst
;

: .pop  ( -- )
    "pop" to mnemonic
    opcode $58 - register-rm to dreg
    1 to #operands
    .inst
;

: .ret  ( -- )
   "ret" to mnemonic
   0 to #operands
   .inst
   ip end-address > if
      ip to end-address
      done? on
   then ;

: .13 ( -- )
    \ /r
    \ source is r/m32/64
    \ dest is r32/64
    "adc" to mnemonic
    /r-reg-r/m
;

latest-xt $13 install-handler

: .19 ( -- )
   "sbb" to mnemonic
   /r-r/m-reg
;

latest-xt $19 install-handler

: .1b ( -- )
    \ /r
    \ source is r/m32/64
    \ dest is r32/64
    "sbb" to mnemonic
    /r-reg-r/m
;

latest-xt $1b install-handler

: .23 ( -- )
    \ /r
    \ source is r/m32/64
    \ dest is r32/64
    "and" to mnemonic
    /r-reg-r/m
;

' .23 $23 install-handler

\ $29 handler
: .29 ( -- )
    "sub" to mnemonic
    /r-r/m-reg
;

latest-xt $29 install-handler

: .2b ( -- )
    \ /r
    \ dest is r32/64
    \ source is r/m32/64
    "sub" to mnemonic
    /r-reg-r/m
;

latest-xt $2b install-handler

: .30 ( -- )
    \ source r8
    \ dest r/m8
    "xor" to mnemonic
    !modrm-byte
    modrm-mod 3 = if
        true to register-direct?
        modrm-rm to sreg
        8 to ssize
        modrm-reg to dreg
        8 to dsize
        .inst
        exit
    then
    unsupported
;

latest-xt $30 install-handler

: .31 ( -- )
   "xor" to mnemonic
   /r-r/m-reg
;

latest-xt $31 install-handler

: .33 ( -- )
    "xor" to mnemonic
    /r-reg-r/m
;

latest-xt $33 install-handler

: .38 ( -- )                            \ CMP r/m8, r8                  38 /r
    \ /r
    \ dest is r/m8
    \ source is r8
    "cmp" to mnemonic
    !modrm-byte
    modrm-mod 0= if
        modrm-rm register-rm to dbase
        modrm-reg register-reg to sreg
        8 to ssize
        .inst
        exit
    then
    modrm-mod 3 = if
        modrm-rm register-rm to dreg
        8 to dsize
        modrm-reg register-reg to sreg
        8 to ssize
        .inst
        exit
    then
    unsupported
;

latest-xt $38 install-handler

: .39 ( -- )                            \ CMP r/m64, r64                39 /r
    \ /r
    \ dest is r/m32/64
    \ source is r32/64
    "cmp" to mnemonic
    /r-r/m-reg
;

latest-xt $39 install-handler

\ $3b handler
: .3b ( -- )
    "cmp" to mnemonic
    \ /r
    \ source is r/m32/64
    \ dest is r32/64
    /r-reg-r/m
;

latest-xt $3b install-handler

: .3c ( -- )                            \ cmp al, imm8
    "cmp" to mnemonic
    ip c@                               \ -- imm8
    1 +to ip
    .instruction-bytes
    .mnemonic
    48 >pos
    ." al, " h.
;

latest-xt $3c install-handler

: .63 ( -- )
    \ /r
    \ source is r/m32
    \ dest is r32/64
    "movsx" to mnemonic
    !modrm-byte
    modrm-reg register-reg to dreg
    modrm-rm  register-rm  to sbase
    "dword" to relative-size
    .inst
;

latest-xt $63 install-handler

: jmp/jcc-rel8 ( $mnemonic -- )
    to mnemonic
    next-signed-byte ip + local jump-target
    .instruction-bytes
    .mnemonic
    48 >pos jump-target h.
    jump-target end-address > if
        jump-target to end-address
    then
;

: .70 ( -- ) "jo"  jmp/jcc-rel8 ; latest-xt $70 install-handler
: .71 ( -- ) "jno" jmp/jcc-rel8 ; latest-xt $71 install-handler
: .72 ( -- ) "jc"  jmp/jcc-rel8 ; latest-xt $72 install-handler
: .73 ( -- ) "jnc" jmp/jcc-rel8 ; latest-xt $73 install-handler
: .74 ( -- ) "jz"  jmp/jcc-rel8 ; latest-xt $74 install-handler
: .75 ( -- ) "jne" jmp/jcc-rel8 ; latest-xt $75 install-handler
: .76 ( -- ) "jna" jmp/jcc-rel8 ; latest-xt $76 install-handler
: .77 ( -- ) "ja"  jmp/jcc-rel8 ; latest-xt $77 install-handler
: .78 ( -- ) "js"  jmp/jcc-rel8 ; latest-xt $78 install-handler
: .79 ( -- ) "jns" jmp/jcc-rel8 ; latest-xt $79 install-handler
: .7a ( -- ) "jpe" jmp/jcc-rel8 ; latest-xt $7a install-handler
: .7b ( -- ) "jpo" jmp/jcc-rel8 ; latest-xt $7b install-handler
: .7c ( -- ) "jl"  jmp/jcc-rel8 ; latest-xt $7c install-handler
: .7d ( -- ) "jge" jmp/jcc-rel8 ; latest-xt $7d install-handler
: .7e ( -- ) "jle" jmp/jcc-rel8 ; latest-xt $7e install-handler
: .7f ( -- ) "jg"  jmp/jcc-rel8 ; latest-xt $7f install-handler

: mnemonic-from-regop ( -- $addr )
    opcode $80 $83 between if
        regop
        case
            0 of "add" endof
            1 of "or"  endof
            2 of "adc" endof
            3 of "sbb" endof
            4 of "and" endof
            5 of "sub" endof
            6 of "xor" endof
            7 of "cmp" endof
        endcase
        exit
    then
    opcode $c0 $c1 between
    opcode $d0 $d3 between or if
        regop
        case
            0 of "rol" endof
            1 of "ror" endof
            2 of "rcl" endof
            3 of "rcr" endof
            4 of "shl" endof
            5 of "shr" endof
            6 of "shl" endof
            7 of "sar" endof
        endcase
        exit
    then
    opcode $f6 $f7 between if
        regop
        case
            0 of "test" endof
            1 of "test" endof
            2 of "not"  endof
            3 of "neg"  endof
            4 of "mul"  endof
            5 of "imul" endof
            6 of "div"  endof
            7 of "idiv" endof
        endcase
        exit
    then
    true abort" mnemonic-from-regop unsupported opcode"
;

: .80 ( -- )
    \ modrm-reg encodes opcode extension
    \ source is imm8
    \ dest is r/m8
    !modrm-byte
    mnemonic-from-regop to mnemonic

    modrm-mod 0= if
        modrm-rm register-rm to dbase
        "byte" to relative-size
        next-byte to immediate-operand
        true to immediate-operand?
        .inst
        exit
    then

    modrm-mod 1 = if
        modrm-rm 4 = if
            !sib-byte
            sib-index 4 <>
            sib-base 5 <> and if
                sib-scale 0= if
                    sib-base to dbase
                    sib-index to dindex
                    next-signed-byte to ddisp
                    next-byte to immediate-operand
                    true to immediate-operand?
                    .inst
                    exit
                then
            then
        else
            modrm-rm register-rm to dbase
            next-signed-byte to ddisp
            next-byte to immediate-operand
            true to immediate-operand?
            .inst
            exit
        then
    then

    modrm-mod 3 = if
        \ register-direct
        modrm-rm to dreg
        8 to dsize
        next-byte to immediate-operand
        true to immediate-operand?
        .inst
        exit
    then

    unsupported
;

' .80 $80 install-handler

: .81 ( -- )
    \ modrm-reg encodes opcode extension
    \ source is imm32
    \ dest is r/m32/64
    set-instruction-size
    !modrm-byte
    mnemonic-from-regop to mnemonic
    modrm-mod 3 = if
        \ register-direct addressing mode
        modrm-rm register-rm to dreg
        next-int32 to immediate-operand
        true to immediate-operand?
        true to signed?
        .inst
        exit
    then
    unsupported
;

latest-xt $81 install-handler

: .83 ( -- )
    \ modrm-reg encodes opcode extension
    \ source is imm8
    \ dest is r/m32/64
    set-instruction-size
    !modrm-byte
    mnemonic-from-regop to mnemonic
    modrm-mod 1 = if
        \ register-indirect addressing mode
        modrm-reg 0= if
            \ /0
            \ add r/m32,imm8
            modrm-rm register-rm to dbase
            next-signed-byte to ddisp
            "qword" to relative-size
            \ source is imm8
            true to immediate-operand?
            next-byte to immediate-operand
            .inst
            exit
        then
    then
    modrm-mod 3 = if
        \ register-direct addressing mode
        modrm-rm register-rm to dreg
        next-signed-byte to immediate-operand
        true to immediate-operand?
        true to signed?
        .inst
        exit
    then

    unsupported
;

latest-xt $83 install-handler

: .84 ( -- )
    \ /r
    \ source is r8
    \ dest is r/m8
    "test" to mnemonic
    !modrm-byte
    modrm-mod 3 = if
        true to register-direct?
        modrm-reg to sreg
        8 to ssize
        modrm-rm to dreg
        8 to dsize
        .inst
        exit
    then
    unsupported
;

latest-xt $84 install-handler

: .85  ( -- )
    \ /r
    \ source is r32/64
    \ dest is r/m32/64
    "test" to mnemonic
    /r-r/m-reg
;

latest-xt $85 install-handler

: .88 ( -- )                            \ MOV reg/mem8, reg8            88 /r
    "mov" to mnemonic
    !modrm-byte
    modrm-reg to sreg
    8 to ssize
    modrm-mod 0= if
        modrm-rm to dbase
        8 to dsize
        .inst
        exit
    then
    modrm-mod 1 = if                    \ 1-byte displacement
        next-signed-byte to ddisp
        modrm-rm register-rm to dbase
        .inst
        exit
    then
    modrm-mod 3 = if
        modrm-rm to dreg
        8 to dsize
        modrm-reg to sreg
        8 to ssize
        .inst
        exit
    then
    unsupported
;

latest-xt $88 install-handler

: .89 ( -- )
    \ /r
    \ source is r32/64
    \ dest is r/m32/64
    "mov" to mnemonic
    /r-r/m-reg
;

: .8a ( -- )                            \ MOV reg8, reg/mem8            8a /r
    \ /r
    \ source is r/m8
    \ dest is r8
    "mov" to mnemonic
    !modrm-byte
    modrm-reg to dreg
    8 to dsize
    modrm-mod 0= if
        modrm-rm register-rm to sbase
        .inst
        exit
    then
    modrm-mod 1 = if                    \ 1-byte displacement
        modrm-rm 4 = if
            !sib-byte
            sib-index 4 <>
            sib-base 5 <> and if
                sib-scale 0= if
                    sib-base to sbase
                    sib-index to sindex
                    next-signed-byte to sdisp
                    .inst
                    exit
                then
            then
        then
        modrm-rm register-rm to sbase
        next-signed-byte to sdisp
        .inst
        exit
    then
    unsupported
;

latest-xt $8a install-handler

: .8b ( -- )
    \ /r
    \ source is r/m32/64
    \ dest is r32/64
    "mov" to mnemonic
    /r-reg-r/m
;

: .8d  ( -- )                           \ LEA reg64, mem
    "lea" to mnemonic
    !modrm-byte
    modrm-reg register-reg to dreg
    modrm-mod 2 = if
        \ disp32
        modrm-rm 4 = if
            !sib-byte
            sib-index 4 =
            sib-base  4 = and
            sib-scale  0= and if
                sib-base register-rm to sbase
                ip l@s to sdisp
                4 +to ip
                .inst
                exit
            then
        then
    then
    modrm-rm 4 = if !sib-byte then
    modrm-mod 1 = if                    \ 1-byte displacement
        modrm-reg register-reg to dreg
        modrm-rm register-rm to sbase
        next-signed-byte to sdisp
        .inst
        exit
    then
    unsupported
;

: .8f ( -- )
    "pop" to mnemonic
    1 to #operands
    !modrm-byte
    regop 0= if
        modrm-mod 0= if
            modrm-rm 4 = if
                !sib-byte
                sib-index 4 = if
                    sib-base 5 = if     \ base == rbp means no base register (when mod == 0)
                        \ [disp32]
                        next-int32 to ddisp
                        true to memory-operand?
                        .inst
                        exit
                    then
                then
            then
        then
        modrm-mod 1 = if
            modrm-rm register-rm to dbase
            next-signed-byte to ddisp
            "qword" to relative-size  \ REVIEW
            .inst
            exit
        then
    then
    unsupported
;

latest-xt $8f install-handler

: .90 ( -- )
   "nop" to mnemonic
   0 to #operands
   .inst
;

latest-xt $90 install-handler

: .99 ( -- )
    prefix if "cqo" else "cdq" then to mnemonic
    0 to #operands
    .inst
;

latest-xt $99 install-handler

: .aa ( -- )
   "stosb" to mnemonic
   0 to #operands
   .inst
;

latest-xt $aa install-handler

: .b8  ( -- )
    \ source is imm32/64
    \ dest is r32/64
    "mov" to mnemonic
    opcode $b8 - to dreg
    prefix if
\         ip @ cell +to ip
        next-uint64
    else
\         ip l@ 4 +to ip
        next-uint32
        32 to dsize
    then
    to immediate-operand
    true to immediate-operand?
    .inst
;

:noname $b8 8 bounds do ['] .b8 i install-handler loop ; execute

: .c1 ( -- )
    \ modrm-reg encodes opcode extension
    \ source is imm8
    \ dest is r/m32/64
    !modrm-byte
    mnemonic-from-regop to mnemonic
    modrm-mod 3 = if
        \ direct-mode register addressing
        true to register-direct?
        modrm-rm register-rm to dreg
        true to immediate-operand?
        ip c@s to immediate-operand
        1 +to ip
        .inst
        exit
    then
    unsupported
;

' .c1 $c1 install-handler

: .c6 ( -- )
    \ /0
    \ source is imm8
    \ dest is r/m8
    !modrm-byte
    "mov" to mnemonic
    modrm-reg 0= if
        modrm-mod 1 = if
            \ [r/m + disp8]
            modrm-rm register-rm to dbase
            "byte" to relative-size
            next-signed-byte to ddisp
            next-byte to immediate-operand
            true to immediate-operand?
            .inst
            exit
        then
    then
    unsupported
;

latest-xt $c6 install-handler

: .c7 ( -- )
    \ /0
    \ Move a 32-bit signed immediate value to a 64-bit register
    \ or memory operand.
    !modrm-byte
    regop 0= if                         \ /0
        "mov" to mnemonic
        modrm-mod 0= if
            modrm-rm 4 = if
                !sib-byte
                sib-base 5 = if         \ no base register (when mod == 0)
                    \ [disp32]
                    next-int32 to ddisp
                    true to memory-operand?
                    "qword" to relative-size
                    next-uint32 to immediate-operand
                    true to immediate-operand?
                    .inst
                    exit
                then
            then
        then
        modrm-mod 0= if
            modrm-rm register-rm to dbase
            operand-size-prefix $66 = if
                "word" to relative-size
                next-uint16 to immediate-operand
            else
                "qword" to relative-size
                next-int32 to immediate-operand
            then
            true to immediate-operand?
            .inst
            exit
        then
        modrm-mod 1 = if
            \ [r/m + disp8]
            modrm-rm register-rm to dbase
            "qword" to relative-size
            next-signed-byte to ddisp
            next-int32 to immediate-operand
            true to immediate-operand?
            .inst
            exit
        then
        modrm-mod 3 = if
            modrm-rm register-rm to dreg
            next-int32 to immediate-operand
            true to immediate-operand?
            .inst
            exit
        then
    then
    unsupported
;

latest-xt $c7 install-handler

: .c9 ( -- )
    "leave" to mnemonic
    1 to #operands
    .inst
;

latest-xt $c9 install-handler

: .cc ( -- )
    "int3" to mnemonic
    0 to #operands
    .inst
;

latest-xt $cc install-handler

: .cd ( -- )
    "int" to mnemonic
    0 to #operands
    ip c@
    1 +to ip
    .inst
    48 >pos .
;

latest-xt $cd install-handler

: .d1 ( -- )
    !modrm-byte
    mnemonic-from-regop to mnemonic
    modrm-mod 1 = if
        \ 1-byte displacement
        modrm-rm register-rm to dbase
        next-signed-byte to ddisp
        "qword" to relative-size
        1 to immediate-operand
        true to immediate-operand?
        .inst
        exit
    then
    modrm-mod 3 = if
        \ register-direct
        modrm-rm register-rm to dreg
        1 to immediate-operand
        true to immediate-operand?
        .inst
        exit
    then
    unsupported
;

latest-xt $d1 install-handler

: .d3 ( -- )
    \ dest is r/m32/64
    \ source is cl register
    !modrm-byte
    mnemonic-from-regop to mnemonic
    modrm-mod 3 = if
        \ register-direct
        modrm-rm register-rm to dreg
        1 ( cl ) to sreg
        8 to ssize
        .inst
        exit
    then
    unsupported
;

latest-xt $d3 install-handler

: .e2 ( -- )
   "loop" to mnemonic
   ip c@s
   1 +to ip
   ip + local code-address

   .instruction-bytes
   .mnemonic
   48 >pos
   code-address h.
;

latest-xt $e2 install-handler

: .e3 ( -- )
    \ jump short if rcx == 0
    "jrcxz" to mnemonic
    ip c@s                              \ --
    1 +to ip
    ip + local target
    ip instruction-start - .bytes
    40 >pos ." jrcxz"
    48 >pos target h.
;

latest-xt $e3 install-handler

: .eb ( -- ) "jmp" jmp/jcc-rel8 ; latest-xt $eb install-handler

: .f3 ( -- )
    ip c@ local byte2
    1 +to ip
    ip instruction-start - .bytes
    40 >pos ." repz"
    byte2 $a4 = if
        48 >pos ." movsb"
        exit
    then
    byte2 $a6 = if
        48 >pos ." cmpsb"
        exit
    then
    byte2 $aa = if
        48 >pos ." stosb"
        exit
    then
    unsupported
;

latest-xt $f3 install-handler

: .f6 ( -- )
    !modrm-byte
    mnemonic-from-regop to mnemonic
    modrm-reg 0= if
        \ TEST r/m8, imm8
        modrm-mod 1 = if
            modrm-rm register-rm to dbase
            next-signed-byte to ddisp
            next-byte to immediate-operand
            true to immediate-operand?
            8 to dsize
            .inst
            exit
        then
    else
        modrm-rm to dreg
        8 to dsize
        1 to #operands
        .inst
        exit
    then
    unsupported
;

latest-xt $f6 install-handler

: .f7 ( -- )
    !modrm-byte
    mnemonic-from-regop to mnemonic
    regop 1 > if
        \ everything but TEST
        1 to #operands
    then
    regop 4 7 between if
        \ MUL IMUL DIV IDIV
        modrm-mod 1 = if
            \ disp8
            next-signed-byte to ddisp
            modrm-rm register-rm to dbase
            "qword" to relative-size
            .inst
            exit
        then
        modrm-mod 3 = if
            \ register-direct
            modrm-rm register-rm to dreg
        then
    then
    modrm-mod 3 = if
        \ register-direct
        modrm-rm register-rm to dreg
        regop 0= if
            next-int32 to immediate-operand
            true to immediate-operand?
        then
        .inst
        exit
    then
    unsupported
;

latest-xt $f7 install-handler

: .fc ( -- )
   ip instruction-start - .bytes
   48 >pos ." cld"
;

latest-xt $fc install-handler

: .fd ( -- )
   ip instruction-start - .bytes
   48 >pos ." std"
;

latest-xt $fd install-handler

: .ff ( -- )
    !modrm-byte

    regop
    case
        0 of "inc"  endof
        1 of "dec"  endof
        2 of "call" endof
        4 of "jmp"  endof
        6 of "push" endof
    endcase
    to mnemonic

    1 to #operands

    modrm-mod 0= if
        modrm-rm 4 = if
            !sib-byte
            sib-index 4 = if
                sib-base 4 = if         \ base == rsp means no index
                    modrm-rm register-rm to dbase
                    .inst
                    exit
                then
                sib-base 5 = if         \ base == rbp means no base register (when mod == 0)
                    \ [disp32]
                    next-int32 to ddisp
                    true to memory-operand?
                    .inst
                    exit
                then
            then
        else
            modrm-rm register-rm to dbase
            .inst
            exit
        then
    then

    modrm-mod 1 = if
        \ disp8
        modrm-rm register-rm to dbase
        ip c@s to ddisp
        1 +to ip
        .inst
        exit
    then

    modrm-mod 3 = if
        \ register-direct addressing mode
        modrm-rm register-rm to dreg
        .inst
        exit
    then

    unsupported
;

latest-xt $ff install-handler

hex
' .call e8 install-handler
' .ret  c3 install-handler
:noname 50 8 bounds do ['] .push i install-handler loop ; execute
:noname 58 8 bounds do ['] .pop i install-handler loop ; execute
' .89   89 install-handler
' .8b   8b install-handler
' .8d   8d install-handler
decimal

: .opcode  ( -- )
   opcode handler ?dup
   if
      execute
   else
      prefix if 2 else 1 then .bytes
      unsupported
  then ;

: decode  ( -- )                        \ decode one instruction
    reset-disassembler
    .ip
    ip c@ local byte
    byte $66 = if
        byte to operand-size-prefix
        1 +to ip
        ip c@ to byte
    then
    byte $40 $4f between
    if
        byte to prefix
        ip 1+ c@ to opcode
        2 +to ip
    else
        byte to opcode
        0 to prefix
        1 +to ip
    then
    .opcode
    1 +to #insts
;

: disasm  ( code-addr -- )
    dup to start-address to ip
    0 to end-address
    0 to #insts
    done? off
    begin
        done? @ 0=
    while
        decode
    repeat
    ?cr
    #insts dec. ." instructions "
    end-address start-address - dec. ." bytes" ;

: disassemble  ( xt -- )
    >code disasm ;

also forth definitions

synonym .modrm .modrm

synonym disasm disasm

: see  ( "<spaces>name" -- )
   ' local xt
   cr
   xt >type c@ ?dup if
       case
           tvar   of ." variable " endof
           tvalue of ." value "    endof
           tdefer of
               ." deferred " xt >name .id
               ." is " xt >body @ to xt
           endof
           tconst of ." constant " endof
       endcase
   then
   xt >name ?dup if
       .id
       xt immediate? if
           ." (immediate) "
       then
       xt inline? if
           ." (inlineable) "
       then
       xt >view 2@ ?dup if
           .string ."  line " u.
       else
           drop
       then
   else
       ." [anonymous] "
   then
   xt disassemble ;

\ testing the disassembler

also forth definitions

0 value #words

: dis ( nfa -- flag )
    1 +to #words
    cr #words . dup .id name> disassemble
    key? if key drop key drop then
    true ;

: test-forth ( -- )
    0 to #words
    ['] dis forth-wordlist traverse-wordlist ;

: test-all ( -- )
    0 to #words
    voclink @                           \ -- wid
    begin
        ['] dis over traverse-wordlist
        wid>link @ dup 0=
    until
    drop
    cr #words . ." words" ;

\ end of definitions for testing the disassembler

forth!

warning on                              \ REVIEW
