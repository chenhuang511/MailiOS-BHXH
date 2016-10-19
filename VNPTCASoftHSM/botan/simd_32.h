/*
* Lightweight wrappers for SIMD operations
* (C) 2009,2011 Jack Lloyd
*
* Distributed under the terms of the Botan license
*/

#ifndef BOTAN_SIMD_32_H__
#define BOTAN_SIMD_32_H__

#include "types.h"

#if defined(BOTAN_HAS_SIMD_SSE2)
  #include "simd_sse2.h"
  namespace Botan { typedef SIMD_SSE2 SIMD_32; }

#elif defined(BOTAN_HAS_SIMD_ALTIVEC)
  #include "simd_altivec.h"
  namespace Botan { typedef SIMD_Altivec SIMD_32; }

#elif defined(BOTAN_HAS_SIMD_SCALAR)
  #include "simd_scalar.h"
  namespace Botan { typedef SIMD_Scalar SIMD_32; }

//#else
//  #error "No SIMD module defined"

#endif

#endif
