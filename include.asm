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
code save_input, 'save-input'           ; -- addr len fileid source-buffer >in 7
; CORE EXT
        _ source                        ; -- addr len
        _ source_id                     ; -- addr len fileid
        _ source_buffer                 ; -- addr len fileid source-buffer
        _ source_file_position
        _fetch
        _ source_line_number
        _fetch
        _ toin
        _fetch                          ; -- addr len fileid source-buffer >in
        _lit 7
        next
endcode

; ### restore-input
code restore_input, 'restore-input'     ; addr len fileid source-buffer >in 7 -- flag
; CORE EXT
        _ drop                          ; REVIEW
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
        _if restore_input1
        _ source_file_position
        _fetch
        _ stod
        _ source_id
        _ reposition_file
        _abortq "REPOSITION-FILE error"
        _ source_buffer
        _ slash_source_buffer
        _ source_id
        _ read_line                     ; -- len flag ior
        _abortq "READ-LINE error"
        _ drop                          ; -- len
        _ nsource
        _ store
        _then restore_input1
        _ zero                          ; -- flag
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
        _ file_position                 ; -- ud ior
        _abortq "Bad fileid"
        _ drop                          ; -- u
        _ source_file_position
        _ store
        _ source_buffer
        _ slash_source_buffer
        _ source_id
        _ read_line                     ; -- len flag ior
        _if refill1
        ; error
        _ twodrop
        _ false
        _return
        _then refill1                   ; -- len flag
        _if refill2                     ; -- len
        _ nsource
        _ store
        _ one
        _ source_line_number
        _ plusstore
        _ toin
        _ off
        _ true
        _else refill2
        ; end of file
        _ drop
        _ false
        _then refill2
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
        _begin include_file2
        _ refill
        _while include_file2
        _ verboseinclude
        _if include_file3
        _ source
        _ type
        _ cr
        _then include_file3
        _ interpret
        _repeat include_file2
        _ source_buffer
        _ free_
        _ drop                          ; REVIEW
        _ nrfrom
        _ restore_input
        _ drop                          ; REVIEW
        next
endcode

; ### included
code included, 'included'               ; i*x c-addr u -- j*x
; FILE
        _ ?dup
        _if included1
        _ dup
        _ oneplus
        _ allocate
        _zeq
        _if included2                   ; -- c-addr1 u c-addr2
        _ threedup
        _ zplace                        ; -- c-addr1 u c-addr2
        _ rot
        _ drop                          ; -- u c-addr2
        _ swap                          ; -- c-addr2 u
        _ twodup                        ; -- c-addr2 u c-addr2 u
        _ readonly                      ; -- c-addr2 u c-addr2 u r/o
        _ open_file                     ; -- c-addr2 u fileid ior
        _zeq
        _if included3                   ; -- c-addr2 u fileid
        _ tor                           ; -- c-addr2 u          r: -- fileid
        _ twodrop                       ; --                    r: -- fileid
        _ rfetch
        _ include_file
        _ rfrom                         ; -- fileid
        _ close_file                    ; -- ior
        _ drop                          ; REVIEW
        _else included3                 ; -- c-addr2 u fileid
        _ drop
        _ ?cr
        _dotq "Unable to open "
        _ type
        _lit -38
        _ throw
        _then included3
        _then included2
        _else included1
        _ drop
        _then included1
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
        _ forth_home_
        _ zcount
        _ stringbuf
        _oneplus
        _ zplace
%ifdef WIN64
        _squote "\\"
%else
        _squote "/"
%endif
        _ stringbuf
        _oneplus
        _ zappend
        _ stringbuf
        _oneplus
        _ zappend
        _ stringbuf
        _oneplus
        _ zstrlen
        _ stringbuf
        _ cstore
        _ stringbuf
        _ count
        _ plus_stringbuf
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
        _ minusone
        _ tick_source_id
        _ store                         ; -- c-addr u
        _ set_source                    ; --
        _ toin
        _ off
        _ interpret
        _ nrfrom
        _ restore_input
        _ drop                          ; REVIEW
        next
endcode
