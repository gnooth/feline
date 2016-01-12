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

; 11.6.1.2218 SOURCE-ID
; SOURCE-ID       Input source
; ---------       ------------
; fileid          Text file fileid
; -1              String (via EVALUATE)
; 0               User input device

; ### source-id
value source_id, 'source-id', 0

; ### source-buffer
value source_buffer, 'source-buffer', 0

; ### source-buffer-size
constant source_buffer_size, 'source-buffer-size', 256

; ### 'source
variable tick_source, "'source", 0

; ### #source
variable nsource, '#source', 0

; ### source
code source, 'source'                   ; -- c-addr u
; CORE 6.1.2216
; "c-addr is the address of, and u is the number of characters in, the input buffer."
        _ tick_source
        _fetch
        _ nsource
        _fetch
        next
endcode

; ### set-source
code set_source, 'set-source'           ; c-addr u --
        _ nsource
        _ store
        _ tick_source
        _ store
        next
endcode

; ### set-input
code set_input, 'set-input'             ; source-addr source-len source-id --
        _to source_id
        _ set_source
        next
endcode

; ### save-input
code save_input, 'save-input'
; -- addr len fileid source-buffer source-file-position source-line-number >in 7
; CORE EXT
        _ source                ; -- addr len
        _ source_id             ; -- addr len fileid
        _ source_buffer         ; -- addr len fileid source-buffer
        _ source_file_position
        _fetch                  ; -- addr len fileid source-buffer source-file-position
        _ source_line_number
        _fetch                  ; -- addr len fileid source-buffer source-filename source-line-number
        _ toin
        _fetch                  ; -- addr len fileid source-buffer source-filename source-line-number >in
        _lit 7
        next
endcode

; ### restore-input
code restore_input, 'restore-input'
; addr len fileid source-buffer source-file-position source-line-number >in 7 -- flag
; "flag is true if the input source specification cannot be so restored."
; CORE EXT
        _lit 7
        _ notequal
        _ throw                         ; REVIEW
        _ toin
        _ store
        _ source_line_number
        _ store
        _ source_file_position
        _ store
        _to source_buffer
        _ set_input
        _ source_id
        _ zgt
        _if .1
        _ source_file_position
        _fetch
        _ stod
        _ source_id
        _ reposition_file
        _if .2
        _lit -73                        ; REPOSITION-FILE exception (Forth 2012 Table 9-1)
        _ throw
        _then .2
        _ source_buffer
        _ source_buffer_size
        _ source_id
        _ read_line                     ; -- len flag ior
        _if .3
        _lit -71                        ; READ-LINE exception (Forth 2012 Table 9-1)
        _ throw
        _then .3
        _drop                           ; -- len
        _ nsource
        _ store
        _then .1
        _zero                          ; -- flag
        next
endcode

; ### source-line#
variable source_line_number, 'source-line#', 0

; ### source-file-position
variable source_file_position, 'source-file-position', 0

; ### refill
code refill, 'refill'                   ; -- flag
; CORE EXT  BLOCK EXT  FILE EXT
; "When the input source is a text file, attempt to read the next line
; from the text-input file."
        _ source_id
        ; "When the input source is a string from EVALUATE, return false
        ; and perform no other action."
        _dup
        _lit -1
        _ equal
        _if .1
        _oneplus                        ; -- 0
        _return
        _then .1
        _ file_position                 ; -- ud ior
        _abortq "Bad fileid"
        _ drop                          ; -- u
        _ source_file_position
        _ store
        _ source_buffer
        _ source_buffer_size
        _ source_id
        _ read_line                     ; -- len flag ior
        _if .2
        ; error
        _2drop
        _false
        _return
        _then .2                        ; -- len flag
        _if .3                          ; -- len
        _ nsource
        _ store
        _lit 1
        _ source_line_number
        _ plusstore
        _ toin
        _ off
        _true
        _else .3
        ; end of file
;         _ drop
;         _ false
        xor     rbx, rbx
        _then .3
        next
endcode

; ### echo
value echo, 'echo', 0

; ### +echo
code plusecho, '+echo', IMMEDIATE   ; --
        mov     qword [echo_data], TRUE
        next
endcode

; ### -echo
code minusecho, '-echo', IMMEDIATE  ; --
        mov     qword [echo_data], FALSE
        next
endcode

