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

#include <stdlib.h>     // malloc
#include <string.h>     // memset

#include "../gmp/gmp.h"

#include "feline.h"

#ifdef WIN64
#define SIZEOF_LONG 4
#else
#define SIZEOF_LONG 8
#endif

#define MOST_POSITIVE_FIXNUM          1152921504606846975
#define MOST_NEGATIVE_FIXNUM         -1152921504606846976

static inline cell make_fixnum(signed long int n)
{
  // see _tag_fixnum in macros.asm
  return ((n << 3) + 1);
}

typedef struct {
  cell object_header;
  mpz_t z;
} bignum;

void *bignum_allocate()
{
  // + 8 for object header
  return malloc(sizeof(mpz_t) + 8);
}

bignum *make_bignum(mpz_t z)
{
  bignum *p = bignum_allocate();
  memset(p, 0, sizeof(bignum));
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

void bignum_init_set_si(mpz_t z, cell n)
{
#if SIZEOF_LONG == 4
  long int lo = (n & 0xffffffff);
  long int hi = (n >> 32);
  if (hi != 0)
    {
      mpz_init_set_si(z, hi);
      mpz_mul_2exp(z, z, 32);
      mpz_add_ui(z, z, lo);
    }
  else
    mpz_init_set_si(z, lo);
#else
  mpz_init_set_si(z, n);
#endif
}

cell normalize(mpz_t z)
{
  if (mpz_fits_slong_p(z))
    {
      long n = mpz_get_si(z);
      if (n >= MOST_NEGATIVE_FIXNUM && n <= MOST_POSITIVE_FIXNUM)
        {
          mpz_clear(z);
          return make_fixnum(n);
        }
    }
  return (cell) make_bignum(z);
}

cell bignum_add_bignum (bignum *b1, bignum *b2)
{
  mpz_t result;
  mpz_init_set(result, b1->z);
  mpz_add(result, result, b2->z);
  return normalize(result);
}

cell bignum_add(bignum *b, cell n)
{
  mpz_t result;
  mpz_init_set(result, b->z);
#if SIZEOF_LONG == 4
  if (n < INT32_MIN || n > INT32_MAX)
    {
      mpz_t z;
      bignum_init_set_si(z, n);
      mpz_add(result, result, z);
      return normalize(result);
    }
#endif
  if (n >= 0)
    mpz_add_ui(result, result, (unsigned long) n);
  else
    mpz_sub_ui(result, result, (unsigned long) -n);
  return normalize(result);
}

size_t bignum_sizeinbase(const mpz_t z, int base)
{
  return mpz_sizeinbase(z, base);
}

char * bignum_get_str(char *buf, int base, const mpz_t z)
{
  return mpz_get_str(buf, base, z);
}
