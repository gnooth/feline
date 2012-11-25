\ Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

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

decimal

0 value definition-start
0 value instruction-start
0 value ip
0 value prefix
0 value opcode
0 value operand1                        \ destination
0 value operand2                        \ source
0 value modrm-byte

0 value size

variable done?
variable literal?

: .2  ( ub -- )  0 <# # # #> type ;
: .3  ( ub -- )  0 <# # # # #> type ;
: .sep  ( -- )  ." , " ;

create mnemonic  2 cells allot

: mnemonic!  ( addr len -- )  mnemonic 2! ;
: .mnemonic  ( -- )  40 >pos  mnemonic 2@ type ;

: !modrm-byte  ( -- )  ip prefix if 2 else 1 then + c@ to modrm-byte ;

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

: .reg32  ( +n -- )
   s" eaxecxedxebxespebpesiedi"         \ +n addr len
   drop                                 \ +n addr
   swap                                 \ addr +n
   3 * + 3 type
;

: .reg64  ( +n -- )
   s" raxrcxrdxrbxrsprbprsirdi"         \ +n addr len
   drop                                 \ +n addr
   swap                                 \ addr +n
   3 * + 3 type
;

: .reg  ( +n -- )
   prefix h# 48 = if .reg64 else .reg32 then ;

create handlers  256 cells allot  handlers 256 cells 0 fill

: handler  ( opcode -- handler )  cells handlers + @ ;

: install-handler  ( xt opcode -- )  cells handlers + ! ;

: .bytes  ( u -- )
   ?dup if
      base @ >r
      hex
      instruction-start swap bounds do i c@ .2 space loop
      r> base !
   then ;

: unsupported  ( -- )  40 >pos ." unsupported opcode " opcode h. ;

: .name  ( code-addr -- )  find-code ?dup if 64 >pos count type then ;

: .ip  ( -- )  ?cr ip h. ;

: .literal  ( -- )
   .ip
   cell .bytes
   64 >pos
   ." #"
   base @ >r
   ip @ decimal .
   r> base !
   ." $"
   ip @ h.
   cell +to ip ;

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

: .instruction  ( -- )
   size .bytes
   .mnemonic
   48 >pos
   operand1 ?dup if
      count type
   then
   operand2 ?dup if
      .sep
      count type
   then
;

: .call  ( -- )
   5 to size
\    size .bytes
   s" call" mnemonic!
\    .mnemonic
\    48 >pos
   .instruction
   ip 1+ l@s                            \ signed 32-bit displacement
   ip size + + dup h.
   dup .name >r
   size +to ip
   r@ ['] (lit) >code = if
      .literal
   then
   r@ ['] (do) >code = if
      .literal
   then
   r@ ['] (?do) >code = if
      .literal
   then
   r@ ['] (loop) >code = if
      .literal
   then
   r@ ['] dovalue >code = if
      .literal
   then
   r> drop ;

: .jmp  ( -- )
   5 .bytes
   40 >pos
   ." jmp"
   48 >pos
   ip 1+ l@s                            \ signed 32-bit displacement
   ip 5 + + dup h.
   .name
   5 +to ip ;

\ $01 handler
:noname ( -- )
   s" add" mnemonic!
   !modrm-byte
   modrm-mod 0= if
      prefix if 3 else 2 then to size
      size .bytes
      .mnemonic
      48 >pos
      modrm-rm 0 .relative
      .sep
      modrm-reg .reg64
      size +to ip
      exit
   then
   prefix if 2 else 1 then to size
   unsupported
   size +to ip ;

h# 01 install-handler

: .pop  ( -- )
   1 .bytes
   40 >pos
   ." pop"
   48 >pos
   opcode h# 58 - .reg64
   1 +to ip ;

: .ret  ( -- )
   1 .bytes
\    s" ret" .mnemonic
   s" ret" mnemonic! .mnemonic
   1 +to ip
   done? on ;

: .85  ( -- )
\    ip prefix if 2 else 1 then + c@      \ modrm-byte
   !modrm-byte
   modrm-mod 3 = if                     \ register operands
      modrm-reg 0= if
         prefix if 3 else 2 then to size
         size .bytes
         s" test" mnemonic! .mnemonic
         48 >pos
         modrm-reg .reg64 .sep modrm-rm .reg64
         size +to ip
         exit
      then
   then
   1 .bytes
   unsupported
   1 +to ip ;

: .89  ( -- )
   s" mov" mnemonic!
   !modrm-byte
   modrm-mod 0= if
      prefix if 3 else 2 then to size
      size .bytes
      .mnemonic
      48 >pos
      modrm-rm 0 .relative
      .sep
      modrm-reg .reg64
      size +to ip
      exit
   then
   modrm-mod 1 = if                     \ 1-byte displacement
      prefix if 4 else 3 then to size
      size .bytes
      .mnemonic
      48 >pos
      modrm-rm
      ip prefix if 3 else 2 then + c@s
      .relative
      .sep
      modrm-reg .reg64
      size +to ip
      exit
    then
    modrm-mod 3 = if                    \ register operands
       prefix if 3 else 2 then to size
       size .bytes
       .mnemonic
       48 >pos
       modrm-rm .reg64
       .sep
       modrm-reg .reg64
       size +to ip
       exit
    then
    prefix if 2 else 1 then to size
    size .bytes
    unsupported
    size +to ip ;

: .8b  ( -- )
   s" mov" mnemonic!
   !modrm-byte
   modrm-mod 0= if
      prefix if 3 else 2 then to size
      size .bytes
      .mnemonic
      48 >pos
      modrm-reg .reg64
      .sep
      modrm-rm 0 .relative
      size +to ip
      exit
   then
   modrm-mod 1 = if                \ 1-byte displacement
      prefix if 4 else 3 then to size
      size .bytes
      .mnemonic
      48 >pos
      modrm-reg .reg64 .sep
      modrm-rm
      ip prefix if 3 else 2 then + c@s
      .relative
      size +to ip
      exit
   then
   1 .bytes
   unsupported
   1 +to ip ;

: .8d  ( -- )
   s" lea" mnemonic!
   !modrm-byte
   modrm-mod 1 = if                \ 1-byte displacement
      prefix if 4 else 3 then .bytes
      .mnemonic
      48 >pos
      modrm-reg .reg64 .sep
      modrm-rm
      ip prefix if 3 else 2 then + c@s
      .relative
      prefix if 4 else 3 then +to ip
      exit
   then
   1 .bytes
   unsupported
   1 +to ip ;

: .b8  ( -- )
   s" mov" mnemonic!
   prefix if 10 else 5 then to size
   .instruction
   opcode h# b8 - .reg
   .sep
   prefix if
      ip 2 + @
   else
      ip 1 + l@s
   then
   .
   size +to ip
;

hex
' .call e8 install-handler
' .jmp  e9 install-handler
' .ret  c3 install-handler
' .pop  58 install-handler
' .pop  59 install-handler
' .pop  5a install-handler
' .pop  5b install-handler
' .pop  5d install-handler
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
      prefix if 2 else 1 then +to ip
  then ;

: decode  ( -- )                        \ decode one instruction
   ip to instruction-start
   .ip
   ip c@
   dup h# 48 = if
      to prefix
      ip 1+ c@ to opcode
   else
      to opcode
      0 to prefix
   then
   .opcode ;

: disasm  ( code-addr -- )
   dup to definition-start to ip
   done? off
   begin
      done? @ 0=
   while
      decode
   repeat ;

: disassemble  ( cfa -- )
   >code disasm ;

: see  ( -- )
   ' disassemble ;
