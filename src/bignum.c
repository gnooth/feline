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
#include <string.h>     // memset

#include "../gmp/gmp.h"

#include "feline.h"

#define MOST_POSITIVE_FIXNUM          1152921504606846975
#define MOST_NEGATIVE_FIXNUM         -1152921504606846976

struct bignum {
  Cell object_header;
  mpz_t z;
};

void *bignum_allocate()
{
  // + 8 for object header
  return malloc(sizeof(mpz_t) + 8);
}

struct bignum *make_bignum(mpz_t z)
{
  struct bignum *p = bignum_allocate();
  memset(p, 0, sizeof(struct bignum));
  mpz_init_set(p->z, z);
  return p;
}

void bignum_free(mpz_t z)
{
  mpz_clear(z);
}

void bignum_init(mpz_t z)
{
  mpz_init(z);
}

void bignum_init_set_ui(mpz_t z, unsigned long int n)
{
  mpz_init_set_ui(z, n);
}

void bignum_init_set_si(mpz_t z, signed long int n)
{
  mpz_init_set_si(z, n);
}

void *bignum_add(struct bignum *b, long n)
{
  mpz_t result;
  mpz_init_set(result, b->z);
  if (n >= 0)
    mpz_add_ui(result, result, (unsigned long) n);
  else
    mpz_sub_ui(result, result, (unsigned long) -n);
  if (mpz_fits_slong_p(result))
    {
      long n = mpz_get_si(result);
      if (n >= MOST_NEGATIVE_FIXNUM && n <= MOST_POSITIVE_FIXNUM)
        {
          mpz_clear(result);
          return (void *) ((n << 3) + 1);
        }
    }
  return make_bignum(result);
}

size_t bignum_sizeinbase(const mpz_t z, int base)
{
  return mpz_sizeinbase(z, base);
}

char * bignum_get_str(char *buf, int base, const mpz_t z)
{
  return mpz_get_str(buf, base, z);
}