; ### include-file
code include_file, 'include-file'       ; i*x fileid -- j*x
; FILE
        _ save_input
        _ ntor                          ; -- fileid
        _to source_id
        _ source_buffer_size
        _ iallocate
        _dup
        _to source_buffer
        _to tick_source
        _clear source_line_number
        _begin .1
        _ refill
        _while .1
        _ echo
        _if .2
        _ source
        _ type
        _ cr
        _then .2
        _ interpret
        _repeat .1
        _ source_buffer
        _ ifree
        _ nrfrom
        _ restore_input
        _drop                           ; REVIEW
        next
endcode

; ### includable?
code includable?, 'includable?'         ; $addr -- flag
        _duptor
        _ count
        _ file_exists
        _if .1
        _rfetch
        _ count
        _ file_is_directory
        _zeq_if .2
        _rfrom
        _drop
        _true
        _return
        _then .2
        _then .1
        _rfromdrop
        _false
        next
endcode

; ### resolve-include-filename
code resolve_include_filename, 'resolve-include-filename' ; $addr1 -- $addr
        _ dup                           ; -- $addr1 $addr1
        _ includable?                   ; -- $addr1 flag
        _if .1
        _return
        _then .1                        ; -- $addr1
        _ dup                           ; -- $addr1 $addr1
        _cquote ".forth"
        _ appendstring                  ; -- $addr1 $addr2
        _ dup                           ; -- $addr1 $addr2 $addr2
        _ includable?                   ; -- $addr1 $addr2 flag
        _if .2
        _nip                            ; return addr2
        _else .2
        _ drop                          ; return addr1
        _then .2
        next
endcode

; ### source-filename
value source_filename, 'source-filename', 0

; ### link-file
code link_file, 'link-file'             ; $addr -- nfa
        _ get_current
        _tor
        _ files_wordlist
        _ set_current
        _ warning
        _fetch
        _tor
        _clear warning
        _ count
        _ quotecreate
        _rfrom
        _to warning
        _zero
        _ comma
        _rfrom
        _ set_current
        _ last
        _ fetch
        next
endcode

; ### dirname
code forth_dirname, 'dirname'           ; $filename -- $dirname | 0
        _ count                         ; -- c-addr u
        _begin .1
        _ dup
        _while .1
        _oneminus
        _ twodup
        _ plus
        _cfetch
        _ path_separator_char
        _ equal
        _if .2
        _dup
        _zeq_if .3
        _oneplus
        _then .3
        _ copy_to_temp_string
        _return
        _then .2
        _repeat .1
        _2drop
        _zero
        next
endcode

; ### normalize-filename
code normalize_filename, 'normalize-filename'   ; $addr1 -- $addr2
        _dup
        _ string_first_char
        _lit '~'
        _ notequal
        _if .1
        _return
        _then .1

        _dupcfetch
        _lit 1
        _ equal
        _if .2
        _drop
        _ user_home
        _return
        _then .2

        ; length <> 1
        _dup
        _twoplus
        _cfetch
        _ path_separator_char
        _ equal
        _if .3
        _ user_home
        _swap
        _ count
        _lit 1
        _ slashstring
        _ copy_to_temp_string
        _ appendstring
        _return
        _then .3                        ; -- $addr1

        ; return original string
        next
endcode

; ### included
code included, 'included'               ; i*x c-addr u -- j*x
; FILE
        _ ?dup
        _if .1
        _ source_filename
        _tor
        _ copy_to_temp_string           ; -- $filename
        _ normalize_filename

        _ source_filename
        _ ?dup
        _if .2
        _ forth_dirname
        _ ?dup
        _if .3                          ; -- $filename $dirname
        _ swap
        _ path_append_filename          ; -- $pathname
        _then .3
        _then .2

        _ forth_realpath                ; -- $pathname
        _ resolve_include_filename      ; -- $pathname
        _to source_filename             ; -- $pathname

        _ source_filename
        _ readonly
        _ string_open_file

        _zeq_if .4                      ; -- fileid
        ; file has been opened successfully
        ; make an entry for it in the FILES wordlist
        _from source_filename
        _ link_file
        ; replace the transient string that we've been working with up to now
        ; with the name field of the FILES wordlist entry (which is permanent)
        _to source_filename
        _duptor
        _ include_file
        _rfrom                          ; -- fileid
        _ close_file                    ; -- ior
        _drop                           ; REVIEW

        _lit -1
        _from source_filename
        _namefrom
        _tobody
        _ store

        _else .4
        _ ?cr
        _dotq "Unable to open file "
        _ source_filename
        _ counttype
        _lit -38
        _ throw
        _then .4
        _rfrom
        _to source_filename
        _else .1
        _drop
        _then .1
        next
