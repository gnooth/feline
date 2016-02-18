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

; ### scan
code scan, 'scan'                       ; c-addr1 u1 char -- c-addr2 u2
; not in standard
        popd    rax                     ; char in al
.1:                                     ; -- addr u
        test    rbx, rbx                ; u = 0?
        jz      .2                      ; u = 0, we're done
        mov     rdx, [rbp]              ; addr in rdx
        cmp     [rdx], al               ; is char at addr the char we're looking for?
        je      .2                      ; if so, we're done
        sub     rbx, 1                  ; otherwise decrement u
        add     qword [rbp], 1          ; and increment addr
        jmp     .1
.2:
        next
endcode

; ### skip-whitespace
code skip_whitespace, 'skip-whitespace' ; c-addr1 u1 -- c-addr2 u2
        _begin .1
        _dup
        _zgt
        _while .1
        _over
        _cfetch
        _ blchar
        _ gt
        _if .2
        _return
        _then .2
        _lit 1
        _slashstring
        _repeat .1
        next
endcode

; ### scan-to-whitespace
code scan_to_whitespace, 'scan-to-whitespace'   ; c-addr1 u1 -- c-addr2 u2
        _begin .1
        _dup
        _zgt
        _while .1
        _over
        _cfetch
        _ blchar
        _ le
        _if .2
        _return
        _then .2
        _lit 1
        _slashstring
        _repeat .1
        next
endcode

; ### /source
code slashsource, '/source'             ; -- c-addr u
        _ source
        _from toin
        _slashstring
        next
endcode

; ### parse
code parse, 'parse'                     ; char "ccc<char>" -- c-addr u
; CORE EXT 6.2.2008
        _ slashsource
        _over
        _tor                            ; delim addr1 len1      r: addr1
        _ rot
        _ scan                          ; addr2 len2            r: addr1
        _drop
        _rfetch                         ; addr2 addr1           r: addr1
        _minus                          ; len                   r: addr1
        _dup
        _oneplus
        _plusto toin                    ; len                   r: addr1
        _rfrom
        _swap
        next
endcode

; ### parse-name
code parse_name, 'parse-name'           ; <spaces>name -- c-addr u
; Forth 200x CORE EXT 6.2.2020
; "Skip leading white space and parse name delimited by a white space character.
; c-addr is the address within the input buffer and u is the length of the
; selected string. If the parse area is empty or contains only white space, the
; resulting string has length zero."
        _ source                        ; -- source-addr source-length
        _ tuck                          ; -- source-length source-addr source-length
        _from toin                      ; -- source-length source-addr source-length >in
        _slashstring                    ; -- source-length addr1 #left
        _ skip_whitespace               ; -- source-length start-of-word #left
        _overswap                       ; -- source-length start-of-word start-of-word #left
        _ scan_to_whitespace            ; -- source-length start-of-word end-of-word #left
        _tor                            ; -- source-length start-of-word end-of-word                    r: #left
        _overminus                      ; -- source-length start-of-word word-length
        _ rot                           ; -- start-of-word word-length source-length
        _rfrom                          ; -- start-of-word word-length source-length #left              r: --
        _dup                            ; -- start-of-word word-length source-length #left #left
        _ zne                           ; -- start-of-word word-length source-length #left -1|0
        _plus                           ; -- start-of-word word-length source-length #left-1|#left
        _minus
        _to toin
        next
endcode

; ### char
code char, 'char'                       ; "<spaces>name" -- char
; 6.1.0895 CORE
        _ parse_name                    ; -- addr len
        _if .1
        movzx   rbx, byte [rbx]
        _else .1
        xor     ebx, ebx
        _then .1
        next
endcode

; ### [char]
code bracket_char, '[char]', IMMEDIATE
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ char
        _ iliteral
        next
endcode

value word_buffer, 'word-buffer', 0     ; initialized in main()

; ### word
code forth_word, 'word'                 ; char "<chars>ccc<char>" -- c-addr
; CORE
; "WORD always skips leading delimiters."
        _dup
        _ blchar
        _ equal
        _if .1
        _drop
        _ parse_name
        _else .1
        ; BUG! PARSE does not skip leading delimiters!
        _ parse                         ; -- addr len
        _then .1
        _ word_buffer
        _ place
        _ word_buffer
        next
endcode

value word_start, 'word-start', 0

; ### blword
code blword, 'blword'                   ; "<chars>ccc<char>" -- c-addr
        _ parse_name                    ; -- c-addr u
        _over
        _to word_start
        _ word_buffer
        _duptor
        _ place
        _rfrom
        next
endcode

; ### (
code paren, '(', IMMEDIATE
        _begin .1
        _ slashsource
        _lit ')'
        _ scan
        _nip
        _if .2
        _lit ')'
        _ parse
        _2drop
        _return
        _then .2
        _ refill
        _zeq
        _until .1
        next
endcode

; ### \
; We need some additional comment text here so that NASM isn't
; confused by the '\' in the explicit tag.
; "NASM uses backslash (\) as the line continuation character;
; if a line ends with backslash, the next line is considered to
; be a part of the backslash-ended line."
code backslash, '\', IMMEDIATE
        _lit 10
        _ parse
        _2drop
        next
endcode

; ### .(
code dotparen, '.(', IMMEDIATE
; CORE EXT
; ".( is an immediate word."
        _ flush_compilation_queue
        _lit ')'
        _ parse
        _ type
        next
endcode
