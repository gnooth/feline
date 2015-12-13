\ Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

only forth

[undefined] disassembler [if] vocabulary disassembler [then]

[defined] see [if] warning off [then]   \ temporary

[undefined] x86-64 [if] include-system-file x86-64.forth [then]

only forth also x86-64 also disassembler definitions

decimal

\ : find-code-in-wordlist  ( code-addr wid -- xt | 0 )
\    swap >r                      \ -- wid        r: -- code-addr
\    @ dup if
\       begin                     \ -- nfa        r: -- code-addr
\          name> dup >code r@ = if
\             r>drop
\             exit
\          then
\          >link @ dup 0=
\       until
\    then
\    r>drop ;

: find-code-in-wordlist  ( code-addr wid -- xt | 0 )
    local wid
    local code-addr
    wid @ dup if
        begin                           \ -- nfa
            name> dup >code code-addr = if
                exit
            then
            >link @ dup 0=
        until
    then
;

: find-code  ( code-addr -- xt | 0 )
   >r                           \ --            r: -- code-addr
   voclink @                    \ -- wid        r: -- code-addr
   begin
      r@ over find-code-in-wordlist
      ?dup if
         r>drop
         nip
         exit
      then
      wid>link @ dup 0=
   until
   r>drop ;


0 value start-address
0 value end-address
0 value #insts
0 value instruction-start
0 value ip
0 value prefix
0 value opcode
0 value modrm-byte
0 value sib-byte

0 value size

variable done?
variable literal?

3 constant /operand

: operand-kind      ( operand -- field )            ;
: operand-register  ( operand -- field )      cell+ ;
: operand-data      ( operand -- field )  2 cells + ;

: operand  ( <name> -- )  create /operand cells allot ;

: clear-operand  ( operand -- )  /operand cells erase ;

: operand!  ( kind register data operand -- )
   >r
   r@ operand-data !
   r@ operand-register !
   r> operand-kind ! ;

operand operand1
operand operand2

: source-operand        operand2 ;
: destination-operand   operand1 ;

: source!  ( kind register data -- )  source-operand      operand! ;
: dest!    ( kind register data -- )  destination-operand operand! ;

\ operand kinds
0 constant ok_unknown
1 constant ok_register
2 constant ok_relative
3 constant ok_immediate
4 constant ok_relative_no_reg

: .sep  ( -- )  ." , " ;

\ REVIEW Forth also defines >POS (io.asm)
: >pos ( u -- )
    #out 1+ over u> if cr then
    #out - 1 max spaces
;

\ obsolete
create old-mnemonic  2 cells allot

: old-mnemonic!  ( addr len -- )  old-mnemonic 2! ;
: old-.mnemonic  ( -- )  40 >pos  old-mnemonic 2@ type ;

0 value mnemonic

: .bytes ( u -- )
   ?dup if
      instruction-start swap bounds do i c@ .hexbyte space loop
   then ;

: (modrm-mod)  ( modrm-byte -- mod )  %11000000 and 6 rshift ;
: (modrm-reg)  ( modrm-byte -- reg )  %00111000 and 3 rshift ;
: (modrm-rm)   ( modrm-byte -- rm  )  %00000111 and ;

0 value modrm-mod
0 value modrm-reg
0 value modrm-rm

\ REGOP is a synonym of MODRM-REG
0 value regop   \ REGister or OPcode extension (depending on the instruction)

: !modrm-byte ( -- )
    ip c@ dup to modrm-byte
    1 +to ip
    dup (modrm-mod) to modrm-mod
    dup (modrm-reg) to modrm-reg
    (modrm-rm) to modrm-rm
    modrm-reg to regop
;

: register-reg ( n1 -- n2 )
    prefix rex.r and if
        8 or
    then
;

: register-rm ( n1 -- n2 )
    prefix rex.b and if
        8 or
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

: !sib-byte ( -- )
    ip c@ to sib-byte
    1 +to ip ;

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

: .reg32  ( +n -- )
   s" eaxecxedxebxespebpesiedi"         \ +n addr len
   drop                                 \ +n addr
   swap                                 \ addr +n
   3 * + 3 type ;

create reg64-regs 16 cells allot

: define-reg64                          \ n "spaces<name>" --
    >r
    create
    latest name> reg64-regs r@ cells + !
    r> ,                                \ register number
    latest ,                            \ register name
;

: reg64 ( n -- register )
    dup 0 15 between if
        reg64-regs swap cells + @ execute
    else
        throw                           \ REVIEW
    then ;

create reg8-regs 8 cells allot

: define-reg8                           \ n "spaces<name>" --
    >r
    create
    latest name> reg8-regs r@ cells + !
    r> ,                                \ register number
    latest ,                            \ register name
;

: reg8 ( n -- register )
    dup 0 7 between if
        reg8-regs swap cells + @ execute
    else
        throw                           \ REVIEW
    then ;

 0 define-reg8 al
 1 define-reg8 cl
 2 define-reg8 dl
 3 define-reg8 bl

