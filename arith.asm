; Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

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

code plus, '+'
        add     rbx, [rbp]
        add     rbp, BYTES_PER_CELL
        next
endcode

code oneplus, '1+'
        inc     rbx
        next
endcode

code charplus, 'char+'                  ; c-addr1 -- c-addr2
; CORE 6.1.0897
        inc     rbx
        next
endcode

code chars, 'chars'                     ; n1 -- n2
; CORE 6.1.0898
        next
endcode

code cellplus, 'cell+'                  ; a-addr1 -- a-addr2
; CORE 6.1.0880
        add      rbx, BYTES_PER_CELL
        next
endcode

code cells, 'cells'                     ; n1 -- n2
; CORE 6.1.0890
; "n2 is the size in address units of n1 cells"
        shl     rbx, 3
        next
endcode

code dplus, 'd+'                        ; d1|ud1 d2|ud2 -- d3|ud3
; DOUBLE 8.6.1.1040
        mov     rax, [rbp + BYTES_PER_CELL * 2]
        add     rax, [rbp]
        adc     rbx, [rbp + BYTES_PER_CELL]
        mov     [rbp + BYTES_PER_CELL * 2], rax
        add     rbp, BYTES_PER_CELL * 2
        next
endcode

code minus, '-'
        neg     rbx
        add     rbx, [rbp]
        add     rbp, BYTES_PER_CELL
        next
endcode

code oneminus, '1-'
        dec     rbx
        next
endcode

code star, '*'
        popd    rax
        popd    rdx
        imul    rdx
        pushd   rax
        next
endcode

code mstar, 'm*'
        popd    rax
        popd    rdx
        imul    rdx
        pushd   rax
        pushd   rdx
        next
endcode

code twostar, '2*'
        shl     rbx, 1
        next
endcode

code slash, '/'                         ; n1 n2 -- n3
; CORE
        _ slmod
        _ nip
        next
endcode

code mod, 'mod'                          ; n1 n2 -- n3
; CORE
        _ slmod
        _ drop
        next
endcode

; : */mod  (s n1 n2 n3 -- rem quot )  >r  m*  r>  m/mod  ;
; : */     (s n1 n2 n3 -- n1*n2/n3 )   */mod  nip  ;

code starslashmod, '*/mod'              ; n1 n2 n3 -- n4 n5
; CORE
        _ tor
        _ mstar
        _ rfrom
        _ fmslmod
        next
endcode

code starslash, '*/'                    ; n1 n2 n3 -- n4
; CORE
        _ starslashmod
        _ nip
        next
endcode

code twoslash, '2/'
        sar     rbx, 1
        next
endcode

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

code umslmod, 'um/mod'                  ; ud u1 -- u2 u3
; 6.1.2370 CORE
;         popd    rdx
        mov     rdx, [rbp]
        add     rbp, BYTES_PER_CELL
;         popd    rax
        mov     rax, [rbp]
        add     rbp, BYTES_PER_CELL
        div     rbx                     ; remainder in RDX, quotient in RAX
;         pushd   rdx
        sub     rbp, BYTES_PER_CELL
        mov     [rbp], rdx
        mov     rbx, rax
        next
endcode

code fmslmod, 'fm/mod'                  ; d1 n1 -- n2 n3
; CORE n2 is remainder, n3 is quotient
; gforth
        _ dup
        _ tor
        _ dup
        _ zlt
        _if fmslmod1
        _ negate
        _ tor
        _ dnegate
        _ rfrom
        _then fmslmod1
        _ over
        _ zlt
        _if fmslmod2
        _ tuck
        _ plus
        _ swap
        _then fmslmod2
        _ umslmod
        _ rfrom
        _ zlt
        _if fmslmod3
        _ swap
        _ negate
        _ swap
        _then fmslmod3
        next
endcode

code slmod, '/mod'                      ; n1 n2 -- n3 n4
        _ tor                           ; >r s>d r> fm/mod
        _ stod
        _ rfrom
        _ fmslmod
        next
endcode

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
        _ zlt
        _if smslrem1
        _ negate
        _then smslrem1
        _ rfrom
        _ zlt
        _if smslrem2
        _ swap
        _ negate
        _ swap
        _then smslrem2
        next
endcode

code muslmod, 'mu/mod'                  ; d n -- rem dquot
        _ tor
        _ zero
        _ rfetch
        _ umslmod
        _ rfrom
        _ swap
        _ tor
        _ umslmod
        _ rfrom
        next
endcode

code abs_, 'abs'
        or      rbx, rbx
        jns     abs1
        neg     rbx
abs1:
        next
endcode

