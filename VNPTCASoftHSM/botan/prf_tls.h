/*
* TLS v1.0 and v1.2 PRFs
* (C) 2004-2010 Jack Lloyd
*
* Distributed under the terms of the Botan license
*/

#ifndef BOTAN_TLS_PRF_H__
#define BOTAN_TLS_PRF_H__

#include "kdf.h"
#include "mac.h"
#include "hash.h"

namespace Botan {

/**
* PRF used in TLS 1.0/1.1
*/
class  TLS_PRF : public KDF
   {
   public:
      SecureVector<byte> derive(size_t key_len,
                                const byte secret[], size_t secret_len,
                                const byte seed[], size_t seed_len) const;

      std::string name() const { return "TLS-PRF"; }
      KDF* clone() const { return new TLS_PRF; }

      TLS_PRF();
      ~TLS_PRF();
   private:
      MessageAuthenticationCode* hmac_md5;
      MessageAuthenticationCode* hmac_sha1;
   };

/**
* PRF used in TLS 1.2
*/
class  TLS_12_PRF : public KDF
   {
   public:
      SecureVector<byte> derive(size_t key_len,
                                const byte secret[], size_t secret_len,
                                const byte seed[], size_t seed_len) const;

      std::string name() const { return "TLSv12-PRF(" + hmac->name() + ")"; }
      KDF* clone() const { return new TLS_12_PRF(hmac->clone()); }

      TLS_12_PRF(MessageAuthenticationCode* hmac);
      ~TLS_12_PRF();
   private:
      MessageAuthenticationCode* hmac;
   };

}

#endif