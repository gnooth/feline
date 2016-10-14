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

import feline-mode
import forth-mode

import locals-enter
import locals-leave

: throw ( n -- )
    dup fixnum? t = if
        untag-fixnum
    then
    throw
;

: depth ( -- n ) depth tag-fixnum ;

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
