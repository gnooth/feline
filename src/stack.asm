; Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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
inline ?dup, '?dup'
        _?dup
endinline

; ### 2dup
inline twodup, '2dup'                   ; x1 x2 -- x1 x2 x1 x2
; CORE
        _twodup
endinline

; ### 3dup
code threedup, '3dup'                   ; x1 x2 x3 -- x1 x2 x3 x1 x2 x3
        lea     rbp, [rbp - BYTES_PER_CELL * 3]
        mov     [rbp + BYTES_PER_CELL * 2], rbx
        mov     rax, [rbp + BYTES_PER_CELL * 4]
        mov     [rbp + BYTES_PER_CELL], rax
        mov     rax, [rbp + BYTES_PER_CELL * 3]
        mov     [rbp], rax
        next
endcode

; ### rot
code rot, 'rot'                         ; x1 x2 x3 -- x2 x3 x1
; CORE
        mov     rax, [rbp]                      ; x2 in RAX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; x1 in RDX
        mov     [rbp + BYTES_PER_CELL], rax     ; x2
        mov     [rbp], rbx                      ; x3
        mov     rbx, rdx                        ; x1
        next
endcode

; ### -rot
code rrot, '-rot'                       ; x1 x2 x3 -- x3 x1 x2
; not in standard
        mov     rax, [rbp]                      ; x2 in RAX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; x1 in RDX
        mov     [rbp + BYTES_PER_CELL], rbx     ; x3
        mov     [rbp], rdx                      ; x1
        mov     rbx, rax                        ; x2
        next
endcode

; ### over
inline over, 'over'
        _over
endinline

; ### over+
inline overplus, 'over+'
        _overplus
endinline

; ### over-
inline over_minus, 'over-'
        _over_minus
endinline

; ### dupd
inline dupd, 'dupd'
        _dupd
endinline

; ### +dup
inline plusdup, '+dup'
        _plusdup
endinline

; ### 2over
inline forth_2over, '2over'             ; x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2
; CORE
        _forth_2over
endinline

; ### nip
inline nip, 'nip'                       ; x1 x2 -- x2
; CORE EXT
        _nip
endinline

; ### 2nip
inline twonip, '2nip'                   ; x y z -- z
        _2nip
endinline

; ### tuck
code tuck, 'tuck'                       ; x1 x2 -- x2 x1 x2
; CORE EXT
        _tuck
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
inline forth_pick, 'pick'
        _forth_pick
endinline

; ### roll
code roll, 'roll'                       ; n1 n2 ... nk k -- n2 n3 ... nk n1
; CORE EXT
; Win32Forth
; "Rotate k values on the stack, bringing the deepest to the top."
        _duptor
        _forth_pick
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
code dot_s, '.s'
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
        _forth_pick
        _ dot
        pop     rcx
        loop    .1
.2:
        poprbx
        next
endcode

; ### hex.s
code hex_dot_s, 'hex.s'
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
        _forth_pick
        _ hdot
        pop     rcx
        loop    .1
.2:
        poprbx
        next
endcode

; ### .rs
code dot_rs, '.rs'
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
inline swap, 'swap'                     ; x1 x2 -- x2 x1
        _swap
endinline

; ### swapd
code swapd, 'swapd'                     ; x y z -- y x z
        mov     rax, [rbp]
        mov     rdx, [rbp + BYTES_PER_CELL]
        mov     [rbp + BYTES_PER_CELL], rax
        mov     [rbp], rdx
        next
endcode

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

; ### rdrop
code rdrop, 'rdrop'
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
        _begin .1
        _ dup
        _while .1
        _ rot
        _rfrom
        _ swap
        _tor
        _tor
        _oneminus
        _repeat .1
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
        _begin .1
        _ dup
        _while .1
        _rfrom
        _rfrom
        _ swap
        _tor
        _ rrot
        _oneminus
        _repeat .1
        _ drop
        next
endcode

; ### 0-over
inline zero_over, '0-over'              ; x -- x 0 x
        lea     rbp, [rbp-16]
        mov     [rbp+8], rbx
        mov     qword [rbp], 0
endinline
