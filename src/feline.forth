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

import feline-mode
import forth-mode

import bye

import view

import include
import require
import include-system-file

import locals-enter
import locals-leave

import swap
import dup
import 2dup
import over
import drop
import 2drop
import nip
import rot

import >r
import r>

import time

: throw ( n -- )
    dup fixnum? t = if
        untag-fixnum
    then
    throw
;

: depth ( -- n ) depth tag-fixnum ;

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

: set-file-lines ( strings path -- )
    string> w/o create-file throw local fileid
    local strings
    strings length untag-fixnum 0 ?do
        i tag-fixnum strings nth
        string> fileid write-line throw
    loop
    fileid close-file throw
;

: regular-file? ( path -- ? )
    dup path-is-directory?
    if
        drop f
    else
        \ not a directory
        path-file-exists?
        tag-boolean
    then
;

: directory? ( path -- ? )
    path-is-directory? tag-boolean
;
