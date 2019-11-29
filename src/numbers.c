// Copyright (C) 2016-2019 Peter Graves <gnooth@gmail.com>

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
#include <string.h>     // strlen
#include <errno.h>      // errno
#include <inttypes.h>   // PRId64

#include "feline.h"

Float *make_float(double d)
{
  Float *p = malloc(sizeof(Float));
  p->header = TYPECODE_FLOAT;
  p->d = d;
  return p;
}

static Int64 *make_int64(int64_t n)
{
  Int64 *p = malloc(sizeof(Int64));
  p->header = TYPECODE_INT64;
  p->n = n;
  return p;
}

cell c_raw_int64_to_float(int64_t n)
{
  double d = n;
  return (cell) make_float(d);
}

cell c_raw_uint64_to_float(uint64_t n)
{
  double d = n;
  return (cell) make_float(d);
}

cell c_float_to_string(char *buf, size_t size, Float *p)
{
  snprintf(buf, size, "%.17g", p->d);
  return (cell) buf;
}

cell c_string_to_float(char *s, size_t length)
{
  // Return the raw pointer returned by make_float if conversion is
  // successful. Otherwise, return F_VALUE.

  if (length == 0)
    return F_VALUE;

  errno = 0;
  char *endptr;
  double d = strtod(s, &endptr);
  if (errno != 0 || endptr != s + length)
    return F_VALUE;     // error

  return (cell) make_float(d);
}

cell c_string_to_integer(char *s, size_t length, int base)
{
  // Return a tagged fixnum or the raw pointer returned by make_int64
  // if conversion is successful. Otherwise, return F_VALUE.

  if (length == 0)
    return F_VALUE;

  errno = 0;
  char *endptr;

#ifdef WIN64
  long long int n = strtoll(s, &endptr, base);
#else
  long n = strtol(s, &endptr, base);
#endif

  if (errno != 0 || endptr != s + length)
    return F_VALUE;   // error

  if (n >= MOST_NEGATIVE_FIXNUM && n <= MOST_POSITIVE_FIXNUM)
    return make_fixnum(n);

  return (cell) make_int64(n);
}

cell c_decimal_to_number(char *s, size_t length)
{
  // Return a tagged fixnum or the raw pointer returned by make_float or
  // make_int64 if conversion is successful. Otherwise, return F_VALUE.

  if (length == 0)
    return F_VALUE;

  int maybe_integer = 1;

  for (int i = length; i-- > 0;)
    {
      unsigned char c = s[i];
      if (c < '0' || c > '9')
        {
          if (i > 0 || length == 1 || (c != '-' && c != '+'))
            {
              maybe_integer = 0;
              break;
            }
        }
    }

  if (maybe_integer)
    {
      errno = 0;
      char *endptr;
#ifdef WIN64
      long long int n = strtoll(s, &endptr, 10);
#else
      long n = strtol(s, &endptr, 10);
#endif
      if (errno == ERANGE)
        return c_string_to_float(s, length);
      if (errno != 0 || endptr != s + length)
        return F_VALUE;   // error
      if (n >= MOST_NEGATIVE_FIXNUM && n <= MOST_POSITIVE_FIXNUM)
        return make_fixnum(n);

      return (cell) make_int64(n);
    }

  return c_string_to_float(s, length);
}

int c_fixnum_to_base(cell n, cell base, char * buf, size_t size)
{
  // arguments are all untagged
  if (base == 16)
    // PRIX64 is defined in inttypes.h
    return snprintf(buf, size, "%" PRIx64, n);
  else
    // FIXME it's an error if base is not 10 here
    // PRId64 is defined in inttypes.h
    return snprintf(buf, size, "%" PRId64, n);
}

cell c_pi (void)
{
  return (cell) make_float (3.1415926535897932846);
}

cell c_float_float_lt(Float *p1, Float *p2)
{
  return p1->d < p2->d ? T_VALUE : F_VALUE;
}

cell c_float_float_le(Float *p1, Float *p2)
{
  return p1->d <= p2->d ? T_VALUE : F_VALUE;
}

cell c_float_float_gt(Float *p1, Float *p2)
{
  return p1->d > p2->d ? T_VALUE : F_VALUE;
}

cell c_float_float_ge(Float *p1, Float *p2)
{
  return p1->d >= p2->d ? T_VALUE : F_VALUE;
}

cell c_float_float_plus(Float *p1, Float *p2)
{
  return (cell) make_float(p1->d + p2->d);
}

cell c_float_float_minus(Float *p1, Float *p2)
{
  return (cell) make_float(p1->d - p2->d);
}

cell c_float_float_multiply(Float *p1, Float *p2)
{
  return (cell) make_float(p1->d * p2->d);
}

cell c_float_float_divide(Float *p1, Float *p2)
{
  return (cell) make_float(p1->d / p2->d);
}

cell c_float_floor(Float *p)
{
  // Return a tagged fixnum or the raw pointer returned by make_int64 if
  // no overflow. Otherwise, return p.

  double d = floor(p->d);
  int64_t n = (int64_t) d;
  if (n >= MOST_NEGATIVE_FIXNUM && n <= MOST_POSITIVE_FIXNUM)
    return make_fixnum(n);
  if (n > INT64_MIN && n < INT64_MAX)
    return (cell) make_int64(n);
  return (cell) p;
}

cell c_float_truncate(Float *p)
{
  // Return a tagged fixnum or the raw pointer returned by make_int64 if
  // no overflow. Otherwise, return p.

  double d = trunc(p->d);
  int64_t n = (int64_t) d;
  if (n >= MOST_NEGATIVE_FIXNUM && n <= MOST_POSITIVE_FIXNUM)
    return make_fixnum(n);
  if (n > INT64_MIN && n < INT64_MAX)
    return (cell) make_int64(n);
  return (cell) p;
}

cell c_float_negate(Float *p)
{
  return (cell) make_float(-p->d);
}

cell c_float_sqrt(Float *p)
{
  return (cell) make_float(sqrt(p->d));
}

cell c_float_expt(Float *base, Float *power)
{
  return (cell) make_float(pow(base->d, power->d));
}
