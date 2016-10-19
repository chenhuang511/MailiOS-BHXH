/*
* Hash Function Base Class
* (C) 1999-2008 Jack Lloyd
*
* Distributed under the terms of the Botan license
*/

#ifndef BOTAN_HASH_FUNCTION_BASE_CLASS_H__
#define BOTAN_HASH_FUNCTION_BASE_CLASS_H__

#include "buf_comp.h"
#include "algo_base.h"
#include <string>

namespace Botan {

/**
* This class represents hash function (message digest) objects
*/
class  HashFunction : public Buffered_Computation,
                               public Algorithm
   {
   public:
      /**
      * Get a new object representing the same algorithm as *this
      */
      virtual HashFunction* clone() const = 0;

      /**
      * The hash block size as defined for this algorithm
      */
      virtual size_t hash_block_size() const { return 0; }
   };

}

#endif
