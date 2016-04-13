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

feline!

import bye

import vocabulary

import only
import also
import definitions

import [defined]
import [undefined]
import [if]
import [then]

import (
import \

\ import =
: = ( n1 n2 -- flag ) = tag-fixnum ;

\ import 0=
: 0= ( n -- flag ) 0 = tag-fixnum ;

import u<
import <

import :
import ;

import include-system-file
import empty
import forth!

import decimal

import constant
import local

: depth ( -- n ) depth tag-fixnum ;