: register-number ( register -- n )
    @ ;

: register-name ( register -- $addr )
    cell+ @ ;

 0 define-reg64 rax
 1 define-reg64 rcx
 2 define-reg64 rdx
 3 define-reg64 rbx
 4 define-reg64 rsp
 5 define-reg64 rbp
 6 define-reg64 rsi
 7 define-reg64 rdi
 8 define-reg64 r8
 9 define-reg64 r9
10 define-reg64 r10
11 define-reg64 r11
12 define-reg64 r12
13 define-reg64 r13
14 define-reg64 r14
15 define-reg64 r15

: .reg64  ( +n -- )
    prefix $41 = if
        \ extended register
        8 or
    then
    reg64 register-name $.
;

\ FIXME need a consistent interface here
: .reg  ( x -- )
    dup 15 > if
        \ x is address of register structure
        register-name $.
    else
        \ x is register number (can't be address if <= 15)
        prefix $40 and if .reg64 else .reg32 then
    then
;

0 value relative-size                   \ $addr or 0

: .relative  ( reg disp -- )
    relative-size ?dup if
        $. space
        0 to relative-size
    then
    ." [" swap .reg64                   \ -- disp
    ?dup if
        dup 0> if
            ." +"
        else
            ." -"
            abs
        then
        0 .r
    then
    ." ]" ;

: .relative-no-reg ( disp -- )
    ." [" 0 h.r ." ]"
;

0 value immediate-operand?
0 value immediate-operand

0 value register-direct?
-1 value sreg
-1 value dreg

-1 value #operands

: reset-disassembler
    ip to instruction-start
    0 to mnemonic
    operand1 clear-operand
    operand2 clear-operand

    0 to immediate-operand?
    0 to immediate-operand

    false to register-direct?
    -1 to sreg
    -1 to dreg

    -1 to #operands
;

: .operand ( operand -- )
    dup local current-operand
    operand-kind @
    case
        ok_relative of
            current-operand operand-register @
            current-operand operand-data @
            .relative
        endof
        ok_relative_no_reg of
            current-operand operand-data @
            .relative-no-reg
        endof
        ok_register of
            current-operand operand-register @ .reg
        endof
        ok_immediate of
            current-operand operand-data @ h.
        endof
    endcase
;

: .inst ( -- )
   ip instruction-start - .bytes
   mnemonic if
      40 >pos
      mnemonic count type
   then
   #operands 0= if
       exit
   then
   48 >pos
   register-direct? if
       dreg -1 = abort" .inst dreg not set"
       dreg .reg
   else
       destination-operand @ if
           destination-operand .operand
       then
   then
   immediate-operand? if
       .sep
       immediate-operand h.
       exit
   then
\    register-direct? if
       sreg 0>= if
           .sep
           sreg .reg
           exit
       then
\    then
   source-operand @ if
       source-operand operand-kind @ if .sep then
       source-operand .operand
   then
;

create handlers  256 cells allot  handlers 256 cells 0 fill

: handler ( opcode -- handler )    cells handlers + @ ;

: install-handler ( xt opcode -- ) cells handlers + ! ;

: unsupported  ( -- )
    ?cr ." unsupported instruction at " instruction-start h.
    instruction-start 16 dump
    abort ;

: .name  ( code-addr -- )  find-code ?dup if 64 >pos >name count type then ;

: .ip  ( -- )  ?cr ip h. ;

: .literal  ( -- )
   .ip
   cell .bytes
   64 >pos
   ." #"
   ip @ dec.
   ip @ h.
   cell +to ip ;

\ obsolete
: .instruction  ( -- )
   size .bytes
\    ip instruction-start - .bytes
   old-.mnemonic
   48 >pos
\    operand1 ?dup if
\       count type
\    then
\    operand2 ?dup if
\       .sep
\       count type
\    then
;

: .call  ( -- )
   $" call" to mnemonic
   ok_immediate 0 ip l@s
   4 +to ip
   ip + dup local code-address
   dest!
   .inst
   code-address .name
;

: .jmp  ( -- )
   $" jmp" to mnemonic
   ok_immediate 0 ip l@s 4 +to ip ip + dest!
   .inst
;

\ $00 handler
: .00 ( -- )
    $" add" to mnemonic
    \ source is r8
    \ dest is r/m8
    !modrm-byte
    modrm-mod 0 = if
        ok_relative modrm-rm register-rm 0 dest!
        modrm-reg reg8 to sreg
        .inst
        exit
    then
    modrm-mod 1 = if
        \ 1-byte displacement
        ok_relative modrm-rm register-rm ip c@s dest!
        1 +to ip
        modrm-reg reg8 to sreg
        .inst
        exit
    then
    unsupported
;

latest-xt $00 install-handler

\ $01 handler
: .01 ( -- )                            \ ADD reg/mem64, reg64
    $" add" to mnemonic
    !modrm-byte
    modrm-mod 3 <> if
        modrm-rm 4 = if
            !sib-byte
            sib-byte $25 = if
                ok_relative_no_reg 0 ip l@s dest!
                4 +to ip
                ok_register modrm-reg register-reg 0 source!
                .inst
                exit
            then
        then
    then
    modrm-mod 0= if
        ok_relative modrm-rm register-rm 0 dest!
        ok_register modrm-reg register-reg 0 source!
        .inst
        exit
    then
    modrm-mod 1 = if                     \ 1-byte displacement
        ok_relative modrm-rm register-rm ip c@s dest!
        1 +to ip
        ok_register modrm-reg register-reg 0 source!
        .inst
        exit
    then
    modrm-mod 3 = if
        prefix if 3 else 2 then to size
        ok_register modrm-rm register-rm 0 dest!
        ok_register modrm-reg register-reg 0 source!
        .inst
        exit
    then
    prefix if 2 else 1 then to size
    unsupported
    size +to ip ;

latest-xt $01 install-handler

\ $03 handler
: .03 ( -- )                            \ ADD reg64, reg/mem64
    $" add" to mnemonic
    !modrm-byte
    modrm-rm 4 = if
        !sib-byte
        modrm-mod 0= if
            ok_register modrm-reg register-reg 0 dest!
            ok_relative_no_reg 0 ip l@s source!
            4 +to ip
            .inst
            exit
        then
        modrm-mod 1 = if
            ok_register modrm-reg register-reg 0      dest!
            ok_relative modrm-rm  register-rm  ip c@s source!
            1 +to ip
            .inst
            exit
        then
    else
        modrm-mod 1 = if                \ 1-byte displacement
            ok_relative modrm-rm ip c@s source!
            1 +to ip
            ok_register modrm-reg 0 dest!
            .inst
            exit
        then
    then
    ip instruction-start - .bytes
    unsupported
;

latest-xt $03 install-handler

\ $09 handler
: .09 ( -- )
    \ /r
    \ ModR/M byte contains both a register and an r/m operand
    \ source is r/m32/64
    \ dest is r32/64
    !modrm-byte
    $" or" to mnemonic
    modrm-mod 3 = if
        ok_register modrm-rm register-rm 0 dest!
        ok_register modrm-rm register-reg 0 source!
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
    !modrm-byte
    $" or" to mnemonic
    modrm-mod 1 = if
        ok_register modrm-reg register-reg 0      dest!
        ok_relative modrm-reg register-rm  ip c@s source!
        1 +to ip
        .inst
        exit
    then
    unsupported
;

' .0b $0b install-handler

: .jcc32 ( $mnemonic -- )
    to mnemonic
    ip l@s                          \ 32-bit signed offset
    4 +to ip
    5 to size
    .inst
    ip +                \ jump target
    dup end-address > if
        dup to end-address
    then
    h. ;

create cmov-mnemonic-table 16 cells allot

: initialize-cmov-mnemonic-table ( -- )
    cmov-mnemonic-table local t
    $" cmovo"  t  0 cells +  !
    $" cmovno" t  1 cells +  !
    $" cmovc"  t  2 cells +  !
    $" cmovnc" t  3 cells +  !
    $" cmovz"  t  4 cells +  !
    $" cmovnz" t  5 cells +  !
    $" cmovna" t  6 cells +  !
    $" cmova"  t  7 cells +  !
    $" cmovs"  t  8 cells +  !
    $" cmovns" t  9 cells +  !
    $" cmovpe" t 10 cells +  !
    $" cmovpo" t 11 cells +  !
    $" cmovl"  t 12 cells +  !
    $" cmovge" t 13 cells +  !
    $" cmovle" t 14 cells +  !
    $" cmovg"  t 15 cells +  !
;

: cmov-mnemonic ( byte2 -- )
    cmov-mnemonic-table @ 0= if
        initialize-cmov-mnemonic-table
    then
    $0f and cells cmov-mnemonic-table + @
;

: .0f ( -- )
    ip c@ local byte2
    1 +to ip
\     byte2 $4d = if
    byte2 $f0 and $40 = if
\         $" cmovnl" to mnemonic
        byte2 cmov-mnemonic to mnemonic
        !modrm-byte
        modrm-mod 3 = if
            ok_register modrm-rm register-rm 0 source!
            ok_register modrm-reg register-reg 0 dest!
            .inst
        else
            unsupported
        then
        exit
    then
    byte2 $31 = if
        $" rdtsc" to mnemonic
        0 to #operands
        .inst
        exit
    then
    byte2 $84 = if
        $" jz" .jcc32
        exit
    then
    byte2 $81 = if
        $" jno" .jcc32
        exit
    then
    byte2 $8d = if
        $" jge" .jcc32
        exit
    then
    byte2 $9c = if
        $" setl" to mnemonic
        !modrm-byte
        modrm-mod 3 = if
            ok_register modrm-rm reg8 0 dest!
            .inst
            exit
        then
    then
    byte2 $b6 = if
        \ ModR/M byte contains both a register and an r/m operand
        \ source is r/m8
        \ dest is r32/64
        $" movzx" to mnemonic
        !modrm-byte
        modrm-mod 0= if
            ok_relative modrm-rm register-rm 0 source!
            ok_register modrm-reg register-reg 0 dest!
            $" byte" to relative-size
            .inst
            exit
        then
        modrm-mod 1 = if
            ok_relative modrm-rm register-rm ip c@s source!
            1 +to ip
            ok_register modrm-reg register-reg 0 dest!
            $" byte" to relative-size
            .inst
            exit
        then
        modrm-mod 3 = if
            true to register-direct?
            modrm-rm  reg8         to sreg
            modrm-reg register-reg to dreg
            .inst
            exit
        then
    then
    byte2 $be = if
        $" movsx" to mnemonic
        !modrm-byte
        ok_register modrm-reg reg8 0 source!
        ok_register modrm-rm register-rm 0 dest!
        .inst
        exit
    then
    ip instruction-start - .bytes
    unsupported ;

latest-xt $0f install-handler

: .push  ( -- )
    prefix if 2 else 1 then to size
    size .bytes
    40 >pos
    ." push"
    48 >pos
    opcode $50 - .reg64
;

: .pop  ( -- )
    prefix if 2 else 1 then to size
   size .bytes
   40 >pos
   ." pop"
   48 >pos
   opcode $58 - .reg64
;

: .ret  ( -- )
   $" ret" to mnemonic
   0 to #operands
   .inst
   ip end-address > if
      ip to end-address
      done? on
   then ;

\ $19 handler
:noname ( -- )
   c" sbb" to mnemonic
   !modrm-byte
   ok_register modrm-rm 0 dest!
   ok_register modrm-reg 0 source!
   .inst
   prefix if 3 else 2 then to size
;

$19 install-handler

: .23 ( -- )
    \ /r
    \ ModR/M byte contains both a register and an r/m operand
    \ source is r/m32/64
    \ dest is r32/64
    !modrm-byte
    $" and" to mnemonic
    modrm-mod 1 = if
        ok_register modrm-reg register-reg 0      dest!
        ok_relative modrm-reg register-rm  ip c@s source!
        1 +to ip
        .inst
        exit
    then
    unsupported
;

' .23 $23 install-handler

\ $29 handler
: .29 ( -- )
    $" sub" to mnemonic
    \ /r
    \ ModR/M byte contains both a register and an r/m operand
    \ source is r32/64
    \ dest is r/m32/64
    !modrm-byte
    modrm-mod 1 = if
        \ dest is [r/m + disp8]
        modrm-reg register-reg to sreg
        ok_relative modrm-rm register-rm ip c@s dest!
        1 +to ip
        .inst
        exit
    then
    modrm-mod 3 = if
        ok_register modrm-rm register-rm 0 dest!
        ok_register modrm-reg register-reg 0 source!
        .inst
        exit
    then
    prefix if 2 else 1 then to size
    unsupported
    size +to ip ;

latest-xt $29 install-handler

: .30 ( -- )
    \ source r8
    \ dest r/m8
    $" xor" to mnemonic
    !modrm-byte
    modrm-mod 3 = if
        true to register-direct?
        modrm-rm  reg8 to sreg
        modrm-reg reg8 to dreg
        .inst
        exit
    then
    unsupported
;

latest-xt $30 install-handler

\ $31 handler
:noname ( -- )
   $" xor" to mnemonic
   !modrm-byte
   ok_register modrm-rm 0 dest!
   ok_register modrm-reg 0 source!
   .inst
   prefix if 3 else 2 then to size
;

$31 install-handler

\ $39 handler
:noname ( -- )                          \ CMP r/m64, r64                39 /r
    $" cmp" to mnemonic
    !modrm-byte
    modrm-mod 1 = if
        ok_relative modrm-rm ip c@s dest!
        1 +to ip
        ok_register modrm-reg 0 source!
\         prefix if 4 else 3 then to size
        .inst
        exit
    then
    modrm-mod 3 = if
        ok_register modrm-rm register-rm 0 dest!
        ok_register modrm-reg register-reg 0 source!
        .inst
        exit
    then
    unsupported
;

$39 install-handler

\ $3b handler
:noname ( -- )
    $" cmp" to mnemonic
    !modrm-byte
    modrm-mod 1 = if
        ok_relative modrm-rm ip c@s source!
        1 +to ip
        ok_register modrm-reg 0 dest!
        prefix if 4 else 3 then to size
        .inst
        exit
    then
    unsupported
;

$3b install-handler

: .jcc8 ( $mnemonic -- )
    to mnemonic
    ip c@s              \ 8-bit signed offset
    1 +to ip
    2 to size
    .inst
    ip +                \ jump target
    dup end-address > if
        dup to end-address
    then
    h. ;

\ $70 handler
:noname ( -- ) $" jo" .jcc8 ; $70 install-handler

\ $71 handler
:noname ( -- ) $" jno" .jcc8 ; $71 install-handler

\ $74 handler
:noname ( -- ) $" jz" .jcc8 ; $74 install-handler

\ $75 handler
:noname ( -- ) $" jne" .jcc8 ; $75 install-handler

\ $78 handler
:noname ( -- ) $" js" .jcc8 ; $78 install-handler

\ $7c handler
:noname ( -- ) $" jl" .jcc8 ; $7c install-handler

\ $7e handler
:noname ( -- ) $" jle" .jcc8 ; $7e install-handler

\ $7f handler
:noname ( -- ) $" jg" .jcc8 ; $7f install-handler

\ $eb handler
:noname  ( -- )
    s" jmp" old-mnemonic!
    ip c@s  1 +to ip      \ 8-bit signed offset
    2 to size
    .instruction
    ip + dup h.

    \ -- target-address
    dup end-address > if
        to end-address
    else
        drop
    then
;

$eb install-handler

: mnemonic-from-regop ( -- $addr )
    opcode $80 $83 between if
        regop
        case
            0 of $" add" endof
            1 of $" or"  endof
            2 of $" adc" endof
            3 of $" sbb" endof
            4 of $" and" endof
            5 of $" sub" endof
            6 of $" xor" endof
            7 of $" cmp" endof
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

    modrm-mod 0 = if
        ok_relative modrm-rm register-rm 0 dest!
        $" byte" to relative-size
        ok_immediate 0 ip c@ source!
        1 +to ip
        .inst
        exit
    then

    modrm-mod 3 <
    modrm-rm 4 = and if
        !sib-byte
        modrm-mod 1 = if
            break \ FIXME!!
        then
    then

    ok_register modrm-rm reg8 0 dest!
    ok_immediate 0 ip c@ source!
    1 +to ip
    .inst
    exit

    unsupported
;

' .80 $80 install-handler

: .81 ( -- )
    \ modrm-reg encodes opcode extension
    \ source is imm32
    \ dest is r/m32/64
\     regop
\     case
\         0 of $" add" endof
\         1 of $" or"  endof
\         2 of $" adc" endof
\         3 of $" sbb" endof
\         4 of $" and" endof
\         5 of $" sub" endof
\         6 of $" xor" endof
\         7 of $" cmp" endof
\     endcase
    mnemonic-from-regop to mnemonic

    modrm-reg 0= if
        $" add" to mnemonic
        ok_register modrm-rm register-rm 0 dest!
        ok_immediate 0 ip l@ source!
        4 +to ip
        .inst
        exit
    then
    modrm-reg 4 = if
        $" and" to mnemonic
        modrm-mod 3 = if
            \ register-direct addressing mode
            ok_register modrm-rm register-rm 0 dest!
            ok_immediate 0 ip l@ source!
            4 +to ip
            .inst
            exit
        then
    then
    modrm-reg 1 = if
        $" or" to mnemonic
        modrm-mod 3 = if
            \ register-direct addressing mode
            ok_register modrm-rm register-rm 0 dest!
            ok_immediate 0 ip l@ source!
            4 +to ip
            .inst
            exit
        then
    then
    unsupported
;

' .81 $81 install-handler

\ $83 handler
: .83 ( -- )
    \ modrm-reg encodes opcode extension
    \ source is imm8
    \ dest is r/m32/64
    !modrm-byte
\     regop
\     case
\         0 of $" add" endof
\         1 of $" or"  endof
\         2 of $" adc" endof
\         3 of $" sbb" endof
\         4 of $" and" endof
\         5 of $" sub" endof
\         6 of $" xor" endof
\         7 of $" cmp" endof
\     endcase
    mnemonic-from-regop to mnemonic

    modrm-mod 1 = if
        \ register-indirect addressing mode
        modrm-reg 0= if
            \ /0
            \ add r/m32,imm8
\             $" add" to mnemonic
            ok_relative modrm-rm register-rm ip c@s dest!
            $" qword" to relative-size
            1 +to ip
\             ok_immediate 0 ip c@ source!
\             1 +to ip
    \ source is imm8
    true to immediate-operand?
    ip c@s to immediate-operand
    1 +to ip

            .inst
            exit
        then
    then
    modrm-mod 3 = if
        \ register-direct addressing mode
        modrm-reg 0= if
\             s" add" old-mnemonic!
\             prefix if 4 else 3 then to size
\             .instruction
\             modrm-rm .reg64
            ok_register modrm-rm register-rm 0 dest!
\             .sep
\             ip c@s  1 +to ip
\             .
    \ source is imm8
    true to immediate-operand?
    ip c@s to immediate-operand
    1 +to ip

            .inst
            exit
        then
        modrm-reg 5 = if
\             $" sub" to mnemonic
            ok_register modrm-rm register-rm 0 dest!
\             ok_immediate 0 ip c@s source!
\             1 +to ip
    \ source is imm8
    true to immediate-operand?
    ip c@s to immediate-operand
    1 +to ip

            .inst
            exit
        then
        modrm-reg 7 = if
\             s" cmp" old-mnemonic!
\             prefix if 4 else 3 then to size
\             .instruction
\             modrm-rm .reg64
\             .sep
\             ip c@s  1 +to ip
\             .
            ok_register modrm-rm register-rm 0 dest!
            \ source is imm8
            true to immediate-operand?
            ip c@s to immediate-operand
            1 +to ip
            .inst
            exit
        then
    then
    unsupported
;

latest-xt $83 install-handler

: .84 ( -- )
    \ /r
    \ source is r8
    \ dest is r/m8
    $" test" to mnemonic
    !modrm-byte
    modrm-mod 3 = if
        true to register-direct?
        modrm-reg reg8 to sreg
        modrm-rm  reg8 to dreg
        .inst
        exit
    then
    unsupported
;

latest-xt $84 install-handler

: .85  ( -- )
\    ip prefix if 2 else 1 then + c@      \ modrm-byte
   !modrm-byte
   modrm-mod 3 = if                     \ register operands
\       modrm-reg 0= if
         prefix if 3 else 2 then to size
         size .bytes
         s" test" old-mnemonic! old-.mnemonic
         48 >pos
         modrm-reg .reg64 .sep modrm-rm .reg64
\          size +to ip
         exit
\       then
   then
   prefix if 2 else 1 then to size
   size .bytes
   unsupported
   size +to ip ;

\ $88 handler
:noname ( -- )                          \ MOV reg/mem8, reg8            88 /r
    $" mov" to mnemonic
    !modrm-byte
    modrm-mod 0 = if
        ok_register modrm-reg reg8 0 source!
        ok_relative modrm-rm 0 dest!
        .inst
        exit
    then
    modrm-mod 1 = if                    \ 1-byte displacement
        ok_register modrm-reg reg8 0 source!
        ok_relative modrm-rm ip c@s dest!
        1 +to ip
        .inst
        exit
    then
    1 .bytes
    unsupported
;

$88 install-handler

: .89 ( -- )
    \ MOV reg/mem64, reg64
    \ "Move the contents of a 64-bit register to a 64-bit destination register
    \ or memory operand."
    \ 89 /r
    \ "/r: indicates that the ModR/M byte of the instruction contains both a
    \ register operand and an r/m operand."
    $" mov" to mnemonic
    !modrm-byte
    modrm-rm 4 =
    modrm-mod 3 <> and
    if
        !sib-byte
        modrm-mod 0= if
            sib-scale 0= if
                sib-index 4 = if
                    sib-base 5 = if
                        prefix if 7 else 6 then to size
                        ok_register modrm-reg register-reg 0 source!
                        ok_relative_no_reg 0 ip l@s dest!
                        4 +to ip
                        .inst
                        exit
                    else
                        ok_register modrm-reg register-reg 0 source!
                        ok_relative sib-base 0 dest!
                        .inst
                        exit
                    then
                then
            then
        then
    else
        \ no sib byte
        modrm-mod 0= if
            ok_relative modrm-rm register-rm 0 dest!
            ok_register modrm-reg register-reg 0 source!
            .inst
            exit
        then
        modrm-mod 1 = if                     \ 1-byte displacement
            ok_relative modrm-rm register-rm ip c@s dest!
            1 +to ip
            ok_register modrm-reg register-reg 0 source!
            .inst
            exit
        then
        modrm-mod 3 = if                    \ register operands
            prefix if 3 else 2 then to size
            ok_register modrm-reg register-reg 0 source!
            ok_register modrm-rm  register-rm  0 dest!
            .inst
            exit
        then
    then
    ip instruction-start - .bytes
    unsupported
;

\ $8a handler
: .8a ( -- )                            \ MOV reg8, reg/mem8            8a /r
    \ /r
    \ source is r/m8
    \ dest is r8
    $" mov" to mnemonic
    !modrm-byte
    modrm-mod 0= if
        ok_register modrm-reg reg8 0 dest!
        ok_relative modrm-rm register-rm 0 source!
        .inst
        exit
    then
    modrm-mod 1 = if                    \ 1-byte displacement
        ok_register modrm-reg reg8 0 dest!
        ok_relative modrm-rm ip c@s source!
        1 +to ip
        .inst
        exit
    then
    unsupported
;

latest-xt $8a install-handler

: .8b ( -- )
    \ ModR/M byte contains both a register operand and an r/m operand
    \ source is r/m32/64
    \ dest is r32/64
    s" mov" old-mnemonic!
    $" mov" to mnemonic
    !modrm-byte
    modrm-rm 4 <> if
        modrm-mod 0= if
            prefix if 3 else 2 then to size
            ok_register modrm-reg register-reg 0 dest!
            ok_relative modrm-rm register-rm 0 source!
            .inst
            exit
        then
        modrm-mod 1 = if
            ok_register modrm-reg 0 dest!
            ok_relative modrm-rm register-rm ip c@s source!
            1 +to ip
            .inst
            exit
        then
        modrm-mod 3 = if
            ok_register modrm-reg register-reg 0 dest!
            ok_register modrm-rm register-rm 0 source!
            .inst
            exit
        then
    then
    modrm-rm 4 = if
        !sib-byte
        sib-byte   $24 = if
            ok_register modrm-reg register-reg 0 dest!
            ok_relative modrm-rm  register-rm  0 source!
            .inst
            exit
        then
        modrm-mod 0= if
            sib-scale 0= if
                sib-index 4 = if
                    prefix if 7 else 6 then to size
                    ok_register modrm-reg register-reg 0 dest!
                    ok_relative_no_reg 0 ip l@s source!
                    4 +to ip
                    .inst
                    exit
                then
            then
            prefix if 3 else 2 then to size
            size .bytes
            old-.mnemonic
            48 >pos
            modrm-reg .reg64
            .sep
            modrm-rm 0 .relative
            exit
        then
    then
    modrm-mod 1 = if                \ 1-byte displacement
        ok_register modrm-reg 0 dest!
        ok_relative modrm-rm ip c@s source!
        1 +to ip
        .inst
        exit
    then
    1 .bytes
    unsupported
\    1 +to ip
;

: .8d  ( -- )                           \ LEA reg64, mem
\    s" lea" old-mnemonic!
    c" lea" to mnemonic
    !modrm-byte
    modrm-rm 4 = if !sib-byte then
    modrm-mod 1 = if                    \ 1-byte displacement
        ok_register modrm-reg register-reg 0 dest!
        ok_relative modrm-rm register-rm ip c@s source!
        1 +to ip
        .inst
        exit
    then
    ip instruction-start - .bytes
    unsupported
;

: .8f ( -- )
    $" pop" to mnemonic
    !modrm-byte
    modrm-mod 0= if
        modrm-rm 4 = if
            !sib-byte
            sib-index 4 = if
                sib-base 5 = if         \ base == rbp means no base register (when mod == 0)
                    \ [disp32]
                    ok_relative_no_reg 0 ip l@s dest!
                    4 +to ip
                    .inst
                    exit
                then
            then
        then
    then
    modrm-reg 0= if
        ok_relative modrm-rm register-rm ip c@s dest!
        1 +to ip
        .inst
        exit
    then
    ip instruction-start - .bytes
    unsupported
;

' .8f $8f install-handler

:noname  ( -- )
   c" nop" to mnemonic
   .inst ;

$90 install-handler

: .b8  ( -- )
    $" mov" to mnemonic
    prefix if 10 else 5 then to size
    ok_register opcode $b8 - 0 dest!
    ok_immediate 0
    prefix if
        ip @ cell +to ip
    else
        ip l@ 4 +to ip
    then
    source!
    .inst
;

:noname $b8 8 bounds do ['] .b8 i install-handler loop ; execute

: .c1 ( -- )
    \ modrm-reg encodes opcode extension
    \ source is imm8
    \ dest is r/m32/64
    !modrm-byte
    regop
    case
        0 of $" rol" endof
        1 of $" ror"  endof
        2 of $" rcl" endof
        3 of $" rcr" endof
        4 of $" shl" endof
        5 of $" shr" endof
        6 of $" shl" endof              \ REVIEW alias? (not in v8 disassembler)
        7 of $" sar" endof
    endcase
    to mnemonic

    modrm-mod 3 = if
        \ direct-mode register addressing
\         ok_register modrm-rm register-rm 0 dest!
        true to register-direct?
        modrm-rm register-rm to dreg
        true to immediate-operand?
        ip c@s to immediate-operand
        1 +to ip
        .inst
        exit
    then

    modrm-reg 4 = if
        ok_register modrm-rm register-rm 0 dest!
        ok_immediate 0 ip c@ source!
        1 +to ip
        .inst
        exit
    then
    unsupported
;

' .c1 $c1 install-handler

\ $c7 handler
:noname ( -- )
    \ Move a 32-bit signed immediate value to a 64-bit register
    \ or memory operand.
    $" mov" to mnemonic
    !modrm-byte
    modrm-reg 0= if
        modrm-rm 4 = if
            !sib-byte
            sib-base 5 = if             \ no base register (when mod == 0)
                \ [disp32]
                ok_relative_no_reg 0 ip l@s dest!
                4 +to ip
                ok_immediate 0 ip l@s source!
                4 +to ip
                .inst
                exit
            then
        then
        modrm-mod 0 = if
            ok_relative modrm-reg register-reg 0 dest!
            ok_immediate 0 ip l@ source!
            4 +to ip
            .inst
            exit
        then
        modrm-mod 1 = if                \ 1-byte displacement
            ok_relative modrm-rm ip c@s dest!
            1 +to ip
            ok_immediate 0 ip l@s source!
            4 +to ip
            .inst
            exit
        then
        modrm-mod 3 = if
            ok_register modrm-rm register-rm 0 dest!
            ok_immediate 0 ip l@s source!
            4 +to ip
            .inst
            exit
        then
    then
    unsupported
;

$c7 install-handler

:noname ( -- )
    $" leave" to mnemonic
    1 to size
    .inst ;

$c9 install-handler

: .cc ( -- )
    $" int3" to mnemonic
    .inst
;

' .cc $cc install-handler

: .cd ( -- )
    $" int" to mnemonic
    0 to #operands
    ip c@
    1 +to ip
    .inst
    48 >pos .
;

' .cd $cd install-handler

\ $d1 handler
: .d1 ( -- )
    !modrm-byte
    modrm-reg 4 = if
        $" shl" to mnemonic
        ok_register modrm-rm register-rm 0 dest!
        .inst
        exit
    then
    unsupported
;

latest-xt $d1 install-handler

: .e3 ( -- )
    \ jump short if rcx == 0
    $" jrcxz" to mnemonic
    0 ip c@s                            \ --
    1 +to ip
    ip + local target
    ip instruction-start - .bytes
    40 >pos ." jrcxz"
    48 >pos target h.
;

latest-xt $e3 install-handler

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

\ $f6 handler
:noname ( -- )
    !modrm-byte
    modrm-reg 3 = if
        $" neg" to mnemonic
        ok_register modrm-rm reg8 0 dest!
        .inst
        exit
    then
    unsupported
;

$f6 install-handler

\ $f7 handler
:noname ( -- )
    !modrm-byte
    modrm-reg 3 = if
        $" neg" to mnemonic
        prefix if 3 else 2 then to size
        modrm-rm 3 = if
            ok_register modrm-rm register-rm 0 dest!
            .inst
            exit
        then
    then ;

$f7 install-handler

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
        0 of $" inc"  endof
        1 of $" dec"  endof
        2 of $" call" endof
        4 of $" jmp"  endof
        6 of $" push" endof
    endcase
    to mnemonic

    modrm-mod 3 = if
        \ register-direct addressing mode
        ok_register modrm-rm register-rm 0 dest!
        .inst
        exit
    then

    modrm-mod 0= if
        modrm-rm 4 = if
            !sib-byte
            sib-index 4 = if
                sib-base 4 = if         \ base == rsp means no index
                    ok_relative modrm-rm register-rm 0 dest!
                    .inst
                    exit
                then
                sib-base 5 = if         \ base == rbp means no base register (when mod == 0)
                    \ [disp32]
                    ok_relative_no_reg 0 ip l@s dest!
                    4 +to ip
                    .inst
                    exit
                then
            then
        then
    then

    modrm-mod 0 = if
        modrm-reg 4 = if
\             $" jmp" to mnemonic
            ok_relative modrm-rm 0 dest!
            2 to size
            .inst
            exit
        then
    then
    modrm-byte $e0 = if                 \ mod 3
        s" jmp" old-mnemonic!
        2 to size
        .instruction
        ." rax"
        exit
    then
    modrm-reg 0= if
        s" inc" old-mnemonic!
        c" inc" to mnemonic
        modrm-mod 3 = if
            3 to size
            .instruction
            modrm-rm .reg64
            exit
        then
        modrm-mod 0= if
                                        \ INC reg/mem64
\          4 to size
\          2 +to ip
\          .instruction
            !sib-byte
            sib-base 5 = if
                ok_relative_no_reg 0 ip l@s dest!
                4 +to ip
                .inst
                exit
            then
            ip instruction-start - .bytes
            40 >pos ." inc"
            48 >pos ." qword [" modrm-rm .reg64 ." ]"
            exit
        then
    then
    modrm-reg 1 = if
        $" dec" to mnemonic
        prefix if 3 else 2 then to size
        ok_register modrm-rm register-rm 0 dest!
        .inst
        exit
    then
    ip instruction-start - .bytes
    unsupported
;

' .ff $ff install-handler

hex
' .call e8 install-handler
' .jmp  e9 install-handler
' .ret  c3 install-handler
:noname 50 8 bounds do ['] .push i install-handler loop ; execute
\ ' .pop  58 install-handler
\ ' .pop  59 install-handler
\ ' .pop  5a install-handler
\ ' .pop  5b install-handler
\ ' .pop  5d install-handler
:noname 58 8 bounds do ['] .pop i install-handler loop ; execute
' .85   85 install-handler
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
\       prefix if 2 else 1 then +to ip
  then ;

: decode  ( -- )                        \ decode one instruction
    reset-disassembler
    .ip
    ip c@
    dup $40 $4f between if
        to prefix
        ip 1+ c@ to opcode
        2 +to ip
    else
        to opcode
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
   xt >name .id
   xt immediate? if
       ." (immediate) "
   then
   xt inline? if
       ." (inlineable) "
   then
   xt >view 2@ ?dup if
       $. ."  line " u.
   else
       drop
   then
   xt disassemble ;

only forth also disassembler also forth definitions     \ REVIEW

warning on                              \ REVIEW
