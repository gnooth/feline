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

[undefined] disassembler [if]
vocabulary disassembler
[then]

[defined] see [if] warning off [then]   \ temporary

only forth also disassembler definitions

decimal

: find-code-in-wordlist  ( code-addr wid -- xt | 0 )
   swap >r                      \ -- wid        r: -- code-addr
   @ dup if
      begin                     \ -- nfa        r: -- code-addr
         name> dup >code r@ = if
            r>drop
            exit
         then
         >link @ dup 0=
      until
   then
   r>drop ;

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

\ "0 = default operand size   1 = 64-bit operand size"
8 constant rex.w

\ "1-bit (high) extension of the ModRM reg field, thus permitting access to 16 registers."
4 constant rex.r

\ "1-bit (high) extension of the SIB index field, thus permitting access to 16 registers."
2 constant rex.x

\ "1-bit (high) extension of the ModRM r/m field, SIB base field1, or opcode reg field,
\ thus permitting access to 16 registers."
1 constant rex.b


0 value start-address
0 value end-address
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

: .2  ( ub -- )  0 <# # # #> type ;
: .3  ( ub -- )  0 <# # # # #> type ;
: .sep  ( -- )  ." , " ;

\ Obsolete.
create old-mnemonic  2 cells allot

: old-mnemonic!  ( addr len -- )  old-mnemonic 2! ;
: old-.mnemonic  ( -- )  40 >pos  old-mnemonic 2@ type ;

0 value mnemonic

: .bytes  ( u -- )
   ?dup if
      base @ >r
      hex
      instruction-start swap bounds do i c@ .2 space loop
      r> base !
   then ;

\ : !modrm-byte  ( -- )  ip prefix if 2 else 1 then + c@ to modrm-byte ;
: !modrm-byte  ( -- )  ip c@ to modrm-byte  1 +to ip ;

: (modrm-mod)  ( modrm-byte -- mod )  b# 11000000 and 6 rshift ;
: (modrm-reg)  ( modrm-byte -- reg )  b# 00111000 and 3 rshift ;
: (modrm-rm)   ( modrm-byte -- rm  )  b# 00000111 and ;

: modrm-mod  ( -- mod )  modrm-byte (modrm-mod) ;
: modrm-reg  ( -- reg )  modrm-byte (modrm-reg) ;
: modrm-rm   ( -- rm  )  modrm-byte (modrm-rm)  ;

: register-reg ( n1 -- n2 )
\     prefix if
        prefix rex.r and if
            8 or
        then
\     then
;

: register-rm ( n1 -- n2 )
\     prefix if
        prefix rex.b and if
            8 or
        then
\     then
;

: .modrm  ( modrm-byte -- )
   base @ >r binary
   ?cr ." mod: " dup (modrm-mod) .2 space
   cr  ." reg: " dup (modrm-reg) .3 space
   cr  ."  rm: "      (modrm-rm) .3 space
   r> base ! ;

: !sib-byte ( -- )
    ip c@ to sib-byte
    1 +to ip ;

: (sib-scale)  ( sib -- scale )  b# 11000000 and 6 rshift ;
: (sib-index)  ( sib -- index )  b# 00111000 and 3 rshift ;
: (sib-base)   ( sib -- base  )  b# 00000111 and ;

: sib-scale  ( -- scale )  sib-byte (sib-scale) ;
: sib-index  ( -- index )  sib-byte (sib-index) ;
: sib-base   ( -- base  )  sib-byte (sib-base)  ;

: .sib  ( sib -- )
   base @ >r binary
   ?cr ." scale: " dup (sib-scale) .2 space
   cr  ." index: " dup (sib-index) .3 space
   cr  ."  base: "     (sib-index) .3 space
   r> base ! ;

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
    ." [$"
    base@ >r
    0 hex u.r
    r> base!
    ." ]"
;

\ 0 value current-operand                 \ FIXME this should be a local!

: .operand ( operand -- )
\     dup to current-operand
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
            current-operand operand-data @ ." $" h.
        endof
    endcase
;

: .inst ( -- )
   ip instruction-start - .bytes
   mnemonic if
      40 >pos
      mnemonic count type
   then
   48 >pos
   destination-operand @ if
      destination-operand .operand
      source-operand operand-kind @ if ." , " then
   then
   source-operand @ if
      source-operand .operand
   then ;

create handlers  256 cells allot  handlers 256 cells 0 fill

: handler  ( opcode -- handler )  cells handlers + @ ;

