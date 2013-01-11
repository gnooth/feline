; Copyright (C) 2012-2013 Peter Graves <gnooth@gmail.com>

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

code noop, 'noop'
        next
endcode

deferred clear_compilation_queue, 'clear-compilation-queue', noop

deferred flush_compilation_queue, 'flush-compilation-queue', noop

code paren_copy_code, '(copy-code)'     ; addr size --
        _ here_c
        _ over
        _ allot_c
        _ swap
        _ cmove
        next
endcode

code copy_code, 'copy-code'             ; xt --
        _ dup                           ; -- xt xt
        _ toinline                      ; -- xt addr
        _ cfetch                        ; -- xt size
        _ swap
        _ tocode
        _ swap                          ; -- code size
        _ paren_copy_code
        next
endcode

variable optimizing?, 'optimizing?', -1

code plusopt, '+opt'
        mov     qword [optimizing?_data], -1
        next
endcode

code minusopt, '-opt'
        mov     qword [optimizing?_data], 0
        next
endcode

code parencompilecomma, '(compile,)'    ; xt --
; CORE EXT
; "Interpretation semantics for this word are undefined."
        _ optimizing?
        _fetch
        _if compilecomma1               ; -- xt
        _ dup                           ; -- xt xt
        _ tocomp                        ; -- xt >comp
        _fetch                          ; -- xt ct
        _ ?dup
        _if compilecomma2
        _ execute
        _return
        _then compilecomma2             ; -- xt
        _ dup                           ; -- xt xt
        _ toinline                      ; -- xt >inline
        _cfetch                         ; -- xt #bytes
        _if compilecomma3
        _ copy_code
        _return
        _then compilecomma3
        _then compilecomma1
        ; not optimizing
        _ tocode
        _ commacall
        next
endcode

deferred compilecomma, 'compile,', parencompilecomma

variable last_code, 'last-code', 0

variable csp, 'csp', 0

code storecsp, '!csp'
        mov     [csp_data], rbp
        next
endcode

code ?csp, '?csp'
        cmp     [csp_data], rbp
        je      .1
        _abortq "Stack changed"
.1:
        next
endcode

code colon, ':'
        _ clear_compilation_queue
        _ header
        _ hide
        _ here_c
        _ dup
        _ last_code
        _ store
        _ latest
        _ namefrom
        _ store
        _ rbrack
        _ storecsp
        next
endcode

code colonnoname, ':noname'
        _ clear_compilation_queue
        _ rbrack
        _ here                          ; address of xt to be created
        _ here_c                        ; code address
        _ dup
        _ last_code
        _ store
        _ comma
        _ zero                          ; comp field
        _ comma
        _ storecsp
        next
endcode

code semi, ';', IMMEDIATE
        _ flush_compilation_queue
        _ ?csp
        _lit $0c3                       ; RET
        _ ccommac
        _ lbrack
        _ reveal
        next
endcode
