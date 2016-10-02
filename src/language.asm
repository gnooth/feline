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

; ### language
value language, 'language', 0

; ### forth-prompt-string
code forth_prompt_string, 'forth-prompt-string'
        _quote "Forth> "
        next
endcode

; ### feline-prompt-string
code feline_prompt_string, 'feline-prompt-string'
        _quote "Feline> "
        next
endcode

deferred prompt_string, 'prompt-string', forth_prompt_string

; ### prompt
code prompt, 'prompt'                   ; --
        _ green
        _ foreground
        _ prompt_string
        _ dot_string
        next
endcode

; ### .language
code dot_language, '.language'
        _ language
        _?dup_if .1
        _ dot_string
        _ forth_space
        _then .1
        next
endcode

; ### forth-mode
code forth_mode, 'forth-mode'
        _lit forth_interpret_xt
        _lit interpret_xt
        _tobody
        _store

        _lit forth_prompt_string_xt
        _lit prompt_string_xt
        _tobody
        _store

        _lit forth_ok_xt
        _lit ok_xt
        _tobody
        _store

        _ only
        _ feline
        _ also
        _ forth
        _ definitions

        _quote "Forth"
        _to language

        next
endcode

; ### feline-ok
code feline_ok, 'feline-ok'             ; --
        _ feline_dot_s
        next
endcode

; ### feline-mode
code feline_mode, 'feline-mode'
        _lit feline_interpret_xt
        _lit interpret_xt
        _tobody
        _store

        _lit feline_prompt_string_xt
        _lit prompt_string_xt
        _tobody
        _store

        _lit feline_ok_xt
        _lit ok_xt
        _tobody
        _store

        _ only
        _ feline
        _ definitions

        _quote "Feline"
        _to language

        next
endcode

; ### LANGUAGE:
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
