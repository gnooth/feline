; Copyright (C) 2016-2017 Peter Graves <gnooth@gmail.com>

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

extern os_key

; ### key
code feline_key, 'key'                  ; -- tagged-char
        xcall   os_key
        pushd   rax
        _tag_char
        next
endcode

extern os_key_avail

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
code ekey, 'ekey'                       ; -- fixnum
        _ key
        _dup
        _zeq_if .1
        _drop
        _ key
        _lit $8000
        _or
        _tag_fixnum
        _return
        _then .1
        _dup
        _lit $80
        _ult
        _if .2
        _tag_fixnum
        _return
        _then .2
        _dup
        _lit $0e0
        _equal
        _if .3
        _drop
        _ key
        _lit $8000
        _or
        _tag_fixnum
        _return
        _then .3
        next
endcode

feline_constant k_right,     'k-right',     tagged_fixnum($804d)
feline_constant k_left,      'k-left',      tagged_fixnum($804b)
feline_constant k_up,        'k-up',        tagged_fixnum($8048)
feline_constant k_down,      'k-down',      tagged_fixnum($8050)
feline_constant k_home,      'k-home',      tagged_fixnum($8047)
feline_constant k_end,       'k-end',       tagged_fixnum($804f)
feline_constant k_delete,    'k-delete',    tagged_fixnum($8053)
feline_constant k_prior,     'k-prior',     tagged_fixnum($8049)
feline_constant k_next,      'k-next',      tagged_fixnum($8051)

feline_constant k_ctrl_home, 'k-ctrl-home', tagged_fixnum($8077)
feline_constant k_ctrl_end,  'k-ctrl-end',  tagged_fixnum($8075)

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
        _ key
        _dup
        _lit $1b
        _equal
        _if .1
        _begin .2
        _ key?
        _while .2
        _lit 8
        _lshift
        _ key
        _or
        _repeat .2
        _then .1
        _tag_fixnum
        next
endcode

feline_constant k_right,     'k-right',     tagged_fixnum($1b5b43)
feline_constant k_left,      'k-left',      tagged_fixnum($1b5b44)
feline_constant k_up,        'k-up',        tagged_fixnum($1b5b41)
feline_constant k_down,      'k-down',      tagged_fixnum($1b5b42)
feline_constant k_home,      'k-home',      tagged_fixnum($1b5b48)
feline_constant k_end,       'k-end',       tagged_fixnum($1b5b46)
feline_constant k_delete,    'k-delete',    tagged_fixnum($1b5b337e)
feline_constant k_prior,     'k-prior',     tagged_fixnum($1b5b357e)
feline_constant k_next,      'k-next',      tagged_fixnum($1b5b367e)

feline_constant k_ctrl_home, 'k-ctrl-home', tagged_fixnum($1b5b313b3548)
feline_constant k_ctrl_end,  'k-ctrl-end',  tagged_fixnum($1b5b313b3546)

%endif
