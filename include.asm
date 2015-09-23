; Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

; ### 'source-id
variable tick_source_id, "'source-id", 0

; ### source-id
code source_id, 'source-id'             ; -- 0 | -1 | fileid
        _ tick_source_id
        _fetch
        next
endcode

; ### 'source-buffer
variable tick_source_buffer, "'source-buffer", 0

; ### source-buffer
code source_buffer, 'source-buffer'     ; -- addr
        _ tick_source_buffer
        _fetch
        next
endcode

; ### /source-buffer
code slash_source_buffer, '/source-buffer'
        _lit 256
        next
endcode

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
        _ tick_source_id
        _ store
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
        _ tick_source_buffer
        _ store
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
        _ slash_source_buffer
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
        _ slash_source_buffer
        _ source_id
        _ read_line                     ; -- len flag ior
        _if .2
        ; error
        _2drop
        _ false
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
        _ true
        _else .3
        ; end of file
;         _ drop
;         _ false
        xor     rbx, rbx
        _then .3
        next
endcode

; ### verboseinclude
value verboseinclude, 'verboseinclude', 0

; ### +verboseinclude
code plusverboseinclude, '+verboseinclude', IMMEDIATE   ; --
        mov     qword [verboseinclude_data], TRUE
        next
endcode

; ### -verboseinclude
code minusverboseinclude, '-verboseinclude', IMMEDIATE  ; --
        mov     qword [verboseinclude_data], FALSE
        next
endcode

; ### include-file
code include_file, 'include-file'       ; i*x fileid -- j*x
; FILE
        _ save_input
        _ ntor                          ; -- fileid
        _ tick_source_id
        _ store                         ; --
        _ slash_source_buffer
        _ allocate                      ; -- a-addr ior
        _ drop                          ; REVIEW
        _ dup
        _ tick_source_buffer
        _ store
        _ tick_source
        _ store
        _ source_line_number
        _ off
        _begin .1
        _ refill
        _while .1
        _ verboseinclude
        _if .2
        _ source
        _ type
        _ cr
        _then .2
        _ interpret
        _repeat .1
        _ source_buffer
        _ free_
        _ drop                          ; REVIEW
        _ nrfrom
        _ restore_input
        _ drop                          ; REVIEW
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
        _ true
        _return
        _then .2
        _then .1
        _rfromdrop
        _ false
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
variable source_filename, 'source-filename', 0

; ### link-file
code link_file, 'link-file'             ; c-addr u -- nfa
        _ here
        _ tor
        _ get_current
        _ tor
        _ files_wordlist
        _ set_current
        _ quotecreate
        _zero
        _ comma
        _ rfrom
        _ set_current
        _ rfrom
        _ toname
        next
endcode

; ### included
code included, 'included'               ; i*x c-addr u -- j*x
; FILE
        _ ?dup
        _if .1
        _ source_filename
        _fetch
        _ tor
        _ to_stringbuf
        _ resolve_include_filename      ; -- $addr
        _ realpath_
        _ dup
        _ count
        _ link_file
        _ source_filename
        _ store
        _ string_to_zstring
        _ readonly
        _ paren_open_file               ; -- fileid ior
        _zeq_if .2
        _duptor
        _ include_file
        _ rfrom                         ; -- fileid
        _ close_file                    ; -- ior
        _ drop                          ; REVIEW
        _else .2
        _ ?cr
        _dotq "Unable to open file "
        _ source_filename
        _ fetch
        _ counttype
        _lit -38
        _ throw
        _then .2
        _ rfrom
        _ source_filename
        _ store
        _else .1
        _ drop
        _then .1
        next
endcode

; ### include
code include, 'include'
        _ parse_name                    ; -- c-addr u
        _ included
        next
endcode

; ### system-file-pathname
code system_file_pathname, 'system-file-pathname'
; c-addr1 u1 -- c-addr2 u2
        _ to_stringbuf                  ; -- $addr1
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
        _ tick_source_id
        _ store                         ; -- c-addr u
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
