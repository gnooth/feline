; Copyright (C) 2016-2019 Peter Graves <gnooth@gmail.com>

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

; ### wait_for_key
code wait_for_key, 'wait_for_key', SYMBOL_INTERNAL      ; --
        xcall   os_key_avail
        test    rax, rax
        jnz     .exit
        _ safepoint
        _lit tagged_fixnum(25)
        _ sleep
        jmp     wait_for_key
.exit:
        next
endcode

; ### raw_key
code raw_key, 'raw_key', SYMBOL_INTERNAL        ; -- untagged-char
        xcall   os_key
        pushd   rax
        next
endcode

; ### raw_key?
code raw_key?, 'raw_key?', SYMBOL_INTERNAL      ; -- untagged
        xcall   os_key_avail            ; returns non-zero if a key has been pressed
        pushd   rax
        next
endcode

; ### key
code feline_key, 'key'                  ; -- tagged-char
        _ wait_for_key
        xcall   os_key
        pushd   rax
        _tag_char
        next
endcode

; ### key?
code feline_key?, 'key?'                ; -- ?
        xcall   os_key_avail
        pushrbx
        mov     ebx, f_value
        mov     edx, t_value
        test    rax, rax
        cmovnz  ebx, edx
        next
endcode

%ifdef WIN64

; Windows console

; : ekey ( -- x )
;     key
;     dup 0= if
;         drop
;         key $8000 or tag-fixnum
;         exit
;     then
;     dup $80 u< if                       \ normal character
;         tag-fixnum
;         exit
;     then
;     dup $e0 = if
;         drop
;         key $8000 or tag-fixnum
;         exit
;     then
; ;

; ### ekey
code ekey, 'ekey'                       ; -- tagged-fixnum/tagged-char

        _ wait_for_key

        _ raw_key

        _dup
        _zeq_if .1
        _drop
        _ raw_key
        _lit 0x8000
        _or
        _tag_fixnum
        _return
        _then .1

        _dup
        _lit 0x80
        _ult
        _if .2
        _tag_char
        _return
        _then .2

        _dup
        _lit 0xe0
        _equal
        _if .3
        _drop
        _ raw_key
        _lit 0x8000
        _or
        _tag_fixnum
        _return
        _then .3

        next
endcode

%else

; Linux

; : ekey ( -- x )
;     key
;     dup $1b = if
;         begin
;             key?
;         while
;             8 lshift
;             key or
;         repeat
;     then
;     tag-fixnum
; ;

; ### ekey
code ekey, 'ekey'                       ; -- fixnum

        _ wait_for_key

        _ raw_key

        _dup
        _lit 0x1b
        _equal
        _if .1
        _begin .2
        _ raw_key?
        _while .2
        _lit 8
        _lshift
        _ raw_key
        _or
        _repeat .2
        _then .1

        _dup
        _lit 0x80
        _ult
        _if .3
        _tag_char
        _else .3
        _tag_fixnum
        _then .3

        next
endcode

%endif
