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

code sp@, 'sp@'
        lea     rbp, [rbp - BYTES_PER_CELL]
        mov     [rbp], rbx
        mov     rbx, rbp
        next
endcode

code spstore, 'sp!'
        mov     rbp, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

inline drop, 'drop'
        poprbx
endinline

inline twodrop, '2drop'
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
endinline

inline threedrop, '3drop'
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
endinline

inline fourdrop, '4drop'
        mov     rbx, [rbp + BYTES_PER_CELL * 3]
        lea     rbp, [rbp + BYTES_PER_CELL * 4]
        next
endinline

inline dup, 'dup'
        pushrbx
endinline

code ?dup, '?dup'
        test    rbx, rbx
        jz      .1
        pushrbx
.1:
        next
endcode

code twodup, '2dup'
        _ over
        _ over
        next
endcode

code threedup, '3dup'                   ; x1 x2 x3 -- x1 x2 x3 x1 x2 x3
        sub     rbp, BYTES_PER_CELL * 3
        mov     [rbp + BYTES_PER_CELL * 2], rbx
        mov     rax, [rbp + BYTES_PER_CELL * 4]
        mov     [rbp + BYTES_PER_CELL], rax
        mov     rax, [rbp + BYTES_PER_CELL * 3]
        mov     [rbp], rax
        next
endcode

code rot, 'rot'                         ; x1 x2 x3 -- x2 x3 x1
        mov     rax, [rbp]                      ; x2 in RAX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; x1 in RDX
        mov     [rbp + BYTES_PER_CELL], rax     ; x2
        mov     [rbp], rbx                      ; x3
        mov     rbx, rdx                        ; x1
        next
endcode

code rrot, '-rot'                       ; x1 x2 x3 -- x3 x1 x2
        popd    rax                     ; x3
        popd    rcx                     ; x2
        popd    rdx                     ; x1
        pushd   rax
        pushd   rdx
        pushd   rcx
        next
endcode

inline over, 'over'
        mov     [rbp - BYTES_PER_CELL], rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp - BYTES_PER_CELL]
endinline

inline overplus, 'over+'
        add     rbx, [rbp]
endinline

code twoover, '2over'                   ; x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2
        mov     rax, [rbp + BYTES_PER_CELL * 2]         ; x1
        mov     rdx, [rbp + BYTES_PER_CELL ]            ; x2
        pushd   rax
        pushd   rdx
        next
endcode

inline nip, 'nip'                       ; x1 x2 -- x2
; CORE EXT
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

code tuck, 'tuck'                       ; x1 x2 -- x2 x1 x2
        popd    rax                     ; x2
        popd    rdx                     ; x1
        pushd   rax
        pushd   rdx
        pushd   rax
        next
endcode

code depth, 'depth'
        mov     rax, [sp0_data]
        sub     rax, rbp
        shr     rax, 3
        pushd   rax
        next
endcode

code rdepth, 'rdepth'
        pop     rcx                     ; return address
        mov     rax, [rp0_data]
        sub     rax, rsp
        shr     rax, 3
        pushd   rax
        push    rcx
        next
endcode

code pick, 'pick'
; REVIEW error handling
        shl     rbx, 3
        add     rbx, rbp
        mov     rbx, [rbx]
        next
endcode

code dots, '.s'
        _lit '<'
        _ emit
        _ depth
        _ paren_dot
        _ type
        _lit '>'
        _ emit
        _ space
        _ depth
        mov     rcx, rbx
        jrcxz   .2
.1:
        push    rcx
        pushd   rcx
        _ pick
        _ dot
        pop     rcx
        loop    .1
.2:
        poprbx
        next
endcode

code dotrs, '.rs'
        _lit '<'
        _ emit
        _ rdepth
        _ paren_dot
        _ type
        _lit '>'
        _ emit
        _ space
        _ rdepth
        mov     rcx, rbx                ; depth in RCX
        jrcxz   .2
.1:
        mov     rax, rcx
        shl     rax, 3
        add     rax, rsp
        pushrbx
        mov     rbx, [rax]
        push    rcx
        _ dot
        pop     rcx
        dec     rcx
        jnz     .1
