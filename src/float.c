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

#include "feline.h"

struct double_float
{
  cell header;
  double d;
};

cell c_float_to_string(char *buf, size_t size, struct double_float *p)
{
  // FIXME "3.14" string>float float>string -> "3.1400000000000001"
  snprintf(buf, size, "%.17g", p->d);
  return (cell) buf;
}

cell c_string_to_float(char *s)
{
  double d = strtod(s, NULL);
  struct double_float *p = malloc(sizeof(struct double_float));
  p->header = OBJECT_TYPE_FLOAT;
  p->d = d;
  return (cell) p;
}

cell c_pi()
{
  struct double_float *p = malloc(sizeof(struct double_float));
  p->header = OBJECT_TYPE_FLOAT;
  p->d = M_PI;
  return (cell) p;
}
