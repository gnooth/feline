; Copyright (C) 2012-2018 Peter Graves <gnooth@gmail.com>

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

%macro  _depth 0
        _ current_thread_raw_sp0
        sub     rbx, rbp
        shr     rbx, 3
        sub     rbx, 1
%endmacro

%macro  _rdepth 0
        _ current_thread_raw_rp0
        sub     rbx, rsp
        shr     rbx, 3
%endmacro
