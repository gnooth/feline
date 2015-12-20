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

; ### sp@
code spfetch, 'sp@'
        lea     rbp, [rbp - BYTES_PER_CELL]
        mov     [rbp], rbx
        mov     rbx, rbp
        next
endcode

; ### sp!
code spstore, 'sp!'
        mov     rbp, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### drop
inline drop, 'drop'
        _drop
endinline

; ### 2drop
inline twodrop, '2drop'
        _2drop
endinline

; ### 3drop
inline threedrop, '3drop'
        _3drop
endinline

; ### 4drop
inline fourdrop, '4drop'
        mov     rbx, [rbp + BYTES_PER_CELL * 3]
        lea     rbp, [rbp + BYTES_PER_CELL * 4]
endinline

; ### dup
inline dup, 'dup'
        _dup
endinline

; ### ?dup
code ?dup, '?dup'
        test    rbx, rbx
        jz      .1
        pushrbx
.1:
        next
endcode

; ### 2dup
code twodup, '2dup'                     ; x1 x2 -- x1 x2 x1 x2
; CORE
        mov     rax, [rbp]
        lea     rbp, [rbp - BYTES_PER_CELL * 2]
        mov     [rbp], rax
        mov     [rbp + BYTES_PER_CELL], rbx
        next
endcode

; ### 3dup
code threedup, '3dup'                   ; x1 x2 x3 -- x1 x2 x3 x1 x2 x3
        sub     rbp, BYTES_PER_CELL * 3
        mov     [rbp + BYTES_PER_CELL * 2], rbx
        mov     rax, [rbp + BYTES_PER_CELL * 4]
        mov     [rbp + BYTES_PER_CELL], rax
        mov     rax, [rbp + BYTES_PER_CELL * 3]
        mov     [rbp], rax
        next
endcode

; ### rot
code rot, 'rot'                         ; x1 x2 x3 -- x2 x3 x1
        mov     rax, [rbp]                      ; x2 in RAX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; x1 in RDX
        mov     [rbp + BYTES_PER_CELL], rax     ; x2
        mov     [rbp], rbx                      ; x3
        mov     rbx, rdx                        ; x1
        next
endcode

; ### -rot
code rrot, '-rot'                       ; x1 x2 x3 -- x3 x1 x2
        popd    rax                     ; x3
        popd    rcx                     ; x2
        popd    rdx                     ; x1
        pushd   rax
        pushd   rdx
        pushd   rcx
        next
endcode

; ### over
inline over, 'over'
        mov     [rbp - BYTES_PER_CELL], rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp - BYTES_PER_CELL]
endinline

; ### over+
inline overplus, 'over+'
        _overplus
endinline

; ### +dup
inline plusdup, '+dup'
        _plusdup
endinline

; ### 2over
code twoover, '2over'                   ; x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2
        mov     rax, [rbp + BYTES_PER_CELL * 2]         ; x1
        mov     rdx, [rbp + BYTES_PER_CELL ]            ; x2
        pushd   rax
        pushd   rdx
        next
endcode

; ### nip
inline nip, 'nip'                       ; x1 x2 -- x2
; CORE EXT
        _nip
endinline

; ### tuck
code tuck, 'tuck'                       ; x1 x2 -- x2 x1 x2
; CORE EXT
        mov     rax, [rbp]              ; x1 in rax, x2 in rbx
        mov     [rbp], rbx
        mov     [rbp - BYTES_PER_CELL], rax
        lea     rbp, [rbp - BYTES_PER_CELL]
        next
endcode

; ### depth
code depth, 'depth'
        mov     rax, [sp0_data]
        sub     rax, rbp
        shr     rax, 3
        pushd   rax
        next
endcode

; ### rdepth
code rdepth, 'rdepth'
        pop     rcx                     ; return address
        mov     rax, [rp0_data]
        sub     rax, rsp
        shr     rax, 3
        pushd   rax
        push    rcx
        next
endcode

; ### pick
code pick, 'pick'
; REVIEW error handling
        shl     rbx, 3
        add     rbx, rbp
        mov     rbx, [rbx]
        next
endcode

; ### roll
code roll, 'roll'                       ; n1 n2 ... nk k -- n2 n3 ... nk n1
; CORE EXT
; Win32Forth
; "Rotate k values on the stack, bringing the deepest to the top."
        _duptor
        _ pick
        _ spfetch
        _dup
        _cellplus
        _ rfrom
        _cells
        _cellplus
        _ move
        _drop
        next
endcode

; ### .s
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

; ### .rs
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

; ### swap
inline swap, 'swap'
        mov     rax, rbx
        mov     rbx, [rbp]
        mov     [rbp], rax
endinline

; ### 2swap
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

; ### >r
code tor, '>r'
        pop     rax                     ; return address
        push    rbx
        poprbx
        jmp     rax
        next                            ; for disassembler
endcode

; ### dup>r
code duptor, 'dup>r'
        pop     rax
        push    rbx
        jmp     rax
        next
endcode

; ### r@
code rfetch, 'r@'
        pop     rax                     ; return address
        pushrbx
        mov     rbx, [rsp]
        jmp     rax
        next                            ; for disassembler
endcode

; ### r>
code rfrom, 'r>'
        pop     rax                     ; return address
        pushrbx
        pop     rbx
        jmp     rax
        next                            ; for disassembler
endcode

; ### r>drop
code rfromdrop, 'r>drop'
        pop     rax                     ; return address
        pop     rdx                     ; discard
        jmp     rax
        next
endcode

; ### rp@
code rpfetch, 'rp@'
        pushrbx
        mov     rbx, rsp
        add     rbx, BYTES_PER_CELL
        next
endcode

; ### rp!
code rpstore, 'rp!'
        pop     rax                     ; return address
        mov     rsp, rbx
        poprbx
        jmp     rax
endcode

; ### 2>r
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

; ### 2r>
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

; ### 2r@
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

; ### n>r
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

; ### nr>
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
