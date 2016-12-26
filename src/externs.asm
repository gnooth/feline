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

extern os_accept_string
extern os_allocate
extern os_allocate_executable
extern os_bye
extern os_chdir
extern os_close_file
extern os_cputime
extern os_create_file
extern os_delete_file
extern os_emit_file
extern os_file_is_directory
extern os_file_position
extern os_file_size
extern os_file_status
extern os_flush_file
extern os_free
extern os_free_executable
extern os_getcwd
extern os_getenv
extern os_key
extern os_key_avail
extern os_ms
extern os_open_file
extern os_read_char
extern os_read_file
extern os_realpath
extern os_rename_file
extern os_reposition_file
extern os_resize
extern os_resize_file
extern os_strerror
extern os_system
extern os_ticks
extern os_write_file

extern c_fixnum_to_base
extern c_get_saved_backtrace_array
extern c_get_saved_backtrace_size
extern c_random
extern c_save_backtrace
extern c_seed_random

; bignum.c
extern c_bignum_add
extern c_bignum_add_bignum
extern c_bignum_allocate
extern c_bignum_equal
extern c_bignum_free
extern c_bignum_from_signed
extern c_bignum_from_unsigned
extern c_bignum_get_str
extern c_bignum_init
extern c_bignum_init_set_si
extern c_bignum_init_set_ui
extern c_bignum_negate
extern c_bignum_sizeinbase
extern c_decimal_to_integer
extern c_expt