.2:
        poprbx
        next
endcode

inline swap, 'swap'
        mov     rax, rbx
        mov     rbx, [rbp]
        mov     [rbp], rax
endinline

code twoswap, '2swap'                   ; x1 x2 x3 x4 -- x3 x4 x1 x2
        mov     rax, [rbp]                              ; x3
        mov     rdx, [rbp + BYTES_PER_CELL]             ; x2
        mov     rcx, [rbp + BYTES_PER_CELL * 2]         ; x1
        mov     [rbp + BYTES_PER_CELL * 2], rax         ; x3
        mov     [rbp + BYTES_PER_CELL], rbx             ; x4
        mov     [rbp], rcx                              ; x1
        mov     rbx, rdx
        next
endcode

code tor, '>r'
        pop     rax                     ; return address
        push    rbx
        poprbx
        jmp     rax
        next                            ; for disassembler
endcode

code duptor, 'dup>r'
        pop     rax
        push    rbx
        jmp     rax
        next
endcode

code rfetch, 'r@'
        pop     rax                     ; return address
        pushrbx
        mov     rbx, [rsp]
        jmp     rax
        next                            ; for disassembler
endcode

code rfrom, 'r>'
        pop     rax                     ; return address
        pushrbx
        pop     rbx
        jmp     rax
        next                            ; for disassembler
endcode

code rfromdrop, 'r>drop'
        pop     rax                     ; return address
        pop     rdx                     ; discard
        jmp     rax
        next
endcode

code rpfetch, 'rp@'
        pushrbx
        mov     rbx, rsp
        add     rbx, BYTES_PER_CELL
        next
endcode

code rpstore, 'rp!'
        pop     rax                     ; return address
        mov     rsp, rbx
        poprbx
        jmp     rax
endcode

code twotor, '2>r'                      ; x1 x2 --      r: -- x1 x2
; CORE EXT
; "Interpretation: Interpretation semantics for this word are undefined."
        pop     rax                     ; return address
        push    qword [rbp]
        push    rbx
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        jmp     rax
        next
endcode

code tworfrom, '2r>'                    ; -- x1 x2      r: x1 x2 --
; CORE EXT
; "Interpretation: Interpretation semantics for this word are undefined."
        pop     rax                     ; return address
        mov     [rbp - BYTES_PER_CELL], rbx
        pop     rbx
        pop     qword [rbp - BYTES_PER_CELL * 2]
        lea     rbp, [rbp - BYTES_PER_CELL * 2]
        jmp     rax
        next
endcode

code tworfetch, '2r@'                   ; -- x1 x2      r: x1 x2 -- x1 x2
; CORE EXT
; "Interpretation: Interpretation semantics for this word are undefined."
        pop     rax                     ; return address
        mov     [rbp - BYTES_PER_CELL], rbx
        mov     rdx, [rsp + BYTES_PER_CELL]
        mov     rbx, [rsp]
        mov     [rbp - BYTES_PER_CELL * 2], rdx
        lea     rbp, [rbp - BYTES_PER_CELL * 2]
        jmp     rax
        next
endcode

code ntor, 'n>r'                        ; i*n +n --     r: -- j*x +n
; Forth 200x TOOLS EXT
; "Interpretation semantics for this word are undefined."
        _ dup
        _begin ntor1
        _ dup
        _while ntor1
        _ rot
        _rfrom
        _ swap
        _tor
        _tor
        _oneminus
        _repeat ntor1
        _ drop
        _ rfrom
        _ swap
        _tor
        _tor
        next
endcode

code nrfrom, 'nr>'                      ; -- i*x +n     r: j*x +n --
; Forth 200x TOOLS EXT
; "Interpretation semantics for this word are undefined."
        _rfrom
        _rfrom
        _ swap
        _tor
        _ dup
        _begin nrfrom1
        _ dup
        _while nrfrom1
        _rfrom
        _rfrom
        _ swap
        _tor
        _ rrot
        _oneminus
        _repeat nrfrom1
        _ drop
        next
endcode
