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

#include "feline.h"

cell c_fixnum_expt(cell base, cell power)
{
  mpz_t z;
  mpz_init(z);
  mpz_ui_pow_ui(z, (unsigned long int)base, (unsigned long int)power);
  return normalize(z);
}

cell c_bignum_expt(Bignum *b, cell power)
{
  mpz_t z;
  mpz_init(z);
  mpz_pow_ui(z, b->z, (unsigned long int)power);
  return normalize(z);
}
