; Copyright (C) 2012-2017 Peter Graves <gnooth@gmail.com>

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

; ### ?dup
inline ?dup, '?dup'
        _?dup
endinline

%macro  _depth 0
        mov     rax, [sp0_data]
        sub     rax, rbp
        shr     rax, 3
        pushd   rax
%endmacro

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
        _twotor
        jmp     rax
        next
endcode

; ### 2r>
code tworfrom, '2r>'                    ; -- x1 x2      r: x1 x2 --
; CORE EXT
; "Interpretation: Interpretation semantics for this word are undefined."
        pop     rax                     ; return address
        _tworfrom
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
