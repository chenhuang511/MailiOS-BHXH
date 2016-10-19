/*
* DLIES
* (C) 1999-2007 Jack Lloyd
*
* Distributed under the terms of the Botan license
*/

#ifndef BOTAN_DLIES_H__
#define BOTAN_DLIES_H__

#include "pubkey.h"
#include "mac.h"
#include "kdf.h"

namespace Botan {

/**
* DLIES Encryption
*/
class  DLIES_Encryptor : public PK_Encryptor
   {
   public:
      DLIES_Encryptor(const PK_Key_Agreement_Key&,
                      KDF* kdf,
                      MessageAuthenticationCode* mac,
                      size_t mac_key_len = 20);

      ~DLIES_Encryptor();

      void set_other_key(const MemoryRegion<byte>&);
   private:
      SecureVector<byte> enc(const byte[], size_t,
                             RandomNumberGenerator&) const;
      size_t maximum_input_size() const;

      SecureVector<byte> other_key, my_key;

      PK_Key_Agreement ka;
      KDF* kdf;
      MessageAuthenticationCode* mac;
      size_t mac_keylen;
   };

/**
* DLIES Decryption
*/
class  DLIES_Decryptor : public PK_Decryptor
   {
   public:
      DLIES_Decryptor(const PK_Key_Agreement_Key&,
                      KDF* kdf,
                      MessageAuthenticationCode* mac,
                      size_t mac_key_len = 20);

      ~DLIES_Decryptor();

   private:
      SecureVector<byte> dec(const byte[], size_t) const;

      SecureVector<byte> my_key;

      PK_Key_Agreement ka;
      KDF* kdf;
      MessageAuthenticationCode* mac;
      size_t mac_keylen;
   };

}

#endif