endcode

; ### include
code include, 'include'
        _ parse_name                    ; -- c-addr u
        _ included
        next
endcode

; ### path-separator-char
%ifdef WIN64
constant path_separator_char, 'path-separator-char', '\'
%else
constant path_separator_char, 'path-separator-char', '/'
%endif

; ### filename-is-absolute
code filename_is_absolute, 'filename-is-absolute'       ; $filename -- flag
%ifdef WIN64
        _dup
        _ string_first_char
        _ path_separator_char
        _ equal
        _if .1                          ; -- $filename
        mov     rbx, -1
        _return
        _then .1

        _dupcfetch                      ; -- $filename length
        _lit 2
        _ ge
        _if .2                          ; -- $filename
        _lit 1
        _ swap                          ; -- 1 $filename
        _ string_nth
        _lit ':'
        _ equal
        _return
        _then .2

        ; otherwise...
        _false
%else
        ; Linux
        _ string_first_char
        _ path_separator_char
        _ equal
%endif
        next
endcode

; ### path-append-filename
code path_append_filename, 'path-append-filename'       ; $path $filename -- $pathname
        _ dup
        _ filename_is_absolute
        _if .1
        _nip
        _return
        _then .1                        ; -- $path $filename

        _ swap                          ; -- $filename $path

        _ dup
        _ string_last_char
        _ path_separator_char
        _ notequal
        _if .2
%ifdef WIN64
        _cquote "\"
%else
        _cquote "/"
%endif
        _ appendstring                  ; -- $name $path1
        _then .2
        _ swap
        _ appendstring
        next
endcode

; ### system-file-pathname
code system_file_pathname, 'system-file-pathname'
; c-addr1 u1 -- c-addr2 u2
        _ copy_to_temp_string           ; -- $addr1
        _ forth_home                    ; -- $addr1 $addr2
%ifdef WIN64
        _cquote "\"
%else
        _cquote "/"
%endif
        _ appendstring                  ; -- $addr1 $addr3
        _ swap
        _ appendstring
        _ count
        next
endcode

; ### include-system-file
code include_system_file, 'include-system-file'
        _ parse_name
        _ system_file_pathname
        _ included
        next
endcode

; ### required
code required, 'required'               ; i*x c-addr u -- i*x
; FILE EXT
        _ ?dup
        _if .1
        _ copy_to_temp_string           ; -- $filename
        _ normalize_filename            ; -- $filename

        _ source_filename
        _ ?dup
        _if .2
        _ forth_dirname
        _ ?dup
        _if .3                          ; -- $filename $dirname
        _ swap
        _ path_append_filename          ; -- $pathname
        _then .3
        _then .2

        _ forth_realpath                ; -- $pathname
        _ resolve_include_filename      ; -- $pathname
        _ count
        _ twodup
        _ files_wordlist
        _ search_wordlist
        _if .4
        _ execute
        _fetch
        _if .5
        _2drop
        _return
        _then .5
        _then .4

        _ included

        _else .1
        _drop
        _then .1
        next
endcode

; ### require
code require, 'require'                 ; i*x "name" -- i*x
; FILE EXT
        _ parse_name
        _ required
        next
endcode

; ### evaluate
code evaluate, 'evaluate'               ; i*x c-addr u -- j*x
; CORE 6.1.1360
; "Save the current input source specification. Store minus-one (-1) in
; SOURCE-ID if it is present. Make the string described by c-addr and u
; both the input source and input buffer, set >IN to zero, and interpret.
; When the parse area is empty, restore the prior input source specification.
; Other stack effects are due to the words EVALUATEd."
        _ save_input
        _ ntor                          ; -- c-addr u
        _lit -1
        _to source_id
        _ set_source                    ; --
        _ toin
        _ off
        _lit interpret_xt
        _ catch
        _ nrfrom
        _ restore_input
        _ drop                          ; REVIEW
        _ throw
        next
endcode