code dabs, 'dabs'                       ; d -- ud
; DOUBLE
; gforth
        _ dup
        _ zlt
        _if dabs1
        _ dnegate
        _then dabs1
        next
endcode

code equal, "="                         ; x1 x2 -- flag
        popd    rax
        cmp     rbx, rax
        jne     .1
        mov     rbx, -1
        next
.1:
        xor     rbx, rbx
        next
endcode

code notequal, "<>"                     ; x1 x2 -- flag
        popd    rax
        cmp     rbx, rax
        je      .1
        mov     rbx, -1
        next
.1:
        xor     rbx, rbx
        next
endcode

code gt, '>'                            ; n1 n2 -- flag
        cmp     [rbp], rbx
        mov     ebx, 0
        jle     .1
        dec     rbx
.1:
        add     rbp, BYTES_PER_CELL
        next
endcode

code ge, '>='                           ; n1 n2 -- flag
        cmp     [rbp], rbx
        mov     ebx, 0
        jl      .1
        dec     rbx
.1:
        add     rbp, BYTES_PER_CELL
        next
endcode

code lt, '<'                            ; n1 n2 -- flag
        cmp     [rbp], rbx
        mov     ebx, 0
        jge     .1
        dec     rbx
.1:
        add     rbp, BYTES_PER_CELL
        next
endcode

code le, '<='                           ; n1 n2 -- flag
        cmp     [rbp], rbx
        mov     ebx, 0
        jg      .1
        dec     rbx
.1:
        add     rbp, BYTES_PER_CELL
        next
endcode

code ult, 'u<'
        cmp     [rbp], rbx
        mov     ebx, 0
        jae     .1
        dec     rbx
.1:
        add     rbp, BYTES_PER_CELL
        next
endcode

code within, 'within'                   ; n min max -- flag
; return true if min <= x < max
        _ over
        _ minus
        _ tor
        _ minus
        _ rfrom
        _ ult
        next
endcode

code zero?, '0='
        or      rbx, rbx
        mov     ebx, 0
        jnz     .1
        dec     rbx
.1:
        next
endcode

code dzeroequal, 'd0='
        mov     rax, [rbp]
        add     rbp, BYTES_PER_CELL
        or      rbx, rax
        jz      dze1
        xor     rbx, rbx
        next
dze1:
        mov     rbx, -1
        next
endcode

code zne, '0<>'
        or      rbx, rbx
        mov     ebx, 0
        jz      .1
        dec     rbx
.1:
        next
endcode

code zgt, '0>'
        or      rbx, rbx
        mov     ebx, 0
        jng     .1
        dec     rbx
.1:
        next
endcode

code zge, '0>='
        or      rbx, rbx
        mov     ebx, 0
        js      .1
        dec     rbx
.1:
        next
endcode

code zlt, '0<'
        or      rbx, rbx
        mov     ebx, 0
        jnl     .1
        dec     rbx
.1:
        next
endcode

code stod, 's>d'                        ; n -- d
        _ dup
        _ zlt
        next
endcode

code min, 'min'                         ; n1 n2 -- n3
        popd    rax
        cmp     rax, rbx
        jge     .1
        mov     rbx, rax
.1:
        next
endcode

code max, 'max'                         ; n1 n2 -- n3
        popd    rax
        cmp     rax, rbx
        jle     .1
        mov     rbx, rax
.1:
        next
endcode

code lshift, 'lshift'                   ; x1 u -- x2
        mov     ecx, ebx
        poprbx
        shl     rbx, cl
        next
endcode

code rshift, 'rshift'                   ; x1 u -- x2
        mov     ecx, ebx
        poprbx
        shr     rbx, cl
        next
endcode

code and, 'and'                         ; x1 x2 -- x3
; CORE
        and     rbx, [rbp]
        add     rbp, BYTES_PER_CELL
        next
endcode

code or, 'or'                           ; x1 x2 -- x3
; CORE
        or      rbx, [rbp]
        add     rbp, BYTES_PER_CELL
        next
endcode

code xor, 'xor'                         ; x1 x2 -- x3
; CORE
        xor     rbx, [rbp]
        add     rbp, BYTES_PER_CELL
        next
endcode

code invert, 'invert'                   ; x1 -- x2
; CORE
        not     rbx
        next
endcode

code negate, 'negate'                   ; n1 -- n2
; CORE
        neg     rbx
        next
endcode

code dnegate, 'dnegate'                 ; d1 -- d2
; DOUBLE
        xor     rax, rax
        mov     rdx, rax
        sub     rdx, [rbp]
        sbb     rax, rbx
        mov     [rbp], rdx
        mov     rbx, rax
        next
endcode
