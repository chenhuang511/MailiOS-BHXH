/*
* MD4 (x86-32)
* (C) 1999-2007 Jack Lloyd
*
* Distributed under the terms of the Botan license
*/

//#ifndef BOTAN_MD4_X86_32_H__
#define BOTAN_MD4_X86_32_H__

#include "md4.h"

namespace Botan {

/**
* MD4 using x86 assembly
*/
class  MD4_X86_32 : public MD4
   {
   public:
      HashFunction* clone() const { return new MD4_X86_32; }
   private:
      void compress_n(const byte[], size_t blocks);
   };

}

//#endif
