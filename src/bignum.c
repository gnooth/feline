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
#include <string.h>     // memset

#include "feline.h"

#ifdef WIN64
#define SIZEOF_LONG 4
#else
#define SIZEOF_LONG 8
#endif

const cell MOST_POSITIVE_FIXNUM =  1152921504606846975;
const cell MOST_NEGATIVE_FIXNUM = -1152921504606846976;

#define OBJECT_TYPE_BIGNUM      8

#define T_VALUE                14
#define F_VALUE                 6

extern cell get_handle_for_object(cell);

static inline cell make_fixnum(cell n)
{
  // see _tag_fixnum in macros.asm
  return ((n << 3) + 1);
}

static void *c_bignum_allocate()
{
  Bignum *b = malloc(sizeof(Bignum));
  memset(b, 0, sizeof(Bignum));
  b->object_header = OBJECT_TYPE_BIGNUM;
  return b;
}

static Bignum *c_make_bignum(mpz_t z)
{
  Bignum *b = c_bignum_allocate();
  mpz_init_set(b->z, z);
  return b;
}

void c_bignum_free(mpz_t z)
{
  mpz_clear(z);
}

void c_bignum_init(mpz_t z)
{
  mpz_init(z);
}

void c_bignum_init_set_ui(mpz_t z, cell n)
{
#if SIZEOF_LONG == 4
  long int lo = (n & 0xffffffff);
  long int hi = (n >> 32);
  if (hi != 0)
    {
      mpz_init_set_ui(z, hi);
      mpz_mul_2exp(z, z, 32);
      mpz_add_ui(z, z, lo);
    }
  else
    mpz_init_set_ui(z, lo);
#else
  mpz_init_set_ui(z, n);
#endif
}

void c_bignum_init_set_si(mpz_t z, cell n)
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

cell c_bignum_from_signed(cell n)
{
  Bignum *b = c_bignum_allocate();
  c_bignum_init_set_si(b->z, n);
  return get_handle_for_object((cell)b);
}

cell c_bignum_from_unsigned(cell n)
{
  Bignum *b = c_bignum_allocate();
  c_bignum_init_set_ui(b->z, n);
  return get_handle_for_object((cell)b);
}

static cell normalize(mpz_t z)
{
#if SIZEOF_LONG == 8
  if (mpz_fits_slong_p(z))
    {
      long n = mpz_get_si(z);
      if (n >= MOST_NEGATIVE_FIXNUM && n <= MOST_POSITIVE_FIXNUM)
        {
          mpz_clear(z);
          return make_fixnum(n);
        }
    }
#else
  size_t size = mpz_size(z);

  if (size == 0)
    return make_fixnum(0);

  if (size == 1)
    {
      int sign = mpz_sgn(z);
      mp_limb_t n = mpz_getlimbn(z, 0);
      if (sign == 1)
        {
          if (n <= MOST_POSITIVE_FIXNUM)
            {
              mpz_clear(z);
              return make_fixnum(n);
            }
        }
      else if (sign == -1)
        {
          if (n <= -MOST_NEGATIVE_FIXNUM)
            {
              mpz_clear(z);
              return make_fixnum(-n);
            }
        }
    }
#endif
  Bignum *b = c_make_bignum(z);
  mpz_clear(z);
  return get_handle_for_object((cell)b);
}

cell c_bignum_bignum_plus(Bignum *b1, Bignum *b2)
{
  mpz_t result;
  mpz_init_set(result, b1->z);
  mpz_add(result, result, b2->z);
  return normalize(result);
}

cell c_bignum_bignum_minus(Bignum *b1, Bignum *b2)
{
  mpz_t result;
  mpz_init_set(result, b1->z);
  mpz_sub(result, result, b2->z);
  return normalize(result);
}

cell c_bignum_bignum_lt(Bignum *b1, Bignum *b2)
{
  return mpz_cmp(b1->z, b2->z) < 0 ? T_VALUE : F_VALUE;
}

cell c_bignum_bignum_le(Bignum *b1, Bignum *b2)
{
  return mpz_cmp(b1->z, b2->z) <= 0 ? T_VALUE : F_VALUE;
}

cell c_bignum_fixnum_plus(Bignum *b, cell n)
{
  mpz_t result;
  mpz_init_set(result, b->z);
#if SIZEOF_LONG == 4
  if (n < INT32_MIN || n > INT32_MAX)
    {
      mpz_t z;
      c_bignum_init_set_si(z, n);
      mpz_add(result, result, z);
      mpz_clear(z);
      return normalize(result);
    }
#endif
  if (n >= 0)
    mpz_add_ui(result, result, (unsigned long) n);
  else
    mpz_sub_ui(result, result, (unsigned long) -n);
  return normalize(result);
}

size_t c_bignum_sizeinbase(const mpz_t z, int base)
{
  return mpz_sizeinbase(z, base);
}

char * c_bignum_get_str(char *buf, int base, const mpz_t z)
{
  return mpz_get_str(buf, base, z);
}

cell c_string_to_integer(char *s, int base)
{
  char *endptr;
  long n = strtol(s, &endptr, base);

  if (*endptr != '\0')
    return F_VALUE;

#if SIZEOF_LONG == 8
  if (n >= MOST_NEGATIVE_FIXNUM && n <= MOST_POSITIVE_FIXNUM)
    return make_fixnum(n);
#endif

  // "The strtol() function returns the result of the conversion, unless the
  // value would underflow or overflow. If an underflow occurs, strtol()
  // returns LONG_MIN. If an overflow occurs, strtol() returns LONG_MAX."
  if (n > LONG_MIN && n < LONG_MAX)
    {
      // no overflow.
#if SIZEOF_LONG == 4
      if (n >= MOST_NEGATIVE_FIXNUM && n <= MOST_POSITIVE_FIXNUM)
        return make_fixnum(n);
#endif
      mpz_t z;
      mpz_init_set_si(z, n);
      Bignum *b = c_make_bignum(z);
      mpz_clear(z);
      return get_handle_for_object((cell)b);
    }

  // mpz_init_set_str() doesn't like a leading '+'
  if (*s == '+')
    ++s;

  mpz_t z;
  int error = mpz_init_set_str(z, s, base);
  if (error)
    {
      mpz_clear(z);
      return F_VALUE;
    }
  // conversion succeeded
  return normalize(z);
}

cell c_bignum_equal(Bignum *b1, Bignum *b2)
{
  return (mpz_cmp(b1->z, b2->z) == 0) ? T_VALUE : F_VALUE;
}

cell c_bignum_negate(Bignum *b)
{
  mpz_t z;
  mpz_init(z);
  mpz_neg(z, b->z);
  return normalize(z);
}

// FIXME incomplete
cell c_expt(cell base, cell power)
{
  mpz_t z;
  mpz_init(z);
  mpz_ui_pow_ui(z, (unsigned long int)base, (unsigned long int)power);
  return normalize(z);
}
