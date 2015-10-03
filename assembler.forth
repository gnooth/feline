\ Copyright (C) 2015 Peter Graves <gnooth@gmail.com>

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

\ TEMPORARY
[defined] assembler [if] warning off [then]

[undefined] assembler [if] vocabulary assembler [then]

[undefined] x86-64 [if] include-system-file x86-64.forth [then]

only forth also x86-64 also assembler definitions

decimal

: .2  ( ub -- )  base@ >r hex 0 <# # # #> r> base! type space ;

32 buffer: tbuf

: >tbuf ( byte -- ) tbuf count + c! 1 tbuf c+! ;

: .tbuf ( -- ) tbuf count bounds ?do i c@ .2 loop ;

defer byte,

\ ' .2 is byte,
' >tbuf is byte,

: prefix, ( byte -- ) byte, ;

: make-modrm-byte ( mod reg rm -- byte )
    local rm
    local reg
    local mod
    mod 6 lshift
    reg 3 lshift +
    rm + ;

-1 value sreg \ source register
64 value sreg-size
-1 value dreg \ destination register
64 value dreg-size

false value dest?

: -> true to dest? ;

: define-reg64 ( reg# -- )
    create ,
    does>
        @ dest? if
            to dreg 64 to dreg-size
        else
            to sreg 64 to sreg-size
        then
;

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

: ;opc ( -- )
    -1 to sreg
    -1 to dreg

    \ for testing only!
    $c3 >tbuf
    .tbuf
    tbuf 1+ ( skip count byte ) disasm

    0 tbuf c!
;

: ret, ( -- ) $c3 byte, ;opc ;

: pop,  ( -- )
    sreg -1 = abort" no source register"
    sreg 7 > if $41 prefix, sreg 8 - else sreg then $58 + byte, ;opc ;

: push, ( -- )
    sreg -1 = abort" no source register"
    sreg 7 > if $41 prefix, sreg 8 - else sreg then $50 + byte, ;opc ;

: mov,  ( -- )
    sreg -1 <> dreg -1 <> and if
        sreg-size 64 = dreg-size 64 = or if
            $48 prefix,
        then
        $89 byte,
        3 sreg dreg make-modrm-byte byte,
    then
    ;opc
;

: }asm ( -- ) previous ; immediate

also forth definitions

: asm{ ( -- ) also assembler ; immediate
