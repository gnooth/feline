; Copyright (C) 2012-2019 Peter Graves <gnooth@gmail.com>

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

extern malloc
extern realloc
extern free

%ifdef WIN64
extern CreateMutexA
%endif

extern os_accept_string
extern os_allocate_executable
extern os_bye
extern os_chdir
extern os_close_file
extern os_create_file
extern os_current_thread

%ifdef WIN64
extern os_current_thread_raw_thread_handle
%endif

extern os_current_thread_raw_thread_id
extern os_date_time
extern os_delete_file
extern os_emit_file
extern os_file_create_write
extern os_file_is_directory
extern os_file_open_append
extern os_file_open_read
extern os_file_position
extern os_file_size
extern os_file_status
extern os_file_write_time
extern os_flush_file
extern os_free
extern os_free_executable
extern os_getcwd
extern os_getenv
extern os_initialize_primordial_thread
extern os_key
extern os_key_avail
extern os_malloc
extern os_ms
extern os_mutex_init
extern os_mutex_lock
extern os_mutex_trylock
extern os_mutex_unlock
extern os_nano_count
extern os_open_file
extern os_read_char
extern os_read_file
extern os_realloc
extern os_realpath
extern os_rename_file
extern os_reposition_file
extern os_resize_file
extern os_sleep
extern os_strerror
extern os_thread_create
extern os_thread_initialize_datastack
extern os_thread_join
extern os_ticks
extern os_write_file

%ifdef WIN64
extern os_get_console_character_attributes
%endif

extern c_get_saved_backtrace_array
extern c_get_saved_backtrace_size
extern c_random
extern c_save_backtrace
extern c_seed_random

; numbers.c
extern c_decimal_to_number
extern c_fixnum_to_base
extern c_float_expt
extern c_float_float_divide
extern c_float_float_ge
extern c_float_float_gt
extern c_float_float_le
extern c_float_float_lt
extern c_float_float_minus
extern c_float_float_multiply
extern c_float_float_plus
extern c_float_floor
extern c_float_negate
extern c_float_sqrt
extern c_float_to_string
extern c_float_truncate
extern c_pi
extern c_raw_int64_to_float
extern c_raw_uint64_to_float
extern c_string_to_float
extern c_string_to_integer

; math.c
extern c_float_sin

; socket.c
extern c_accept_connection
extern c_make_server_socket
extern c_make_socket
extern c_socket_close
extern c_socket_read_char
extern c_socket_write
extern c_socket_write_char
