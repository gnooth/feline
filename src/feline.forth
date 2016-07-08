\ Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

\ This program is free software: you can redistribute it and/or modify
\ it under the terms of the GNU General Public License as published by
\ the Free Software Foundation, either version 3 of the License, or
\ (at your option) any later version.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
\ GNU General Public License for more details.

\ You should have received a copy of the GNU General Public License
\ along with this program.  If not, see <http://www.gnu.org/licenses/>.

LANGUAGE: forth

CONTEXT: forth feline ;
CURRENT: feline

import LANGUAGE:
\ import CONTEXT:
\ import CURRENT:

import feline-mode
import forth-mode

import bye

import vocabulary

\ import only
\ import also
\ import definitions
\ import order

import [defined]
import [undefined]
import [if]
import [then]

\ import :
\ import ;

\ import see
: forth:disasm disasm ;

import view

import include
import require
import include-system-file
import empty

import decimal

import constant
\ import local

import locals-enter
import locals-leave

import swap
import dup
import over
import drop
import nip
import >r
import r>

\ REVIEW
import execute
import ?cr
import .(
import time

: throw ( n -- ) untag-fixnum throw ;

: depth ( -- n ) depth tag-fixnum ;

: do ( n1 n2 -- )
    postpone untag-fixnum
    postpone swap
    postpone untag-fixnum
    postpone swap
    postpone do
; immediate

: ?do ( n1 n2 -- )
    postpone untag-fixnum
    postpone swap
    postpone untag-fixnum
    postpone swap
    postpone ?do
; immediate

: i ( -- index )
    postpone i
    postpone tag-fixnum
; immediate

: forth:if ( -- )
    postpone if
; immediate

: file-contents ( path -- string )
    string> r/o open-file throw local fileid
    fileid file-size throw drop local filesize
    filesize -allocate local buffer
    buffer filesize fileid read-file throw local bufsize
    fileid close-file throw
    buffer bufsize >string
    buffer -free
;

: file-lines ( path -- string )
    string> r/o open-file throw local fileid
    1024 local bufsize
    bufsize 2 + -allocate local buffer
    256 <vector> local v
    begin
        buffer bufsize fileid read-line \ -- u2 flag ior
        0= and
    while                               \ -- u2
        buffer swap >string v vector-push
    repeat
    drop
    fileid close-file throw
    buffer -free
    v
;
