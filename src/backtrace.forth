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

only forth also definitions

: (find-word-in-wordlist) ( code-address wid -- nfa distance )
    local wid
    local code-address

    100000 local best-distance
         0 local best-nfa

     wid @ local nfa

    0 local address
    0 local distance

    begin
        nfa
    while
        nfa name> >code to address

        address code-address = if
            nfa 0 exit
        then

        code-address address - to distance

        distance 0>
        distance best-distance < and
        if
            nfa to best-nfa
            distance to best-distance
        then

        nfa name>link @ to nfa
    repeat

    best-nfa best-distance
;

: find-word-from-code-address ( code-address -- nfa )
    local code-address

    100000 local best-distance
    0 local best-nfa

    0 local distance
    0 local nfa

    voclink @ local wid
    begin
        wid
    while
        code-address wid (find-word-in-wordlist)
        to distance
        to nfa

        distance 0>=
        distance best-distance < and
        if
            nfa to best-nfa
            distance to best-distance
        then

        wid wid>link @ to wid
    repeat

    best-nfa
;

: print-saved-registers ( -- )
    ?cr
    ." Registers:" cr
    4 >pos ." RAX = " saved-rax h.     40 >pos ." R8  = " saved-r8  h. cr
    4 >pos ." RBX = " saved-rbx h.     40 >pos ." R9  = " saved-r9  h. cr
    4 >pos ." RCX = " saved-rcx h.     40 >pos ." R10 = " saved-r10 h. cr
    4 >pos ." RDX = " saved-rdx h.     40 >pos ." R11 = " saved-r11 h. cr
    4 >pos ." RSI = " saved-rsi h.     40 >pos ." R12 = " saved-r12 h. cr
    4 >pos ." RDI = " saved-rdi h.     40 >pos ." R13 = " saved-r13 h. cr
    4 >pos ." RBP = " saved-rbp h.     40 >pos ." R14 = " saved-r14 h. cr
    4 >pos ." RSP = " saved-rsp h.     40 >pos ." R15 = " saved-r15 h. cr
    4 >pos ." RIP = " saved-rip h.     40 >pos ." EFL = " saved-efl h. cr
;

: (print-backtrace) ( -- )
    ?cr
    ." Backtrace:"
    get-saved-backtrace                 \ -- addr u
    local size
    local array
    0 local code-address
    0 local nfa
    size 0 ?do
        array i cells + @ to code-address
        cr code-address 17 h.r space
        code-address find-word-from-code-address to nfa
        nfa if
            nfa .id
            code-address nfa name> >code -
            ." <+" 0 dec.r ." >"
        then
    loop
;

' (print-backtrace) is print-backtrace

synonym bt print-backtrace

:noname ( -- )
    print-saved-registers
    print-backtrace
; is print-saved-registers-and-backtrace
