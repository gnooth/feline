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

; ### forth-mode
code forth_mode, 'forth-mode'
        _lit forth_interpret_xt
        _lit interpret_xt
        _tobody
        _store
        _lit forth_prompt_xt
        _lit prompt_xt
        _tobody
        _store
        next
endcode

; ### feline-mode
code feline_mode, 'feline-mode'
        _lit feline_interpret_xt
        _lit interpret_xt
        _tobody
        _store
        _lit feline_prompt_xt
        _lit prompt_xt
        _tobody
        _store
        next
endcode

; ### language:
code language_colon, 'LANGUAGE:', IMMEDIATE
        _ parse_name                    ; -- c-addr u

        _twodup
        _squote "forth"
        _ strequal
        _if .1
        _2drop
        _ forth_mode
        _return
        _then .1

        _twodup
        _squote "feline"
        _ strequal
        _if .2
        _2drop
        _ feline_mode
        _return
        _then .2

        _2drop
        _true
        _abortq "unsupported language"
        next
endcode
