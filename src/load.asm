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

feline_global reload_file, 'reload-file'

; ### maybe-set-reload-file
code maybe_set_reload_file, 'maybe-set-reload-file'     ; path --
        _ reload_file
        _tagged_if_not .1
        _to_global reload_file
        _else .1
        _drop
        _then .1
        next
endcode

; ### reload
code reload, 'reload'   ; --
        _ reload_file
        _dup
        _tagged_if .1
        _ load
        _else .1
        _drop
        _write "nothing to reload"
        _then .1
        next
endcode

; ### load
code load, 'load'                       ; path --
        _ canonical_path
        _dup
        _ file_contents
        _ new_lexer
        _tuck
        _ lexer_set_file

        _ begin_scope
        _ lexer
        _ set

        _ interactive?
        _ get
        _tagged_if .1
        _ ?nl
        _write "Loading "
        _ lexer
        _ get
        _ lexer_file
        _dup
        _ write_string
        _ nl
        _ maybe_set_reload_file
        _then .1

        _f
        _ interactive?
        _ set

        _quotation .2
        _ interpret
        _end_quotation .2
        _quotation .3
        _ do_error
        _end_quotation .3
        _ recover
        _ end_scope
        next
endcode

; ### load-system-file
code load_system_file, 'load-system-file' ; filename --
        _ feline_home
        _quote "src"
        _ path_append
        _swap
        _ path_append
        _ load
        next
endcode

; ### l
code interactive_load, 'l', SYMBOL_IMMEDIATE   ; --
        _ interactive?
        _ get
        _tagged_if .1
        _ parse_token   ; -- string/f
        _dup
        _tagged_if .2
        _quote ".feline"
        _ concat
        _ load
        _else .2
        _error "unexpected end of input"
        _then .2
        _else .1
        _error "interactive only"
        _then .1
        next
endcode