: install-handler  ( xt opcode -- )
\   tuck
   cells handlers + !
\    ?cr h. ." handler installed"
;

: unsupported  ( -- )  40 >pos ." unsupported opcode " opcode h. ;

: .name  ( code-addr -- )  find-code ?dup if 64 >pos >name count type then ;

: .ip  ( -- )  ?cr ip h. ;

: .literal  ( -- )
   .ip
   cell .bytes
   64 >pos
   ." #"
   base@ >r
   ip @ decimal .
   r> base!
   ." $"
   ip @ h.
   cell +to ip ;

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
\    5 to size
\    size .bytes
\    s" call" old-mnemonic!
\    old-.mnemonic
\    48 >pos

   $" call" to mnemonic
   ok_immediate 0 ip l@s
   4 +to ip
   ip + dup>r
   dest!
   .inst

\    .instruction
\    ip l@s                            \ signed 32-bit displacement
\    4 +to ip
\    ip + dup h.
   r>
   dup .name >r
\    r@ ['] (do) >code = if
\       ip to instruction-start
\       .literal
\    then
\    r@ ['] (?do) >code = if
\       ip to instruction-start
\       .literal
\    then
\    r@ ['] (+loop) >code = if
\        ip to instruction-start
\        .literal
\    then
   r> drop ;

: .jmp  ( -- )
\    5 to size
\    s" jmp" old-mnemonic!
\    .instruction
\    ip l@s                            \ signed 32-bit displacement
\    4 +to ip
\    ip + h.
   c" jmp" to mnemonic
   ok_immediate 0 ip l@s 4 +to ip ip + dest!
   .inst
   ;

\ $01 handler
:noname  ( -- )                         \ ADD reg/mem64, reg64
    $" add" to mnemonic
    !modrm-byte
    modrm-mod 3 <> if
        modrm-rm 4 = if !sib-byte then
    then
    modrm-mod 0= if
        ok_relative modrm-rm register-rm 0 dest!
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

$01 install-handler

\ $03 handler
:noname  ( -- )                         \ ADD reg64, reg/mem64
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

$03 install-handler

\ $09 handler
:noname  ( -- )
   !modrm-byte
   modrm-mod 3 = if
      prefix if 2 else 1 then to size
      size .bytes
      s" or" old-mnemonic! old-.mnemonic
      48 >pos
      modrm-reg .reg64 .sep modrm-rm .reg64
      exit
   then
   ip instruction-start - .bytes
   unsupported ;

$09 install-handler

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
    ." $" h. ;

\ $0f handler
:noname  ( -- )
    ip c@ local byte2
    1 +to ip
    byte2 $b6 = if
        $" movzx" to mnemonic
        !modrm-byte
        ok_relative modrm-rm register-rm 0 source!
        ok_register modrm-reg register-reg 0 dest!
        $" byte" to relative-size
        .inst
        exit
    then
    byte2 $4d = if
        $" cmovnl" to mnemonic
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
    byte2 $84 = if
        $" jz" .jcc32
        exit
    then
    byte2 $81 = if
        $" jno" .jcc32
        exit
    then
    ip instruction-start - .bytes
    unsupported ;

$0f install-handler

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
   c" ret" to mnemonic
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

\ $29 handler
:noname  ( -- )
    $" sub" to mnemonic
    !modrm-byte
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

$29 install-handler

\ $31 handler
:noname ( -- )
   c" xor" to mnemonic
   !modrm-byte
   ok_register modrm-rm 0 dest!
   ok_register modrm-reg 0 source!
   .inst
   prefix if 3 else 2 then to size
;

$31 install-handler

\ $39 handler
:noname ( -- )
    $" cmp" to mnemonic
    !modrm-byte
    modrm-mod 1 = if
        ok_relative modrm-rm ip c@s dest!
        1 +to ip
        ok_register modrm-reg 0 source!
        prefix if 4 else 3 then to size
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
    ." $" h. ;

\ $70 handler
:noname ( -- ) $" jo" .jcc8 ; $70 install-handler

\ $71 handler
:noname ( -- ) $" jno" .jcc8 ; $71 install-handler

\ $74 handler
:noname ( -- ) $" jz" .jcc8 ; $74 install-handler

\ $75 handler
:noname ( -- ) $" jne" .jcc8 ; $75 install-handler

\ $7c handler
:noname ( -- ) $" jl" .jcc8 ; $7c install-handler

\ $7f handler
:noname ( -- ) $" jg" .jcc8 ; $7f install-handler

\ $eb handler
:noname  ( -- )
  s" jmp" old-mnemonic!
  ip c@s  1 +to ip      \ 8-bit signed offset
  2 to size
  .instruction
   ip + ." $" h.
;

$eb install-handler

\ $83 handler
:noname  ( -- )
    !modrm-byte
    modrm-mod 3 = if
        modrm-reg 0= if
            s" add" old-mnemonic!
            prefix if 4 else 3 then to size
            .instruction
            modrm-rm .reg64
            .sep
            ip c@s  1 +to ip
            .
            exit
        then
        modrm-reg 5 = if
            $" sub" to mnemonic
            prefix if 4 else 3 then to size
            .inst
            modrm-rm register-rm .reg64
            .sep
            ip c@s  1 +to ip
            .
            exit
        then
        modrm-reg 7 = if
            s" cmp" old-mnemonic!
            prefix if 4 else 3 then to size
            .instruction
            modrm-rm .reg64
            .sep
            ip c@s  1 +to ip
            .
            exit
        then
    then
    ip instruction-start - .bytes
    unsupported ;

$83 install-handler

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
    modrm-rm 4 = if
        !sib-byte
        modrm-mod 0= if
            sib-scale 0= if
                sib-index 4 = if
                    prefix if 7 else 6 then to size
                    ok_register modrm-reg register-reg 0 source!
                    ok_relative_no_reg 0 ip l@s dest!
                    4 +to ip
                    .inst
                    exit
                then
            then
        then
    else
        modrm-mod 0= if
            ok_relative modrm-rm register-rm 0 dest!
            ok_register modrm-reg register-reg 0 source!
            .inst
            exit
        then
        modrm-mod 1 = if                     \ 1-byte displacement
            ok_relative modrm-rm ip c@s dest!
            1 +to ip
            ok_register modrm-reg 0 source!
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
:noname ( -- )                          \ MOV reg8, reg/mem8            8a /r
    $" mov" to mnemonic
    !modrm-byte
    modrm-mod 1 = if                    \ 1-byte displacement
        ok_register modrm-reg reg8 0 dest!
        ok_relative modrm-rm ip c@s source!
        1 +to ip
        .inst
        exit
    then
    1 .bytes
    unsupported
;

$8a install-handler

: .8b  ( -- )                           \ MOV reg64, reg/mem64          8b /r
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
    modrm-rm 4 = if !sib-byte then
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

\ $c7 handler
:noname ( -- )
    \ Move a 32-bit signed immediate value to a 64-bit register
    \ or memory operand.
    !modrm-byte
    modrm-reg 0= if
        $" mov" to mnemonic
        modrm-mod 0 = if
            ok_relative modrm-reg register-reg 0 dest!
            ok_immediate 0 ip l@ source!
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

:noname ( -- )
   s" int3" old-mnemonic!
   1 to size
   .instruction
;

$cc install-handler

:noname ( -- )
   s" int" old-mnemonic!
   2 to size
   .instruction
   ip c@
   1 +to ip
   .
;

$cd install-handler

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

\ $ff handler
:noname  ( -- )
   !modrm-byte
   modrm-mod 0 = if
       modrm-reg 4 = if
           $" jmp" to mnemonic
           ok_relative modrm-rm 0 dest!
           2 to size
           .inst
           exit
       then
   then
   modrm-byte $e0 = if                  \ mod 3
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
         ip c@ h# 24 = if
            1 +to ip
            ip instruction-start - .bytes
            40 >pos ." inc"
            48 >pos ." qword [" modrm-rm .reg64 ." ]"
            exit
         then
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

h# ff install-handler

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
    ip to instruction-start
    operand1 clear-operand
    operand2 clear-operand
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
    .opcode ;

: disasm  ( code-addr -- )
    dup to start-address to ip
    0 to end-address
    done? off
    begin
        done? @ 0=
    while
        decode
    repeat
    ?cr end-address start-address - . ." bytes" ;

: disassemble  ( xt -- )
    >code disasm ;

also forth definitions

: see  ( "<spaces>name" -- )
   ' local xt
   xt >type c@ ?dup if
       cr
       case
           tvar   of ." variable " endof
           tvalue of ." value "    endof
           tdefer of ." defer "    endof
           tconst of ." constant " endof
       endcase
       xt >name .id
   then
   xt disassemble ;

only forth also disassembler also forth definitions     \ REVIEW

warning on                              \ REVIEW
