/*
 * EnDeCrypt.h
 *
 *  Created on: May 3, 2013
 *      Author: Admin
 */

#ifndef ENDECRYPT_H_
#define ENDECRYPT_H_


# define BLOCK_LEN	16
# define MAXBUF		65536
# define MAXHEX		(MAXBUF * 2) + 1
# define KEY		"abcdefghijklmnopqrstuvwxyz012345"
# define IV		"RandomIVRandomIV"

int htoi(const char* f);
unsigned int
bin2hex (unsigned char *pcIbuf, unsigned char *pszObuf, unsigned int ilen);

unsigned int
PadData (unsigned char *ibuf, unsigned int ilen, int blksize);

unsigned int
hex2bin (unsigned char *ibuf, unsigned char *obuf, unsigned int ilen);

unsigned int
NoPadLen (unsigned char *ibuf, unsigned int ilen);

int encypt_openssl(unsigned char* data, unsigned char* encoded, unsigned char* key, int size);
int decrypt_openssl(unsigned char* data, unsigned char* decoded,  unsigned char* key, int size);



#endif /* ENDECRYPT_H_ */
