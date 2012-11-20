; Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

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

variable tick_source_id, "'source-id", 0

code source_id, 'source-id'             ; -- 0 | -1 | fileid
        _ tick_source_id
        _ fetch
        next
endcode

variable tick_source_buffer, "'source-buffer", 0

code source_buffer, 'source-buffer'     ; -- addr
        _ tick_source_buffer
        _ fetch
        next
endcode

code slash_source_buffer, '/source-buffer'
        _lit 256
        next
endcode

variable tick_source, "'source", 0

variable nsource, '#source', 0

code source, 'source'                   ; -- c-addr u
; CORE 6.1.2216
        _ tick_source
        _ fetch
        _ nsource
        _ fetch
        next
endcode

code set_source, 'set-source'           ; c-addr u --
        _ nsource
        _ store
        _ tick_source
        _ store
        next
endcode

code set_input, 'set-input'             ; source-addr source-len source-id --
        _ tick_source_id
        _ store
        _ set_source
        next
endcode

code save_input, 'save-input'           ; -- addr len fileid source-buffer >in 5
; CORE EXT
        _ source                        ; -- addr len
        _ source_id                     ; -- addr len fileid
        _ source_buffer                 ; -- addr len fileid source-buffer
        _ toin
        _ fetch                         ; -- addr len fileid source-buffer >in
        _lit 5
        next
endcode

code restore_input, 'restore-input'     ; addr len fileid source-buffer >in 5 --
; CORE EXT
        _ drop                          ; REVIEW
        _ toin
        _ store
        _ tick_source_buffer
        _ store
        _ set_input
        next
endcode

code refill, 'refill'                   ; -- flag
; CORE EXT  BLOCK EXT  FILE EXT
        _ source_buffer
        _ slash_source_buffer
        _ source_id
        _ read_line                     ; -- len flag ior
        _if refill1
        ; error
        _ twodrop
        _ false
        _ exit_
        _then refill1                   ; -- len flag
        _if refill2                     ; -- len
        _ nsource
        _ store
        _ toin
        _ off
        _ true
        _else refill2
        _ drop
        _ false
        _then refill2
        next
endcode

code include_file, 'include-file'       ; i*x fileid -- j*x
; FILE
        _ save_input
        _ five
        _ equal
        _if include_file1
        _ tor
        _ tor
        _ tor
        _ tor
        _ tor                           ; -- fileid
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
        _begin include_file2
        _ refill
        _while include_file2
        _ interpret
        _repeat include_file2
        _ source_buffer
        _ free_
        _ drop                          ; REVIEW
        _ rfrom
        _ rfrom
        _ rfrom
        _ rfrom
        _ rfrom
        _ five
        _ restore_input
        _then include_file1
        next
endcode

code included, 'included'               ; i*x c-addr u -- j*x
; FILE
        _ ?dup
        _if included1
        _ dup
        _ oneplus
        _ allocate
        _ zero?
        _if included2                   ; -- c-addr1 u c-addr2
        _ threedup
        _ zplace                        ; -- c-addr1 u c-addr2
        _ rot
        _ drop                          ; -- u c-addr2
        _ swap
        _ readonly
        _ open_file                     ; -- fileid ior
        _ zero?
        _if included3                   ; -- fileid
        _ dup
        _ tor                           ; -- fileid             r: -- fileid
        _ include_file
        _ rfrom                         ; -- fileid
        _ close_file                    ; -- ior
        _ drop                          ; REVIEW
        _then included3
        _then included2
        _else included1
        _ drop                          ; FIXME report error opening file
        _then included1
        next
endcode

code include, 'include'
        _ parse_name                    ; -- c-addr u
        _ included
        next
endcode

code evaluate, 'evaluate'               ; i*x c-addr u -- j*x
; CORE 6.1.1360
; "Save the current input source specification. Store minus-one (-1) in
; SOURCE-ID if it is present. Make the string described by c-addr and u
; both the input source and input buffer, set >IN to zero, and interpret.
; When the parse area is empty, restore the prior input source specification.
; Other stack effects are due to the words EVALUATEd."
        _ save_input
        _ five
        _ equal
        _if evaluate1
        _ tor
        _ tor
        _ tor
        _ tor
        _ tor                           ; -- c-addr u
        _ minusone
        _ tick_source_id
        _ store                         ; -- c-addr u
        _ set_source                    ; --
        _ toin
        _ off
        _ interpret
        _ rfrom
        _ rfrom
        _ rfrom
        _ rfrom
        _ rfrom
        _ five
        _ restore_input
        _then evaluate1
        next
endcode
