\ Copyright (C) 2015-2016 Peter Graves <gnooth@gmail.com>

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

require see.forth

only forth also definitions

decimal

\ TEMPORARY
[defined] assembler [if] warning off [then]

[undefined] assembler [if] vocabulary assembler [then]

[undefined] x86-64 [if] include-system-file x86-64.forth [then]

only forth also x86-64 also assembler definitions

: byte,  ( byte  -- ) c,c ;
: int32, ( int32 -- ) l,c ;
: int64, ( int64 -- )  ,c ;

: make-modrm-byte ( mod reg rm -- byte )
    local rm
    local reg
    local mod
    mod       6 lshift
    reg 7 and 3 lshift +                \ extended registers 8-15 need to fit in 3 bits
    rm  7 and          + ;

 0 value immediate-operand?
 0 value immediate-operand

-1 value sreg   \ source register
64 value ssize  \ source operand size
-1 value sbase  \ source base register
 0 value sdisp  \ source displacement
-1 value dreg   \ destination register
64 value dsize  \ destination operand size
-1 value dbase  \ destination base register
 0 value ddisp  \ destination displacement

 0 value prefix-byte

: prefix, ( -- ) prefix-byte ?dup if byte, then ;

: int32?       ( n -- flag ) min-int32 max-int32 between ;
: signed-byte? ( n -- flag ) -128 127 between ;

false value dest?

: -> true to dest? ;

: define-reg64 ( reg# -- )
    create ,
    does>
        @ dest? if
            to dreg 64 to dsize
        else
            to sreg 64 to ssize
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

: extreg? ( reg64 -- flag )
    8 and ;

: define-base-reg ( reg# -- )
    create ,
    does>
        @ dest? if to dbase else to sbase then
;

\ displacement is set by +]
 0 define-base-reg [rax
 1 define-base-reg [rcx
 2 define-base-reg [rdx
 3 define-base-reg [rbx
 4 define-base-reg [rsp
 5 define-base-reg [rbp
 6 define-base-reg [rsi
 7 define-base-reg [rdi
 8 define-base-reg [r8
 9 define-base-reg [r9
10 define-base-reg [r10
11 define-base-reg [r11
12 define-base-reg [r12
13 define-base-reg [r13
14 define-base-reg [r14
15 define-base-reg [r15

\ displacement is 0
 0 define-base-reg [rax]
 1 define-base-reg [rcx]
 2 define-base-reg [rdx]
 3 define-base-reg [rbx]
 4 define-base-reg [rsp]
 5 define-base-reg [rbp]
 6 define-base-reg [rsi]
 7 define-base-reg [rdi]
 8 define-base-reg [r8]
 9 define-base-reg [r9]
10 define-base-reg [r10]
11 define-base-reg [r11]
12 define-base-reg [r12]
13 define-base-reg [r13]
14 define-base-reg [r14]
15 define-base-reg [r15]

: +] ( n -- ) dest? if to ddisp else to sdisp then ;
: -] ( n -- ) negate +] ;

0 value asm-start
0 value asm-end

: reset-assembler ( -- )
    \ reset assembler for next instruction
     0 to immediate-operand?
     0 to immediate-operand

    -1 to sreg
    -1 to dreg
    64 to ssize
    64 to dsize
    -1 to sbase
    -1 to dbase
     0 to sdisp
     0 to ddisp

     0 to prefix-byte
     0 to dest?
;

0 value testing?

: end-instruction ( -- )
    reset-assembler
;

: # ( n -- )
    dest? abort" # can't be a destination"
    to immediate-operand
    true to immediate-operand? ;

: add, ( -- )
    sreg -1 <> dreg -1 <> and if
        dsize 64 = if
            $48 to prefix-byte
        then
        prefix,
        $03 byte,
        3 dreg sreg make-modrm-byte byte,
        end-instruction
        exit
    then
    immediate-operand? if
        dreg -1 <> if
            dsize 64 = if
                $48 to prefix-byte
            then
            prefix,
            immediate-operand signed-byte? if
                $83 byte,
                3 0 dreg make-modrm-byte byte,
                immediate-operand byte,
                end-instruction
                exit
            then
            immediate-operand int32? if
                $81 byte,
                3 0 dreg make-modrm-byte byte,
                immediate-operand int32,
                end-instruction
                exit
            then
        then
    then
    true abort" unsupported" ;

: lea, ( -- )
    sbase -1 <> if
        dreg -1 <> if
            dsize 64 = if
                $48 to prefix-byte
            then
            prefix,
            $8d byte,
            1 sbase dreg make-modrm-byte byte,
            sdisp byte,
            end-instruction
            exit
        then
    then
    true abort" unsupported"
;

: mov, ( -- )
    sreg -1 <> dreg -1 <> and if
        \ register to register move
        ssize 64 = dsize 64 = or if
            $48 to prefix-byte
        then
        sreg extreg? if
            prefix-byte rex.r or to prefix-byte
        then
        dreg extreg? if
            prefix-byte rex.b or to prefix-byte
        then
        prefix,
        $89 byte,
        3 sreg dreg make-modrm-byte byte,
        end-instruction
        exit
    then
    sreg -1 <> if
        ssize 64 = if $48 to prefix-byte then
        dbase -1 <> if
            \ reg to mem
            dbase extreg? if
                prefix-byte rex.b or to prefix-byte
            then
            ddisp 0= if
                \ zero displacement
                prefix, $89 byte,       \ MOV r/m64, r64s               89 /r
                0 sreg dbase make-modrm-byte byte,
                dbase 4 = if \ rsp
                    $24 byte,           \ REVIEW
                then
            else
                prefix, $89 byte,
                1 sreg dbase make-modrm-byte byte,
                dbase 4 = if \ rsp
                    $24 byte,           \ REVIEW
                then
                ddisp byte,
            then
            end-instruction
            exit
        then
    then
    immediate-operand? if
        immediate-operand int32? if
            dsize 64 = if $48 to prefix-byte then
            prefix,
            dreg -1 <> if
                $c7 byte,
                3 0 dreg make-modrm-byte byte,
                immediate-operand int32,
                end-instruction
                exit
            then
        else
            dsize 64 = if $48 to prefix-byte then
            prefix,
            dreg -1 <> if
                $b8 dreg + byte,
                immediate-operand int64,
                end-instruction
                exit
            then
        then
    then
    true abort" unsupported"
;

: pop, ( -- )
    sreg -1 = abort" no source register"
    sreg 7 > if
        \ extended register
        $41 to prefix-byte prefix,
        -8 +to sreg
    then
    sreg $58 + byte,
    end-instruction ;

: push, ( -- )
    sreg -1 = abort" no source register"
    sreg 8 and if
        \ extended register
        $41 to prefix-byte prefix,
        -8 +to sreg
    then
    sreg $50 + byte,
    end-instruction ;

: ret, ( -- ) $c3 byte, end-instruction ;

0 value saved-state

: }asm ( -- )
    previous
    saved-state if ] then
;

also forth definitions

: asm{ ( -- )
    reset-assembler
    state@ to saved-state
    postpone [
    also assembler
    here-c to asm-start
; immediate

: code ( "<spaces>name" -- )
\ TOOLS EXT
    cq-clear
    header
    hide
    align-code
    here-c dup last-code ! latest name> !
    postpone asm{
;

: end-code ( -- )
    }asm
    previous
    reveal
;

\ TEMPORARY
also disassembler
