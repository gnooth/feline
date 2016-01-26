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

; ### d+
code dplus, 'd+'                        ; d1|ud1 d2|ud2 -- d3|ud3
; DOUBLE 8.6.1.1040
        mov     rax, [rbp + BYTES_PER_CELL * 2]
        add     rax, [rbp]
        adc     rbx, [rbp + BYTES_PER_CELL]
        mov     [rbp + BYTES_PER_CELL * 2], rax
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        next
endcode

; ### d-
code dminus, 'd-'                       ; d1|ud1 d2|ud2 -- d3|ud3
; DOUBLE
        ; high word of d2 in rbx
        ; low word of d2 in [rbp]
        ; high word of d1 in [rbp+8]
        ; low word of d1 in [rbp+16]
        mov     rax, [rbp + BYTES_PER_CELL * 2] ; rax = low word of d1
        sub     rax, [rbp]                      ; subtract low word of d2
        sbb     [rbp + BYTES_PER_CELL], rbx     ; subtract high word of d2 from high word of d1
        mov     rbx, [rbp + BYTES_PER_CELL]     ; high word of d3 in rbx
        mov     [rbp + BYTES_PER_CELL * 2], rax
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        next
endcode

; ### d0=
code dzeroequal, 'd0='                  ; xd -- flag
; DOUBLE
        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        or      rbx, rax
        jz      .1
        xor     rbx, rbx
        next
.1:
        mov     rbx, -1
        next
endcode

; ### d0<
code dzerolt, 'd0<'                     ; d -- flag
; DOUBLE
        _nip
        _zlt
        next
endcode

; ### d=
code dequal, 'd='                       ; xd1 xd2 -- flag
; DOUBLE
; adapted from Win32Forth
        mov     rax, [rbp + BYTES_PER_CELL * 2]
        sub     rax, [rbp]
        sbb     rbx, [rbp + BYTES_PER_CELL]
        or      rbx, rax
        sub     rbx, 1
        sbb     rbx, rbx
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        next
endcode

; ### du<
code dult, 'du<'                        ; d1 d2 -- flag
; DOUBLE
        ; high word of d2 in rbx
        ; low word of d2 in [rbp]
        ; high word of d1 in [rbp+8]
        ; low word of d1 in [rbp+16]
        mov     rax, [rbp]              ; low word of d2
        cmp     [rbp + BYTES_PER_CELL * 2], rax
        sbb     [rbp + BYTES_PER_CELL], rbx
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        jb      .1
        xor     ebx, ebx
        _return
.1:
        mov     rbx, -1
        next
endcode

; ### d<
code dlt, 'd<'                          ; d1 d2 -- flag
; DOUBLE
        ; high word of d2 in rbx
        ; low word of d2 in [rbp]
        ; high word of d1 in [rbp+8]
        ; low word of d1 in [rbp+16]
        mov     rax, [rbp]              ; low word of d2
        cmp     [rbp + BYTES_PER_CELL * 2], rax
        sbb     [rbp + BYTES_PER_CELL], rbx
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        jl      .1
        xor     ebx, ebx
        _return
.1:
        mov     rbx, -1
        next
endcode

; ### d>
code dgt, 'd>'                          ; d1 d2 -- flag
; not in standard
        _ twoswap
        _ dlt
        next
endcode

; ### d2*
code dtwostar, 'd2*'                    ; xd1 -- xd2
; DOUBLE
        shl     qword [rbp], 1          ; low word
        rcl     rbx, 1                  ; high word
        next
endcode

; ### d2/
code dtwoslash, 'd2/'                   ; xd1 -- xd2
; DOUBLE
        sar     rbx, 1
        rcr     qword [rbp], 1
        next
endcode

; ### dabs
code dabs, 'dabs'                       ; d -- ud
; DOUBLE
; gforth
        _ dup
        _zlt
        _if dabs1
        _ dnegate
        _then dabs1
        next
endcode

; ### dnegate
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

; ### dmax
code dmax, 'dmax'                       ; d1 d2 -- d3
; DOUBLE
; gforth
        _ twoover
        _ twoover
        _ dlt
        _if .1
        _ twoswap
        _then .1
        _2drop
        next
endcode

; ### dmin
code dmin, 'dmin'                       ; d1 d2 -- d3
; DOUBLE
; gforth
        _ twoover
        _ twoover
        _ dgt
        _if .1
        _ twoswap
        _then .1
        _2drop
        next
endcode

; ### d>s
inline dtos, 'd>s'                      ; d -- n
; DOUBLE
        _dtos
endinline

; ### m+
code mplus, 'm+'                        ; d1|ud1 n -- d2|ud2
; DOUBLE
        ; n in rbx
        ; high word of d1 in [rbp]
        ; low word of d1 in [rbp+8]
        mov     rax, rbx                ; n in rax
        cqo                             ; sign-extend rax into rdx:rax
        add     rax, [rbp + BYTES_PER_CELL]
        adc     rdx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     rbx, rdx                ; high word
        mov     [rbp], rax              ; low word
        next
endcode

