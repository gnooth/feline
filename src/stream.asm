; Copyright (C) 2018-2020 Peter Graves <gnooth@gmail.com>

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

; ### space
code space, 'space'
        _tagged_char(32)
        _ standard_output
        _ get
        _ stream_write_char
        next
endcode

; ### spaces
code spaces, 'spaces'                   ; n -> void

        _check_fixnum                   ; -> raw-count

        test    rbx, rbx
        jng     .exit

        _ standard_output
        _ get                           ; -> raw-count stream

        push    this_register
        mov     this_register, rbx
        poprbx

        push    r12
        mov     r12, rbx
        poprbx

        align   DEFAULT_CODE_ALIGNMENT
.loop:
        _tagged_char(32)
        pushrbx
        mov     rbx, this_register
        _ stream_write_char
        sub     r12, 1
        jnz     .loop

        pop     r12
        pop     this_register
        next

.exit:
        _drop
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

asm_global stdout_

; ### stdout
code feline_stdout, 'stdout'            ; -> stream
        _dup
        mov     rbx, [stdout_]
        next
endcode

special standard_output, 'standard-output'

asm_global stderr_

; ### stderr
code feline_stderr, 'stderr'            ; -> stream
        _dup
        mov     rbx, [stderr_]
        next
endcode

special error_output, 'error-output'

; ### initialize-streams
code initialize_streams, 'initialize-streams'
        _dup
%ifdef WIN64
        mov     rbx, [standard_output_handle]
%else
        mov     rbx, 1
%endif
        _ make_file_output_stream
        mov     [stdout_], rbx
        _drop

        _lit stdout_
        _ gc_add_root

        _ feline_stdout
        _ standard_output
        _ set

        _dup
%ifdef WIN64
        mov     rbx, [error_output_handle]
%else
        mov     rbx, 2
%endif
        _ make_file_output_stream
        mov     [stderr_], rbx
        _drop

        _lit stderr_
        _ gc_add_root

        _ feline_stderr
        _ error_output
        _ set

        next
endcode
