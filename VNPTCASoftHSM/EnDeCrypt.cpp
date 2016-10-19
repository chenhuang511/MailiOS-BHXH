/*
 * EnDeCrypt.cpp
 *
 *  Created on: May 3, 2013
 *      Author: Admin
 */

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include "EnDeCrypt.h"


#include "openssl/aes.h"

int htoi(const char* f) {
    int  z, n;
    n = 0;

    for (z = 0; f[z] >= '0' && f[z] <= 'F'; ++z)
        if (f[z] >= 'A' && f[z] <= 'F')
            n = 10 + 16 * n + (f[z] - 'A');
        else
            n = 16 * n + (f[z] - '0');

    return n;
}

/*
 * bin2hex() takes a block of data provided in pcIbuf with a length
 * of len and converts it into a zero-terminated ascii string of
 * hexadecimal characters.  It returns the length of the resulting
 * hexadecimal string (exclusive of the terminating zero).
 */

unsigned int
bin2hex (unsigned char *pcIbuf, unsigned char *pszObuf, unsigned int ilen)
{
  unsigned int  i;			// loop iteration conuter
  unsigned int  j = (ilen * 2) + 1;	// output buffer length
  unsigned char *p;

  p = pszObuf;		// point to start of output buffer
 
  for (i = 0; i < ilen; i++) {
    sprintf((char*) p, "%2.2x", (unsigned char) pcIbuf [i]);
    p += 2;
	j -= 2;
  }
//  *p = '\0';
  return (ilen* 2);
}

/*
 * The PadData() function is used to pad input data
 * for cipher block chaining using standard padding
 * as specified in PKCS 5.  Input data is padded in
 * place.  ilen is the length of the data before
 * padding.  blksize is the block size to use (16 for
 * AES CBC).  The function returns the length of ibuf
 * after padding.  Note that ibuf must be able to hold
 * at least blksize extra bytes.
 */


unsigned int
PadData (unsigned char *ibuf, unsigned int ilen, int blksize)
{
  unsigned int   i;			// loop counter
  unsigned char  pad;		// pad character (calculated)
  unsigned char *p;			// pointer to end of data

  // calculate pad character
  pad = (unsigned char) (blksize - (ilen % blksize));
  
  // append pad to end of string
  p = ibuf + ilen;
  for (i = 0; i < (int) pad; i++) {
    *p = pad;
	++p;
  }

  return (ilen + pad);
}


/*
 * hex2bin() converts an array of hex digits into an array of binary values.
 * Inputs are pointers to the input and output character arrays, and the
 * length on the input string.  The function returns the length of the
 * resulting output array, or 0 if there is an error.  If the input string
 * is zero terminated, you can call this as follows:
 *
 *   ilen = hex2bin (ibuf, obuf, strlen (ibuf));
 *
 * Note that the output is not terminated by a zero as the output
 * list is likely contain binary data.
 */

unsigned int
hex2bin (unsigned char *ibuf, unsigned char *obuf, unsigned int ilen)
{
  unsigned int   i;			// loop iteration variable
  unsigned int   j;			// current character
  unsigned int   by = 0;	// byte value for conversion
  unsigned char  ch;		// current character

  // process the list of characaters
  for (i = 0; i < ilen; i++) {
    ch = toupper(*ibuf++);		// get next uppercase character
    // do the conversion
    if(ch >= '0' && ch <= '9')
      by = (by << 4) + ch - '0';
    else if(ch >= 'A' && ch <= 'F')
      by = (by << 4) + ch - 'A' + 10;
    else {				// error if not hexadecimal
      memcpy (obuf,"ERROR",5);
      return 0;
    }

    // store a byte for each pair of hexadecimal digits
    if (i & 1) {
      j = ((i + 1) / 2) - 1;
      obuf [j] = by & 0xff;
    }
  }

  return (j+1);
}

/*
 * NoPadLen() will recalculate the length of an array of data after the pad
 * characters have been removed and will return the new length to the
caller.
 * Note that nothing is altered by this routine -- it simply returns the
 * adjusted length after taking into account the removal of the padding.
 *
 * NOTE: Assuming "buf" is a character array that contains your data after
 * it has been decrypted (with padding still appended), you can remove the
 * padding and zero terminate the text string by using the following
 * construct:
 *
 *   buf [NoPadLen (buf, len)] = 0x00;
 */

unsigned int
NoPadLen (unsigned char *ibuf, unsigned int ilen)
{
  unsigned int   i;			// adjusted length
  unsigned char *p;			// pointer to last character

  p = ibuf + (ilen - 1);
  i = ilen - (unsigned int) *p;
  return (i);
}


int encypt_openssl(unsigned char* data, unsigned char* encoded, unsigned char* key, int size)
{
	  unsigned long ilen;
	  unsigned char ibuf[size +  16];	// hex encrypt output
	  unsigned char obuf[size * 16];	// encrypt output
//	  unsigned char xbuf[size * 16];	// hex encrypt output
//	  unsigned char key1[] = KEY;
	  unsigned char iv[]  = IV;
	  AES_KEY aeskeyEnc;
	  	  // Step 1: prepare the input data with padding
	      memset (ibuf, 0x00, sizeof (ibuf));
	      memcpy (ibuf, data, size);

	      //Step 2:  calc length of aes output block
	      ilen = PadData (ibuf, size, BLOCK_LEN);
	      //Step 3:  init cipher keys
	      AES_set_encrypt_key (key, 256, &aeskeyEnc);

	      //Step 4:  encrypt string
	      memcpy (iv, IV, 16);
	      AES_cbc_encrypt (ibuf, obuf, ilen, &aeskeyEnc, iv, AES_ENCRYPT);

	      //Step 5:  convert encoded string to hex and display
	      int length = bin2hex (obuf, encoded, ilen);

	      //Step 6: add blank line for input prompt
	      return length;

}



int decrypt_openssl(unsigned char* data, unsigned char* endcoded, unsigned char* key, int size)
{
	unsigned long ilen;
//	  unsigned char data[MAXBUF];	// command line hex input
	  unsigned char ibuf[size + 16];	// hex decrypt output
//	  unsigned char obuf[size * 116];	// decrypt output
//	  unsigned char key1[] = KEY;
	  unsigned char iv[]  = IV;
	  AES_KEY aeskeyDec;

	 	    //Step 1:  init cipher keys
	    AES_set_decrypt_key (key, 256, &aeskeyDec);
	    //Step 2:  convert hex string to binary
	    ilen = hex2bin (data, ibuf, size);
	 
	    //Step 3:  decrypt text string
	    memcpy (iv, IV, strlen((char* const)IV));
	    AES_cbc_encrypt (ibuf, endcoded, ilen, &aeskeyDec, iv, AES_DECRYPT);
	    int length = NoPadLen (endcoded, ilen);

	    endcoded [NoPadLen (endcoded, ilen)] = 0x00;
	    //Step 4:  add blank line for input prompt
	    return length;

}


