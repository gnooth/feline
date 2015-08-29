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

[undefined] disassembler [if] vocabulary disassembler [then]

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

: .modrm  ( modrm-byte -- )
   base @ >r binary
   ?cr ." mod: " dup (modrm-mod) .2 space
   cr  ." reg: " dup (modrm-reg) .3 space
   cr  ."  rm: "      (modrm-rm) .3 space
   r> base ! ;

: !sib-byte  ( -- )  ip c@ to sib-byte  1 +to ip ;

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

: .reg64  ( +n -- )
   s" raxrcxrdxrbxrsprbprsirdi"         \ +n addr len
   drop                                 \ +n addr
   swap                                 \ addr +n
   3 * + 3 type ;

: .reg  ( +n -- )
   prefix h# 48 = if .reg64 else .reg32 then ;

: .relative  ( reg disp -- )
   ." [" swap .reg64                    \ -- disp
   ?dup if
      dup 0> if
         ." +"
      else
         ." -"
      then
      abs 0 .r
   then
   ." ]" ;

0 value current-operand

: .operand ( operand -- )
   dup to current-operand
   operand-kind @
      case
         ok_relative of
            current-operand operand-register @
            current-operand operand-data @
            .relative
         endof
         ok_register of
            current-operand operand-register @ .reg
         endof
         ok_immediate of
            current-operand operand-data @ ." $" h.
         endof
      endcase ;

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

   c" call" to mnemonic
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
   r@ ['] (do) >code = if
      ip to instruction-start
      .literal
   then
   r@ ['] (?do) >code = if
      ip to instruction-start
      .literal
   then
   r@ ['] (loop) >code = if
      ip to instruction-start
      .literal
   then
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
:noname  ( -- )
   s" add" old-mnemonic!
   !modrm-byte
   modrm-mod 0= if
      prefix if 3 else 2 then to size
      size .bytes
      old-.mnemonic
      48 >pos
      modrm-rm 0 .relative
      .sep
      modrm-reg .reg64
      exit
   then
   prefix if 2 else 1 then to size
   unsupported
   size +to ip ;

h# 01 install-handler

\ $03 handler
:noname  ( -- )                         \ ADD reg64, reg/mem64
   c" add" to mnemonic
   !modrm-byte
   modrm-rm 4 = if !sib-byte then
   modrm-mod 1 = if                \ 1-byte displacement
\       prefix if 4 else 3 then .bytes
\       old-.mnemonic
\       48 >pos
\       modrm-reg .reg64 .sep
\       modrm-rm
\       ip c@s 1 +to ip
\       .relative
      ok_relative modrm-rm ip c@s source!
      1 +to ip
      ok_register modrm-reg 0 dest!
      .inst
      exit
   then
   ip instruction-start - .bytes
   unsupported
;

h# 03 install-handler

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

h# 09 install-handler

\ $0f handler
:noname  ( -- )
   ip c@
   1 +to ip
   dup h# 84 = if
      drop
      c" jz" to mnemonic
      ok_immediate 0
      ip l@s                            \ 32-bit signed offset
      4 +to ip
      ip + dest!
      .inst
      exit
   then
   h# 81 = if
      c" jno" to mnemonic
      ok_immediate 0
      ip l@s
      4 +to ip
      ip + dest!
      .inst
      exit
   then
   ip instruction-start - .bytes
   unsupported ;

h# 0f install-handler

: .push  ( -- )
   1 .bytes
   40 >pos
   ." push"
   48 >pos
   opcode h# 50 - .reg64
;

: .pop  ( -- )
   1 .bytes
   40 >pos
   ." pop"
   48 >pos
   opcode h# 58 - .reg64
;

: .ret  ( -- )
   c" ret" to mnemonic
   .inst
   ip end-address > if
      ip to end-address
      done? on
   then ;

\ $19 handler
:noname  ( -- )
   c" sbb" to mnemonic
   !modrm-byte
   ok_register modrm-rm 0 dest!
   ok_register modrm-reg 0 source!
   .inst
   prefix if 3 else 2 then to size
;

$19 install-handler

\ $74 handler
:noname  ( -- )
   s" jz" old-mnemonic!
   ip c@s  1 +to ip     \ 8-bit signed offset
   2 to size
   .instruction
   ip +                 \ jump target
   dup end-address > if dup to end-address then
   ." $" h.
;

$74 install-handler

\ $eb handler
:noname  ( -- )
  s" jmp" old-mnemonic!
  ip c@s  1 +to ip      \ 8-bit signed offset
  2 to size
  .instruction
   ip + ." $" h.
;

h# 0eb install-handler

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

h# 83 install-handler

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

: .89  ( -- )                           \ MOV reg/mem64, reg64
   s" mov" old-mnemonic!
   c" mov" to mnemonic
   !modrm-byte
   modrm-mod 0= if
\       prefix if 3 else 2 then to size
\       size .bytes
\       old-.mnemonic
\       48 >pos
\       modrm-rm 0 .relative
\       .sep
\       modrm-reg .reg64

\       modrm-rm destination-operand operand-register !
\       ok_relative destination-operand operand-kind !
      ok_relative modrm-rm 0 dest!
\       modrm-reg source-operand operand-register !
\       ok_register source-operand operand-kind !
      ok_register modrm-reg 0 source!
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
       size .bytes
       old-.mnemonic
       48 >pos
       modrm-rm .reg64
       .sep
       modrm-reg .reg64
\        size +to ip
       exit
    then
\     prefix if 2 else 1 then to size
\     size .bytes
    ip instruction-start - .bytes
    unsupported
\     size +to ip
;

: .8b  ( -- )                           \ MOV reg64, reg/mem64          8b /r
   s" mov" old-mnemonic!
   c" mov" to mnemonic
   !modrm-byte
   modrm-rm 4 = if !sib-byte then
   modrm-mod 0= if
      prefix if 3 else 2 then to size
      size .bytes
      old-.mnemonic
      48 >pos
      modrm-reg .reg64
      .sep
      modrm-rm 0 .relative
\       size +to ip
      exit
   then
   modrm-mod 1 = if                \ 1-byte displacement
\       prefix if 4 else 3 then to size
\       size .bytes
\       old-.mnemonic
\       48 >pos
\       modrm-reg .reg64 .sep
\       modrm-rm
\ \       ip prefix if 3 else 2 then + c@s
\       ip c@s  1 +to ip
\       .relative
\ \       size +to ip
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
   modrm-mod 1 = if                \ 1-byte displacement
\       prefix if 4 else 3 then .bytes
\       old-.mnemonic
\       48 >pos
\       modrm-reg .reg64 .sep
\       modrm-rm
\ \       ip prefix if 3 else 2 then + c@s
\       ip c@s 1 +to ip
\       .relative
\ \       prefix if 4 else 3 then +to ip
      ok_register modrm-reg 0 dest!
      ok_relative modrm-rm ip c@s source!
      1 +to ip
      .inst
      exit
   then
   ip instruction-start - .bytes
   unsupported
\    1 +to ip
;

:noname  ( -- )
   c" nop" to mnemonic
   .inst ;

h# 90 install-handler

: .b8  ( -- )
   s" mov" old-mnemonic!
   prefix if 10 else 5 then to size
   .instruction
   opcode h# b8 - .reg
   .sep
   prefix if
      ip ( 2 + ) @

   else
      ip ( 1 + ) l@s
   then
   h.
   prefix if 8 else 4 then +to ip
;

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

\ $ff handler
:noname  ( -- )
   !modrm-byte
   modrm-byte h# 20 = if        \ mod 0
      s" jmp" old-mnemonic!
      2 to size
      .instruction
      ." [rax]"
      exit
   then
   modrm-byte h# e0 = if        \ mod 3
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
:noname b8 8 bounds do ['] .b8 i install-handler loop ; execute
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
   dup h# 48 = if
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

: disassemble  ( cfa -- )
   >code disasm ;

also forth definitions

: see  ( -- )
   ' disassemble ;

only forth definitions
