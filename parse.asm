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

; ### scan
code scan, 'scan'                       ; c-addr1 u1 char -- c-addr2 u2
        _tor                            ; -- c-addr1 u1                 r: -- char
        _begin scan1
        _dup                            ; -- c-addr u u                 r: -- char
        _while scan1
        _ over                          ; -- c-addr u c-addr            r: -- char
        _cfetch
        _rfetch
        _ equal                         ; -- c-addr u                   r: -- char
        _if scan2
        _rfromdrop
        next
        _then scan2
        _ one
        _ slashstring
        _repeat scan1                   ; -- c-addr u                   r: -- char
        _rfromdrop
        next
endcode

; ### skipwhite
code skipwhite, 'skipwhite'             ; c-addr1 u1 -- c-addr2 u2
        _begin skipwhite1
        _ dup
        _ zgt
        _while skipwhite1
        _ over
        _ cfetch
        _ blchar
        _ gt
        _if skipwhite2
        _return
        _then skipwhite2
        _ one
        _ slashstring
        _repeat skipwhite1
        next
endcode

; ### scantowhite
code scantowhite, 'scantowhite'         ; c-addr1 u1 -- c-addr2 u2
        _begin scantowhite1
        _ dup
        _ zgt
        _while scantowhite1
        _ over
        _ cfetch
        _ blchar
        _ le
        _if scantowhite2
        _return
        _then scantowhite2
        _ one
        _ slashstring
        _repeat scantowhite1
        next
endcode

; ### /source
code slashsource, '/source'             ; -- c-addr u
        _ source
        _ toin
        _fetch
        _ slashstring
        next
endcode

; ### parse
code parse, 'parse'                     ; char "ccc<char>" -- c-addr u
; CORE EXT 6.2.2008
        _ slashsource
        _ over
        _ tor                           ; delim addr1 len1      r: addr1
        _ rot
        _ scan                          ; addr2 len2            r: addr1
        _ drop
        _ rfetch                        ; addr2 addr1           r: addr1
        _ minus                         ; len                   r: addr1
        _ dup
        _ oneplus
        _ toin
        _ plusstore                     ; len                   r: addr1
        _ rfrom
        _ swap
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
        _ toin
        _fetch
        _ slashstring                   ; -- source-length addr1 #left
        _ skipwhite                     ; -- source-length start-of-word #left
        _ over                          ; -- source-length start-of-word #left start-of-word
        _ swap                          ; -- source-length start-of-word start-of-word #left
        _ scantowhite                   ; -- source-length start-of-word end-of-word #left
        _ tor                           ; -- source-length start-of-word end-of-word                    r: #left
        _ over                          ; -- source-length start-of-word end-of-word start-of-word
        _ minus                         ; -- source-length start-of-word word-length
        _ rot                           ; -- start-of-word word-length source-length
        _ rfrom                         ; -- start-of-word word-length source-length #left              r: --
        _ dup                           ; -- start-of-word word-length source-length #left #left
        _ zne                           ; -- start-of-word word-length source-length #left -1|0
        _ plus                          ; -- start-of-word word-length source-length #left-1|#left
        _ minus
        _ toin
        _ store
        next
endcode

; ### char
code char, 'char'                       ; "<spaces>name" -- char
; 6.1.0895 CORE
        _ parse_name                    ; -- addr len
        _if char1
        movzx   rbx, byte [rbx]
        _else char1
        xor     rbx, rbx
        _then char1
        next
endcode

; ### [char]
code bracket_char, '[char]', IMMEDIATE
        _ char
        _ literal
        next
endcode

value word_buffer, 'word-buffer', 0     ; initialized in main()

; ### word
code word_, 'word'                      ; char "<chars>ccc<char>" -- c-addr
; CORE
; "WORD always skips leading delimiters."
        _ dup
        _ blchar
        _ equal
        _if word1
        _ drop
        _ parse_name
        _else word1
        ; BUG! PARSE does not skip leading delimiters!
        _ parse                         ; -- addr len
        _then word1
        _ word_buffer
        _ place
        _ word_buffer
        _ dup
        _ count
        _ plus
        _ blchar
        _ swap
        _ cstore
        next
endcode

; ### (
code paren, '(', IMMEDIATE
        _begin paren1
        _ slashsource
        _lit ')'
        _ scan
        _ nip
        _if paren2
        _lit ')'
        _ parse
        _ twodrop
        _return
        _then paren2
        _ refill
        _zeq
        _until paren1
        next
endcode

; ### \
; We need some additonal comment text here so that NASM isn't
; confused by the '\' in the explicit tag.
; "NASM uses backslash (\) as the line continuation character;
; if a line ends with backslash, the next line is considered to
; be a part of the backslash-ended line."
code backslash, '\', IMMEDIATE
        _lit 10
        _ parse
        _ twodrop
        next
endcode

; ### .(
code dotparen, '.(', IMMEDIATE
        _lit ')'
        _ parse
        _ type
        next
endcode
