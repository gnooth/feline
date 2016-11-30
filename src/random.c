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

#include <stdint.h>

// splitmix64
// Written in 2015 by Sebastiano Vigna (vigna@acm.org).
// http://xoroshiro.di.unimi.it/splitmix64.c
// public domain

static uint64_t x;

static uint64_t splitmix64_next()
{
  uint64_t z = (x += 0x9E3779B97F4A7C15);
  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9;
  z = (z ^ (z >> 27)) * 0x94D049BB133111EB;
  return z ^ (z >> 31);
}

// xoroshiro128+
// Written in 2016 by David Blackman and Sebastiano Vigna (vigna@acm.org).
// http://xoroshiro.di.unimi.it/xoroshiro128plus.c
// public domain

static uint64_t state0, state1;

static inline uint64_t rotl(const uint64_t s, int k)
{
  return (s << k) | (s >> (64 - k));
}

static inline uint64_t xoroshiro128plus_next()
{
  const uint64_t s0 = state0;
  uint64_t s1 = state1;
  const uint64_t result = s0 + s1;

  s1 ^= s0;
  state0 = rotl(s0, 55) ^ s1 ^ (s1 << 14);
  state1 = rotl(s1, 36);

  return result;
}


// Feline
void c_seed_random(uint64_t seed)
{
  x = seed;
  state0 = splitmix64_next();
  state1 = splitmix64_next();
}

uint64_t c_random()
{
  return xoroshiro128plus_next();
}
