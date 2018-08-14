; Copyright (C) 2018 Peter Graves <gnooth@gmail.com>

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

; ### nl
code nl, 'nl'
        _ standard_output
        _ get
        _ stream_nl
        next
endcode

; ### ?nl
code ?nl, '?nl'
        _ standard_output
        _ get
        _ stream_?nl
        next
endcode

; ### tab
code tab, 'tab'                         ; n --
        _ standard_output
        _ get
        _ stream_output_column
        _ generic_minus
        _lit tagged_fixnum(1)
        _ generic_max
        _ spaces
        next
endcode

; ### write-char
code write_char, 'write-char'           ; tagged-char -> void
        _ standard_output
        _ get
        _ stream_write_char
        next
endcode

; ### write-char-escaped
code write_char_escaped, 'write-char-escaped'   ; tagged-char -> void
        _ standard_output
        _ get
        _ stream_write_char_escaped
        next
endcode

; ### write-string
code write_string, 'write-string'       ; string -> void
        _ standard_output
        _ get
        _ stream_write_string
        next
endcode

; ### write-string-escaped
code write_string_escaped, 'write-string-escaped'       ; string -> void
        _ standard_output
        _ get
        _ stream_write_string_escaped
        next
endcode

; ### print
code print, 'print'                     ; string -> void
        _ generic_write
        _ nl
        next
endcode

; ### output-stream?
code output_stream?, 'output-stream?'   ; object -> ?
        _ file_output_stream?
        next
endcode
