// Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

#include <stdio.h>
#include <stdlib.h>

#include "../gmp/gmp.h"

#include "feline.h"

void *bignum_allocate()
{
  // + 8 for object header
  return malloc(sizeof(mpz_t) + 8);
}

void bignum_init(mpz_t z)
{
  mpz_init(z);
}

void bignum_init_set_ui(mpz_t z, unsigned long int n)
{
  mpz_init_set_ui(z, n);
}

size_t bignum_sizeinbase(const mpz_t z, int base)
{
  return mpz_sizeinbase(z, base);
}

char * bignum_get_str(char *buf, int base, const mpz_t z)
{
  return mpz_get_str(buf, 10, z);
}
