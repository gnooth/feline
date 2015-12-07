; Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

file __FILE__

; ### +
inline plus, '+'
        _plus
endinline

; ### 1+
inline oneplus, '1+'
        _oneplus
endinline

; ### 2+
inline twoplus, '2+'
        _twoplus
endinline

; ### under+
code underplus, 'under+'                ; n1 n2 n3 -- n1+n3 n2
        add     [rbp + BYTES_PER_CELL], rbx
        poprbx
        next
endcode

; ### char+
inline charplus, 'char+'                ; c-addr1 -- c-addr2
; CORE 6.1.0897
        _oneplus
endinline

; ### chars
code chars, 'chars', IMMEDIATE          ; n1 -- n2
; CORE 6.1.0898
        ; nothing to do
        next
endcode

; ### cell+
inline cellplus, 'cell+'                ; a-addr1 -- a-addr2
; CORE 6.1.0880
        _cellplus
endinline

; ### cell-
inline cellminus, 'cell-'               ; a-addr1 -- a-addr2
; not in standard
        _cellminus
endinline

; ### cells
inline cells, 'cells'                   ; n1 -- n2
; CORE 6.1.0890
; "n2 is the size in address units of n1 cells"
        _cells
endinline

; ### -
inline minus, '-'
        neg     rbx
        add     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### swap-
inline swapminus, 'swap-'
        _swapminus
endinline

; ### 1-
inline oneminus, '1-'
        _oneminus
endinline

; ### *
code star, '*'
        popd    rax
        popd    rdx
        imul    rdx
        pushd   rax
        next
endcode

; ### m*
code mstar, 'm*'
        popd    rax
        popd    rdx
        imul    rdx
        pushd   rax
        pushd   rdx
        next
endcode

; ### 2*
inline twostar, '2*'
        _twostar
endinline

; ### /
code slash, '/'                         ; n1 n2 -- n3
; CORE
        _ slmod
        _nip
        next
endcode

; ### mod
code mod, 'mod'                          ; n1 n2 -- n3
; CORE
        _ slmod
        _ drop
        next
endcode

; ### */mod
code starslashmod, '*/mod'              ; n1 n2 n3 -- n4 n5
; CORE
        _ tor
        _ mstar
        _ rfrom
        _ fmslmod
        next
endcode

; ### */
code starslash, '*/'                    ; n1 n2 n3 -- n4
; CORE
        _ starslashmod
        _nip
        next
endcode

; ### 2/
code twoslash, '2/'
        sar     rbx, 1
        next
endcode

; ### um*
code umstar, 'um*'                      ; u1 u2 -- ud
; 6.1.2360 CORE
; "Multiply u1 by u2, giving the unsigned double-cell product ud. All
; values and arithmetic are unsigned."
        mov     rax, rbx
        mul     qword [rbp]
        mov     [rbp], rax
        mov     rbx, rdx
        next
endcode

; ### um/mod
code umslmod, 'um/mod'                  ; ud u1 -- u2 u3
; 6.1.2370 CORE
        mov     rdx, [rbp]
        mov     rax, [rbp + BYTES_PER_CELL]
        add     rbp, BYTES_PER_CELL
        div     rbx                     ; remainder in RDX, quotient in RAX
        mov     [rbp], rdx
        mov     rbx, rax
        next
endcode

; ### fm/mod
code fmslmod, 'fm/mod'                  ; d1 n1 -- n2 n3
; CORE n2 is remainder, n3 is quotient
; gforth
        _duptor
        _ dup
        _zlt
        _if fmslmod1
        _negate
        _ tor
        _ dnegate
        _ rfrom
        _then fmslmod1
        _ over
        _zlt
        _if fmslmod2
        _ tuck
        _ plus
        _ swap
        _then fmslmod2
        _ umslmod
        _ rfrom
        _zlt
        _if fmslmod3
        _ swap
        _negate
        _ swap
        _then fmslmod3
        next
endcode

; ### /mod
code slmod, '/mod'                      ; n1 n2 -- n3 n4
        _ tor                           ; >r s>d r> fm/mod
        _ stod
        _ rfrom
        _ fmslmod
        next
endcode

; ### sm/rem
code smslrem, 'sm/rem'                  ; d1 n1 -- n2 n3
; CORE
; gforth
        _ over
        _ tor
        _ dup
        _ tor
        _ abs_
        _ rrot
        _ dabs
        _ rot
        _ umslmod
        _ rfrom
        _ rfetch
        _ xor
        _zlt
        _if smslrem1
        _negate
        _then smslrem1
        _ rfrom
        _zlt
        _if smslrem2
        _ swap
        _negate
        _ swap
        _then smslrem2
        next
endcode

