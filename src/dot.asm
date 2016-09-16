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

; ### holdbufptr
variable holdbufptr, 'holdbufptr', 0    ; gforth

; ### holdbuf
code holdbuf, 'holdbuf'                 ; gforth
        _ holdbufptr
        _ fetch
        next
endcode

; ### holdbuf-end
code holdbuf_end, 'holdbuf-end'         ; gforth
        _ holdbuf
        _ holdbufsize
        _ plus
        next
endcode

; ### holdptr
variable holdptr, 'holdptr', 0          ; gforth

; ### <#
code ltsharp,"<#"
; CORE
; "Initialize the pictured numeric output conversion process."
        _ holdbuf_end
        _ holdptr
        _ store
        next
endcode

; ### hold
code hold, 'hold'                       ; char --
; CORE
        _lit -1
        _ holdptr
        _ plusstore
        _ holdptr
        _fetch                          ; -- char addr
        ; Make sure address is not below start of buffer.
        _dup
        _ holdbuf
        _ult
        _lit 17
        _ ?throw                        ; -- char addr
        _ cstore
        next
endcode

; ### sign
code sign, 'sign'                       ; n --
; CORE
; "If n is negative, add a minus sign to the beginning of the pictured
; numeric output string."
        _zlt
        _if .1
        _lit '-'
        _ hold
        _then .1
        next
endcode

; ### #>
code sharpgt,'#>'                       ; d --- c-addr u
; CORE
        _2drop                          ; 2drop holdptr @ holdbuf-end over -
        _ holdptr
        _fetch
        _ holdbuf_end
        _over
        _minus
        next
endcode

; ### #
code sharp, '#'                         ; ud1 -- ud2
; CORE
        _ basefetch                     ; -- ud1 base
        _ muslmod                       ; -- remainder ud2
        _ rot                           ; -- ud2 remainder
        _lit 9                          ; -- ud2 remainder 9
        _ over                          ; -- ud2 remainder 9 remainder
        _ lt                            ; -- ud2 remainder flag
        _if .1                          ; remainder > 9
        add     rbx, 7
        _then .1
        add     rbx, '0'
        _ hold
        next
endcode

; ### #s
code sharps, '#s'
; CORE
        _begin sharps1
        _ sharp
        _ twodup
        _ dzeroequal
        _until sharps1
        next
endcode

; ### holds
code holds, 'holds'
; CORE EXT
        _begin .1
        _dup
        _while .1
        _oneminus
        _ twodup
        _plus
        _cfetch
        _ hold
        _repeat .1
        _2drop
        next
endcode

; ### (.)
code paren_dot, '(.)'                   ; n -- c-addr u
        _ dup
        _ abs_
        _zero
        _ ltsharp
        _ sharps
        _ rot
        _ sign
        _ sharpgt
        next
endcode

; ### .
code dot, '.'
        _ paren_dot
        _ type
        _ forth_space
        next
endcode

; ### .r
code dotr, '.r'                         ; n width --
; CORE EXT
        _ tor
        _ paren_dot
        _ rfrom
        _ over
        _ minus
        _ spaces
        _ type
        next
endcode

; ### (u.)
code paren_udot, '(u.)'
        _zero
        _ ltsharp
        _ sharps
        _ sharpgt
        next
endcode

; ### u.
code udot, 'u.'
        _ paren_udot
        _ type
        _ forth_space
        next
endcode

; ### u.r
code udotr, 'u.r'                       ; u width --
; CORE EXT
        _ tor
        _ paren_udot
        _ rfrom
        _ over
        _ minus
        _ spaces
        _ type
        next
endcode

; ### (h.)
code paren_hdot, '(h.)'
        _ basefetch
        _tor
        _ hex
        _zero
        _ ltsharp
        _ sharps
        _lit '$'
        _ hold
        _ sharpgt
        _rfrom
        _ basestore
        next
endcode

; ### h.
code hdot, 'h.'                         ; x --
        _ paren_hdot
        _ type
        _ forth_space
        next
endcode

; ### h.r
code hdotr, 'h.r'                       ; x width --
        _ tor
        _ paren_hdot
        _ rfrom
        _ over
        _ minus
        _ spaces
        _ type
        next
endcode

; ### dec.
code decdot, 'dec.'                     ; n --
        _ basefetch
        _ swap
        _ decimal
        _ dot
        _ basestore
        next
endcode

; ### dec.r
code decdotr, 'dec.r'                   ; n --
        _ basefetch
        _tor
        _ decimal
        _ dotr
        _rfrom
        _ basestore
        next
endcode

; ### (ud.)
code paren_uddot, '(ud.)'               ; ud -- c-addr u
        _ ltsharp
        _ sharps
        _ sharpgt
        next
endcode

; ### ud.
code uddot, 'ud.'                       ; ud --
        _ paren_uddot
        _ type
        _ forth_space
        next
endcode

; ### d.r
code ddotr, 'd.r'                       ;  d n --
; DOUBLE
        _ tor
        _ tuck
        _ dabs
        _ ltsharp
        _ sharps
        _ rot
        _ sign
        _ sharpgt
        _ rfrom
        _ over
        _ minus
        _ spaces
        _ type
        next
endcode

; ### d.
code ddot, 'd.'                         ; d --
; DOUBLE
        _zero
        _ ddotr
        _ forth_space
        next
endcode

; ### .hexbyte
code dothexbyte, '.hexbyte'             ; ub --
        push    qword [base_data]
        mov     qword [base_data], 16
        _zero
        _ ltsharp
        _ sharp
        _ sharp
        _ sharpgt
        _ type
        pop     qword [base_data]
        next
endcode
