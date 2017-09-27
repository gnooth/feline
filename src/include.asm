; Copyright (C) 2012-2017 Peter Graves <gnooth@gmail.com>

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

; ### path-separator-char
%ifdef WIN64
constant path_separator_char, 'path-separator-char', '\'
%else
constant path_separator_char, 'path-separator-char', '/'
%endif

; ### path-separator-char?
code path_separator_char?, 'path-separator-char?' ; char -- flag
; Accept '/' even on Windows.
%ifdef WIN64
        _dup
        _lit '\'
        _equal
        _if .1
        _drop
        _true
        _return
        _then .1
        ; Fall through...
%endif
        _lit '/'
        _equal
        next
endcode

; ### path-get-directory
code path_get_directory, 'path-get-directory' ; string1 -- string2 | 0
        _ string_from                   ; -- c-addr u
        _begin .1
        _dup
        _while .1
        _oneminus
        _twodup
        _plus
        _cfetch
        _ path_separator_char?
        _if .2
        _dup
        _zeq_if .3
        _oneplus
        _then .3
        _ copy_to_string
        _return
        _then .2
        _repeat .1
        _2drop
        _zero
        next
endcode
