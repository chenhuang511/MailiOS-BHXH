/*
* RC5
* (C) 1999-2007 Jack Lloyd
*
* Distributed under the terms of the Botan license
*/

#include "../botan/rc5.h"
#include "../botan/loadstor.h"
#include "../botan/rotate.h"
#include "../botan/parsing.h"
#include <algorithm>

namespace Botan {

/*
* RC5 Encryption
*/
void RC5::encrypt_n(const byte in[], byte out[], size_t blocks) const
   {
   const size_t rounds = (S.size() - 2) / 2;

   for(size_t i = 0; i != blocks; ++i)
      {
      u32bit A = load_le<u32bit>(in, 0);
      u32bit B = load_le<u32bit>(in, 1);

      A += S[0]; B += S[1];
      for(size_t j = 0; j != rounds; j += 4)
         {
         A = rotate_left(A ^ B, B % 32) + S[2*j+2];
         B = rotate_left(B ^ A, A % 32) + S[2*j+3];

         A = rotate_left(A ^ B, B % 32) + S[2*j+4];
         B = rotate_left(B ^ A, A % 32) + S[2*j+5];

         A = rotate_left(A ^ B, B % 32) + S[2*j+6];
         B = rotate_left(B ^ A, A % 32) + S[2*j+7];

         A = rotate_left(A ^ B, B % 32) + S[2*j+8];
         B = rotate_left(B ^ A, A % 32) + S[2*j+9];
         }

      store_le(out, A, B);

      in += BLOCK_SIZE;
      out += BLOCK_SIZE;
      }
   }

/*
* RC5 Decryption
*/
void RC5::decrypt_n(const byte in[], byte out[], size_t blocks) const
   {
   const size_t rounds = (S.size() - 2) / 2;

   for(size_t i = 0; i != blocks; ++i)
      {
      u32bit A = load_le<u32bit>(in, 0);
      u32bit B = load_le<u32bit>(in, 1);

      for(size_t j = rounds; j != 0; j -= 4)
         {
         B = rotate_right(B - S[2*j+1], A % 32) ^ A;
         A = rotate_right(A - S[2*j  ], B % 32) ^ B;

         B = rotate_right(B - S[2*j-1], A % 32) ^ A;
         A = rotate_right(A - S[2*j-2], B % 32) ^ B;

         B = rotate_right(B - S[2*j-3], A % 32) ^ A;
         A = rotate_right(A - S[2*j-4], B % 32) ^ B;

         B = rotate_right(B - S[2*j-5], A % 32) ^ A;
         A = rotate_right(A - S[2*j-6], B % 32) ^ B;
         }
      B -= S[1]; A -= S[0];

      store_le(out, A, B);

      in += BLOCK_SIZE;
      out += BLOCK_SIZE;
      }
   }

/*
* RC5 Key Schedule
*/
void RC5::key_schedule(const byte key[], size_t length)
   {
   const size_t WORD_KEYLENGTH = (((length - 1) / 4) + 1);
   const size_t MIX_ROUNDS     = 3 * std::max(WORD_KEYLENGTH, S.size());

   S[0] = 0xB7E15163;
   for(size_t i = 1; i != S.size(); ++i)
      S[i] = S[i-1] + 0x9E3779B9;

   SecureVector<u32bit> K(8);

   for(s32bit i = length-1; i >= 0; --i)
      K[i/4] = (K[i/4] << 8) + key[i];

   u32bit A = 0, B = 0;

   for(size_t i = 0; i != MIX_ROUNDS; ++i)
      {
      A = rotate_left(S[i % S.size()] + A + B, 3);
      B = rotate_left(K[i % WORD_KEYLENGTH] + A + B, (A + B) % 32);
      S[i % S.size()] = A;
      K[i % WORD_KEYLENGTH] = B;
      }
   }

/*
* Return the name of this type
*/
std::string RC5::name() const
   {
   return "RC5(" + to_string(get_rounds()) + ")";
   }

/*
* RC5 Constructor
*/
RC5::RC5(size_t rounds)
   {
   if(rounds < 8 || rounds > 32 || (rounds % 4 != 0))
      throw Invalid_Argument("RC5: Invalid number of rounds " +
                             to_string(rounds));

   S.resize(2*rounds + 2);
   }

}