; ### mu/mod
code muslmod, 'mu/mod'                  ; d n -- rem dquot
        _ tor
        _zero
        _ rfetch
        _ umslmod
        _ rfrom
        _ swap
        _ tor
        _ umslmod
        _ rfrom
        next
endcode

; ### abs
code abs_, 'abs'
        or      rbx, rbx
        jns     abs1
        neg     rbx
abs1:
        next
endcode

; ### =
code equal, '='                         ; x1 x2 -- flag
; CORE
; adapted from Win32Forth
        sub     rbx, [rbp]
        cmp     rbx, 1
        sbb     rbx, rbx
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### <>
code notequal, '<>'                     ; x1 x2 -- flag
; CORE EXT
; adapted from Win32Forth
        mov     rax, [rbp]
        sub     rax, rbx
        neg     rax
        sbb     rbx, rbx
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### >
code gt, '>'                            ; n1 n2 -- flag
        cmp     [rbp], rbx
        mov     ebx, 0
        jle     .1
        dec     rbx
.1:
        add     rbp, BYTES_PER_CELL
        next
endcode

; ### >=
code ge, '>='                           ; n1 n2 -- flag
        cmp     [rbp], rbx
        mov     ebx, 0
        jl      .1
        dec     rbx
.1:
        add     rbp, BYTES_PER_CELL
        next
endcode

; ### <
code lt, '<'                            ; n1 n2 -- flag
; CORE
; adapted from Win32Forth
        xor     eax, eax
        cmp     [rbp], rbx
        mov     rbx, -1
        cmovnl  rbx, rax

;         cmp     [rbp], rbx
;         setl    bl
;         neg     bl
;         movsx   rbx, bl

        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### <=
code le, '<='                           ; n1 n2 -- flag
        cmp     [rbp], rbx
        mov     ebx, 0
        jg      .1
        dec     rbx
.1:
        add     rbp, BYTES_PER_CELL
        next
endcode

; ### u<
code ult, 'u<'
        cmp     [rbp], rbx
        mov     ebx, 0
        jae     .1
        dec     rbx
.1:
        add     rbp, BYTES_PER_CELL
        next
endcode

; ### u>
code ugt, 'u>'
        cmp     [rbp], rbx
        mov     ebx, 0
        jbe     .1
        dec     rbx
.1:
        add     rbp, BYTES_PER_CELL
        next
endcode

; ### within
code within, 'within'                   ; n min max -- flag
; CORE EXT
; return true if min <= n < max
        _ over
        _ minus
        _ tor
        _ minus
        _ rfrom
        _ ult
        next
endcode

; ### between
code between, 'between'                 ; n min max -- flag
; return true if min <= n <= max
        _oneplus
        _ within
        next
endcode

; ### 0=
inline zeq, '0='
; CORE
        _zeq
endinline

; ### 0<>
code zne, '0<>'
        or      rbx, rbx
        mov     ebx, 0
        jz      .1
        dec     rbx
.1:
        next
endcode

; ### 0>
code zgt, '0>'
        or      rbx, rbx
        mov     ebx, 0
        jng     .1
        dec     rbx
.1:
        next
endcode

; ### 0>=
code zge, '0>='
        or      rbx, rbx
        mov     ebx, 0
        js      .1
        dec     rbx
.1:
        next
endcode

; ### 0<
inline zlt, '0<'
; CORE
        _zlt
endinline

; ### s>d
code stod, 's>d'                        ; n -- d
        _ dup
        _zlt
        next
endcode

; ### min
code min, 'min'                         ; n1 n2 -- n3
        popd    rax
        cmp     rax, rbx
        jge     .1
        mov     rbx, rax
.1:
        next
endcode

; ### max
code max, 'max'                         ; n1 n2 -- n3
        popd    rax
        cmp     rax, rbx
        jle     .1
        mov     rbx, rax
.1:
        next
endcode

; ### lshift
code lshift, 'lshift'                   ; x1 u -- x2
; CORE
        mov     ecx, ebx
        poprbx
        shl     rbx, cl
        next
endcode

; ### rshift
code rshift, 'rshift'                   ; x1 u -- x2
; CORE
        mov     ecx, ebx
        poprbx
        shr     rbx, cl
        next
endcode

; ### rol
code rol, 'rol'
        mov     ecx, ebx
        poprbx
        rol     rbx, cl
        next
endcode

; ### and
inline and, 'and'                       ; x1 x2 -- x3
; CORE
        and     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### or
inline or, 'or'                         ; x1 x2 -- x3
; CORE
        or      rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endinline

; ### xor
code xor, 'xor'                         ; x1 x2 -- x3
; CORE
        xor     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### invert
code invert, 'invert'                   ; x1 -- x2
; CORE
; "Invert all bits of x1, giving its logical inverse x2."
        not     rbx
        next
endcode

; ### negate
inline negate, 'negate'                 ; n1 -- n2
; CORE
        _negate
endinline
