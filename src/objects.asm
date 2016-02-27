; Copyright (C) 2015-2016 Peter Graves <gnooth@gmail.com>

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

; %macro  _this 0
;         pushd   r15
; %endmacro

%macro  _slot0 0
        _fetch
%endmacro

; Slot 0 is the object header.

; ### object-header
; DEPRECATED
inline object_header, 'object-header'   ; object -- x
        _slot0
endinline

; ### object-header!
; DEPRECATED
code set_object_header, 'object-header!' ; x object --
        _ store
        next
endcode

; The first word (16 bits) of the object header is the object type.

; Use the first word here and not just the first byte so that the header is
; less likely to be mistaken for the start of a legacy counted string. The
; first byte of a counted string might take on any value at all, but normally
; the second byte won't be zero unless the first byte is also zero. This gives
; us 255 distinct object types (1-255) before we need to set any bits in the
; second byte.

%macro  _object_type 0
        _wfetch                         ; 16 bits
%endmacro

%macro  _set_object_type 0
        _wstore                         ; 16 bits
%endmacro

; ### object-type
inline object_type, 'object-type'       ; object -- type
        _object_type
endinline

; ### set-object-type
inline set_object_type, 'set-object-type' ; type object --
        _set_object_type
endinline

; The third byte of the object header contains the object flags.

%macro  _object_flags 0
        movzx   rbx, byte [rbx + 2]
%endmacro

; ### object-flags
inline object_flags, 'object-flags'     ; object -- flags
        _object_flags
endinline

%macro  _set_object_flags 0
        mov     al, [rbp]
        mov     [rbx + 2], al
        _2drop
%endmacro

; ### set-object-flags
inline set_object_flags, 'set-object-flags' ; flags object --
        _set_object_flags
endinline

; ### transient?
code transient?, 'transient?'           ; string -- flag
        _object_flags
        and     ebx, TRANSIENT
        _zne
        next
endcode

; ### allocated?
code allocated?, 'allocated?'           ; string -- flag
        _object_flags
        and     ebx, ALLOCATED
        _zne
        next
endcode

%macro  _slot1 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL]
%endmacro

%macro  _set_slot1 0                    ; x object --
        mov     rax, [rbp]
        mov     [rbx + BYTES_PER_CELL], rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _slot2 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 2]
%endmacro

%macro  _set_slot2 0                    ; x object --
        mov     rax, [rbp]
        mov     [rbx + BYTES_PER_CELL * 2], rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro _slot3 0                         ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 3]
%endmacro

%macro _set_slot3 0                     ; x object --
        mov     rax, [rbp]
        mov     [rbx + BYTES_PER_CELL * 3], rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro
