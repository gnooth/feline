; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

        _ ?nl
        _write "Loading "
        _ lexer
        _ get
        _ lexer_file
        _ write_string
        _ nl

        _quotation .1
        _ feline_interpret
        _end_quotation .1
        _quotation .2
        _ do_error
        _end_quotation .2
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
