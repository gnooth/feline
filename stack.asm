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

code sp@, 'sp@'
        mov     rax, rsp
        pushd   rax
        next
endcode

code drop, 'drop'
        poprbx
        next
endcode

code twodrop, '2drop'
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        next
endcode

code threedrop, '3drop'
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        next
endcode

code fourdrop, '4drop'
        mov     rbx, [rbp + BYTES_PER_CELL * 3]
        lea     rbp, [rbp + BYTES_PER_CELL * 4]
        next
endcode

code dup, 'dup', 0, dup_ret - dup
        pushrbx
dup_ret:
        next
endcode

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

code over, 'over'
        mov     [rbp - BYTES_PER_CELL], rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp - BYTES_PER_CELL]
        next
endcode

code twoover, '2over'                   ; x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2
        mov     rax, [rbp + BYTES_PER_CELL * 2]         ; x1
        mov     rdx, [rbp + BYTES_PER_CELL ]            ; x2
        pushd   rax
        pushd   rdx
        next
endcode

code nip, 'nip'                         ; x1 x2 -- x2
; CORE EXT
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

code tuck, 'tuck'                       ; x1 x2 -- x2 x1 x2
        popd    rax                     ; x2
        popd    rdx                     ; x1
        pushd   rax
        pushd   rdx
        pushd   rax
        next
endcode

code depth, 'depth'
        mov     rax, [s0_data]
        sub     rax, rbp
        shr     rax, 3
        pushd   rax
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
        pushd   '<'
        _ emit
        _ depth
        _ paren_dot
        _ type
        pushd   '>'
        _ emit
        _ space
        _ depth
        mov     rcx, rbx
        test    rcx, rcx
        jle     .empty
.loop:
        push    rcx
        pushd   rcx
        _ pick
        _ dot
        pop     rcx
        dec     rcx
        jnz     .loop
        poprbx
        next
.empty:
        poprbx
        next
endcode

code swap, 'swap'
        mov     rax, rbx
        mov     rbx, [rbp]
        mov     [rbp], rax
        next
endcode

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
