// Copyright (C) 2016-2017 Peter Graves <gnooth@gmail.com>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <stdlib.h>     // malloc
#include <stdio.h>      // snprintf
#include <math.h>       // M_PI
#include <errno.h>      // errno

#include "feline.h"

static Float *make_float(double d)
{
  Float *p = malloc(sizeof(Float));
  p->header = OBJECT_TYPE_FLOAT;
  p->d = d;
  return p;
}

cell c_coerce_fixnum_to_float(int64_t n)
{
  double d = n;
  return (cell) make_float(d);
}

cell c_coerce_bignum_to_float(Bignum *b)
{
  mpf_t f;
  mpf_init(f);
  mpf_set_z(f, b->z);
  double d = mpf_get_d(f);
  mpf_clear(f);
  return (cell) make_float(d);
}

cell c_float_to_string(char *buf, size_t size, Float *p)
{
  snprintf(buf, size, "%.16g", p->d);
  return (cell) buf;
}

cell c_string_to_float(char *s)
{
  errno = 0;
  char *endptr;
  double d = strtod(s, &endptr);
  if (endptr != s && errno == 0)
    return (cell) make_float(d);

  return 0;
}

cell c_pi()
{
  return (cell) make_float(M_PI);
}

cell c_float_add_float(Float *p1, Float *p2)
{
  return (cell) make_float(p1->d + p2->d);
}

cell c_float_subtract_float(Float *p1, Float *p2)
{
  return (cell) make_float(p1->d - p2->d);
}
