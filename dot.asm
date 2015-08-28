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
        _ minusone
        _ holdptr
        _ plusstore
        _ holdptr
        _fetch
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
        _ twodrop                       ; 2drop holdptr @ holdbuf_end over -
        _ holdptr
        _fetch
        _ holdbuf_end
        _ over
        _ minus
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
        _lit 7
        _ plus
        _then .1
        _lit '0'
        _ plus
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
        _twodrop
        next
endcode

; ### (.)
code paren_dot, '(.)'                   ; n -- c-addr u
        _ dup
        _ abs_
        _ zero
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
        _ space
        next
endcode

; ### .r
code dotr, '.r'                         ; n u --
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
        _ zero
        _ ltsharp
        _ sharps
        _ sharpgt
        next
endcode

; ### u.
code udot, 'u.'
        _ paren_udot
        _ type
        _ space
        next
endcode

; ### u.r
code udotr, 'u.r'
        _ tor
        _ paren_udot
        _ rfrom
        _ over
        _ minus
        _ spaces
        _ type
        next
endcode

; ### h.
code hdot, 'h.'                         ; x --
        _ basefetch
        _ swap
        _ hex
        _ udot
        _ basestore
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
        _ space
        next
endcode

; ### .2
code dottwo, '.2'                       ; ub --
        _ zero
        _ ltsharp
        _ sharp
        _ sharp
        _ sharpgt
        _ type
        next
endcode
