; Copyright (C) 2012-2017 Peter Graves <gnooth@gmail.com>

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
extern os_malloc
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
extern c_bignum_bignum_ge
extern c_bignum_bignum_gt
extern c_bignum_bignum_le
extern c_bignum_bignum_lt
extern c_bignum_bignum_minus
extern c_bignum_bignum_multiply
extern c_bignum_bignum_plus
extern c_bignum_equal
extern c_bignum_fixnum_plus
extern c_bignum_free
extern c_bignum_from_signed
extern c_bignum_from_unsigned
extern c_bignum_get_str
extern c_bignum_init_set_si
extern c_bignum_init_set_ui
extern c_bignum_negate
extern c_bignum_sizeinbase
extern c_decimal_to_integer
extern c_string_to_integer

; float.c
extern c_bignum_to_float
extern c_fixnum_to_float
extern c_float_float_divide
extern c_float_float_minus
extern c_float_float_multiply
extern c_float_float_plus
extern c_float_negate
extern c_float_to_string
extern c_pi
extern c_string_to_float

; math.c
extern c_bignum_expt
extern c_fixnum_expt

; socket.c
extern c_accept_connection
extern c_make_server_socket
extern c_make_socket
extern c_socket_close
extern c_socket_read_char
extern c_socket_write
extern c_socket_write_char
