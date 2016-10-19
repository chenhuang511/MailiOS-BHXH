/*
* Algorithm Identifier
* (C) 1999-2007 Jack Lloyd
*
* Distributed under the terms of the Botan license
*/

#ifndef BOTAN_ALGORITHM_IDENTIFIER_H__
#define BOTAN_ALGORITHM_IDENTIFIER_H__

#include "asn1_int.h"
#include "asn1_oid.h"
#include <string>

namespace Botan {

/**
* Algorithm Identifier
*/
class AlgorithmIdentifier : public ASN1_Object
   {
   public:
      enum Encoding_Option { USE_NULL_PARAM };

      void encode_into(class DER_Encoder&) const;
      void decode_from(class BER_Decoder&);

      AlgorithmIdentifier() {}
      AlgorithmIdentifier(const OID&, Encoding_Option);
      AlgorithmIdentifier(const std::string&, Encoding_Option);

      AlgorithmIdentifier(const OID&, const MemoryRegion<byte>&);
      AlgorithmIdentifier(const std::string&, const MemoryRegion<byte>&);

      OID oid;
      SecureVector<byte> parameters;
   };

/*
* Comparison Operations
*/
bool operator==(const AlgorithmIdentifier&,
                          const AlgorithmIdentifier&);
bool operator!=(const AlgorithmIdentifier&,
                          const AlgorithmIdentifier&);

}

#endif
