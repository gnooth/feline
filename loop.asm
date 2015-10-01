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

; ### (?do)
inline i?do, '(?do)'                    ; limit index --        r: leave-addr --
        cmp     rbx, [rbp]
        jne     .1
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        ret                             ; same as jumping to leave-addr
.1:
        _do_common
endinline

; ### (do)
inline ido, '(do)'                      ; limit index --
        _do_common
endinline

; ### do
code do, 'do', IMMEDIATE                ; -- addr
        _ ?comp
        _ flush_compilation_queue

        _lit $48
        _ ccommac
        _lit $0b8                       ; mov rax, imm64
        _ ccommac
        _ here_c                        ; address to be patched by LOOP or +LOOP
        _zero                          ; placeholder for address of LEAVE code
        _ commac
        _lit $50                        ; push rax
        _ ccommac

        _lit ido_xt
        _ copy_code

        _ align_code

        _ here_c                        ; address to jump back to at bottom of loop
        next
endcode

; ### ?do
code ?do, '?do', IMMEDIATE               ; -- addr
        _ ?comp
        _ flush_compilation_queue

        _lit $48
        _ ccommac
        _lit $0b8
        _ ccommac
        _ here_c                        ; address to be patched
        _zero
        _ commac
        _lit $50                        ; push rax
        _ ccommac

        _lit i?do_xt
        _ copy_code

        _ align_code

        _ here_c

        next
endcode

section .text
doloop:
        inc     qword [rsp]                             ; 48 FF 04 24
        jno     0                       ; <-- patch     ; 0F 81 00 00 00 00
doloop_patch    equ     $ - 4
        add     rsp, BYTES_PER_CELL * 3                 ; 48 83 C4 18
doloop_end:

; ### loop
code loop, 'loop', IMMEDIATE            ; addr1 addr2 --
                                        ; addr1 is where we need to put the LEAVE address
                                        ; addr2 is top of loop (after setup code)
        _ ?comp
        _ flush_compilation_queue

        ; move top of loop address to return stack
        _ tor                           ; -- address-to-be-patched-with-LEAVE-address
                                        ; r: -- top-of-loop-addr

        ; copy the first part of the doloop code
        _lit doloop
        _lit doloop_patch - doloop
        _ paren_copy_code

        ; compute the offset back to the top of the loop
        _ here_c
        add     rbx, 4                  ; address of first byte of next instruction
        _ rfrom
        _ swap
        _ minus                         ; -- offset
        _ lcommac

        _lit $18c48348                  ; add rsp, 24
        _ lcommac

        ; patch the setup code with the LEAVE address
        _ here_c                        ; this is the LEAVE address
        _ swap                          ; -- LEAVE-addr addr-to-be-patched
        _ store                         ; --

        next
endcode

section .text
doplusloop:
        add     qword [rsp], rbx
        poprbx
        jno     0                       ; <-- patch     ; 0F 81 00 00 00 00
doplusloop_patch    equ     $ - 4
        add     rsp, BYTES_PER_CELL * 3                 ; 48 83 C4 18
doplusloop_end:

; ### +loop
code plusloop, '+loop', IMMEDIATE       ; addr1 addr2 --
                                        ; addr1 is where we need to put the LEAVE address
                                        ; addr2 is top of loop (after setup code)
        _ ?comp
        _ flush_compilation_queue

        ; move top of loop address to return stack
        _ tor                           ; -- address-to-be-patched-with-LEAVE-address
                                        ; r: -- top-of-loop-addr

        ; copy the first part of the doplusloop code
        _lit doplusloop
        _lit doplusloop_patch - doplusloop
        _ paren_copy_code

        ; compute the offset back to the top of the loop
        _ here_c
        add     rbx, 4                  ; address of first byte of next instruction
        _ rfrom
        _ swap
        _ minus                         ; -- offset
        _ lcommac

        _lit $18c48348                  ; add rsp, 24
        _ lcommac

        ; patch the setup code with the LEAVE address
        _ here_c                        ; this is the LEAVE address
        _ swap                          ; -- LEAVE-addr addr-to-be-patched
        _ store                         ; --

        next
endcode

; ### inline-leave
inline inline_leave, 'inline-leave'
        _leave
endinline

; ### leave
code leave, 'leave', IMMEDIATE
        _ ?comp
        _ flush_compilation_queue
        _lit inline_leave_xt
        _ copy_code
        next
endcode

; ### inline-i
inline inline_i, 'inline-i'
        _i
endinline

; ### i
code i, 'i', IMMEDIATE
        _ ?comp
;         _ flush_compilation_queue
;         _lit inline_i_xt
;         _ copy_code
        _lit inline_i_xt
        _ compilecomma
        next
endcode

; ### inline-i+
inline inline_i_plus, 'inline-i+'
        _i_plus
endinline

; ### j
; FIXME should be immediate compile-only
; runtime should be inline
code j, 'j'
; CORE
; "Interpretation semantics for this word are undefined."
        pushrbx
        mov     rbx, [rsp + BYTES_PER_CELL * 4]
        add     rbx, [rsp + BYTES_PER_CELL * 5]
        next
endcode

; ### inline-unloop
inline inline_unloop, 'inline-unloop'
        _unloop
endinline

; ### unloop
code unloop, 'unloop', IMMEDIATE
        _ ?comp
        _ flush_compilation_queue
        _lit inline_unloop_xt
        _ copy_code
        next
endcode

; ### bounds
code bounds, 'bounds'                   ; addr len -- addr+len addr
        _ over
        _ plus
        _ swap
        next
endcode
