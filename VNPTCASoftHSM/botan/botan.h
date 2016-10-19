/*
* A vague catch all include file for Botan
* (C) 1999-2007 Jack Lloyd
*
* Distributed under the terms of the Botan license
*/

#ifndef BOTAN_BOTAN_H__
#define BOTAN_BOTAN_H__

#include "init.h"
#include "lookup.h"
#include "libstate.h"
#include "version.h"
#include "parsing.h"

#include "rng.h"

#if defined(BOTAN_HAS_AUTO_SEEDING_RNG)
  #include "auto_rng.h"
#endif

#endif
