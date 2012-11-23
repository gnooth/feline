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

0 value ip
0 value prefix
variable opcode

0 value modrm-byte

variable done?
variable literal?

: .2  ( ub -- )  0 <# # # #> type ;
: .3  ( ub -- )  0 <# # # # #> type ;

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

: .reg64  ( +n -- )
   s" raxrcxrdxrbxrsprbprsirdi"         \ +n addr len
   drop                                 \ +n addr
   swap                                 \ addr +n
   3 * + 3 type
;

create handlers  256 cells allot  handlers 256 cells 0 fill

: handler  ( opcode -- handler )  cells handlers + @ ;

: .bytes  ( u -- )
   base @ >r
   hex
   0 ?do ip i + c@ .2 space loop
   r> base ! ;

: .mnemonic  ( addr len -- )  40 >pos type ;

: unsupported  ( -- )  40 >pos ." unsupported opcode " opcode @ h. ;

: .name  ( code-addr -- )
    find-code ?dup if
\         [ decimal ] 64 #out @ - 1 max spaces
        64 >pos
        count type
    then ;

: .ip  ( -- )  ?cr ip h. ;

: .literal  ( -- )
   .ip
   8 .bytes
   64 >pos
   ." $"
   ip @ h.
   cell +to ip ;

: .call  ( -- )
   5 .bytes
   s" call" .mnemonic
   48 >pos
   ip 1+ sl@           \ signed 32-bit displacement
   ip 5 + + dup h.
\     find-code ?dup if count type then
   dup >r
    .name
\     5 ip +!
\    5 ip + to ip
   5 +to ip
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
    r> drop
    ;

: .jmp  ( -- )
   5 .bytes
   40 >pos
   ." jmp"
   48 >pos
   ip 1+ sl@                            \ signed 32-bit displacement
   ip 5 + + dup h.
   .name
   5 +to ip ;

: .pop  ( -- )
   1 .bytes
   40 >pos
   ." pop"
   48 >pos
   opcode @ h# 58 - .reg64
   1 +to ip ;

: .ret  ( -- )
   1 .bytes
   s" ret" .mnemonic
   1 +to ip
   done? on ;

: .85  ( -- )
   ip prefix if 2 else 1 then + c@      \ modrm-byte
   dup modrm-mod 3 = if                 \ register operands
      dup modrm-reg 0= if
         prefix if 3 else 2 then .bytes
         s" test" .mnemonic
         48 >pos
         dup modrm-reg .reg64 ." , " modrm-rm .reg64
         prefix if 3 else 2 then +to ip
          exit
      then
   then
   1 .bytes
   unsupported
   1 +to ip ;

: .89  ( -- )
    ip prefix if 2 else 1 then + c@         \ modrm-byte
    dup modrm-mod 3 = if
        prefix if 3 else 2 then .bytes
        ." mov "

    then
;

: .relative  ( reg disp -- )
   ." [" swap .reg64                    \ -- disp
   ?dup if ." +" 0 .r then
   ." ]" ;

: .8b  ( -- )
   !modrm-byte
   modrm-mod 1 = if                \ 1-byte displacement
      prefix if 4 else 3 then .bytes
      s" mov" .mnemonic
      48 >pos
      modrm-reg .reg64 ." , "
      modrm-rm
      ip prefix if 3 else 2 then + c@
      .relative
      prefix if 4 else 3 then +to ip
      exit
   then
   drop
   1 .bytes
   unsupported
   1 +to ip ;

: .8d  ( -- )
   !modrm-byte
   modrm-mod 1 = if                \ 1-byte displacement
      prefix if 4 else 3 then .bytes
      s" lea" .mnemonic
      48 >pos
      modrm-reg .reg64 ." , "
      modrm-rm
      ip prefix if 3 else 2 then + c@
      .relative
      prefix if 4 else 3 then +to ip
      exit
   then
   drop
   1 .bytes
   unsupported
   1 +to ip ;

: install-handler  ( xt opcode -- )  cells handlers + ! ;

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
\ ' .89   handlers 89 cells + !
' .8b   8b install-handler
' .8d   8d install-handler
decimal

: .opcode  ( -- )
   opcode @ handler ?dup
   if
      execute
   else
      prefix if 2 else 1 then .bytes
      unsupported
      prefix if 2 else 1 then +to ip
  then ;

: decode  ( -- )                        \ decode one instruction
   ip c@
   dup h# 48 = if
      to prefix
      ip 1+ c@ opcode !
   else
      opcode !
      0 to prefix
   then
   .ip
   .opcode ;

: disasm  ( code-addr -- )
   to ip
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
