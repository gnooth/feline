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

; ### parsed-name-start
value parsed_name_start,  'parsed-name-start',  0

; ### parsed-name-length
value parsed_name_length, 'parsed-name-length', 0

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
        _dupd                           ; -- source-length start-of-word start-of-word #left
        _ scan_to_whitespace            ; -- source-length start-of-word end-of-word #left
        _tor                            ; -- source-length start-of-word end-of-word                    r: #left
        _over_minus                     ; -- source-length start-of-word word-length
        _ rot                           ; -- start-of-word word-length source-length
        _rfrom                          ; -- start-of-word word-length source-length #left              r: --
        _dup                            ; -- start-of-word word-length source-length #left #left
        _ zne                           ; -- start-of-word word-length source-length #left -1|0
        _plus                           ; -- start-of-word word-length source-length #left-1|#left
        _minus
        _to toin

        _twodup
        _to parsed_name_length
        _to parsed_name_start

        next
endcode

value word_buffer, 'word-buffer', 0     ; initialized in main()

; ### blword
code blword, 'blword'                   ; "<chars>ccc<char>" -- c-addr
        _ parse_name                    ; -- c-addr u
        _ word_buffer
        _duptor
        _ place
        _rfrom
        next
endcode
