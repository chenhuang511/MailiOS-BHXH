/*
* SHA-160
* (C) 1999-2007 Jack Lloyd
*
* Distributed under the terms of the Botan license
*/

#ifndef BOTAN_SHA_160_H__
#define BOTAN_SHA_160_H__

#include "mdx_hash.h"
//#include <android/log.h>
//#define  LOG_TAG    "sha160.h"
//#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)

namespace Botan {

/**
* NIST's SHA-160
*/
class  SHA_160 : public MDx_HashFunction
   {
   public:
      std::string name() const { return "SHA-160"; }
      size_t output_length() const { return 20; }
      HashFunction* clone() const { return new SHA_160; }

      void clear();

      SHA_160() : MDx_HashFunction(64, true, true), digest(5), W(80)
         {
//    	 LOGI("6");
         clear();
         }
   protected:
      /**
      * Set a custom size for the W array. Normally 80, but some
      * subclasses need slightly more for best performance/internal
      * constraints
      * @param W_size how big to make W
      */
      SHA_160(size_t W_size) :
         MDx_HashFunction(64, true, true), digest(5), W(W_size)
         {
         clear();
         }

      void compress_n(const byte[], size_t blocks);
      void copy_out(byte[]);

      /**
      * The digest value, exposed for use by subclasses (asm, SSE2)
      */
      SecureVector<u32bit> digest;

      /**
      * The message buffer, exposed for use by subclasses (asm, SSE2)
      */
      SecureVector<u32bit> W;
   };

}

#endif