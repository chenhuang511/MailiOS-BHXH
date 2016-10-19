//
//  vdccaVerifier.m
//  VerifyCertificate
//
//  Created by Chen on 7/5/14.
//  Copyright (c) 2014 vdc. All rights reserved.
//

#import "vdccaVerifier.h"

static int ocsp_find_signer(X509 **psigner, OCSP_BASICRESP *bs,
                            STACK_OF(X509) * certs, X509_STORE *st,
                            unsigned long flags);
static int ocsp_check_issuer(OCSP_BASICRESP *bs, STACK_OF(X509) * chain,
                             unsigned long flags);

@implementation vdccaVerifier

#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <include/openssl/ocsp.h>
#include <include/openssl/bio.h>
#include <include/openssl/ssl.h>
#include <include/openssl/pem.h>
#include <include/openssl/conf.h>
#include <include/openssl/x509v3.h>
#ifndef OPENSSL_NO_ENGINE
#include <include/openssl/engine.h>
#endif

#define SPC_X509STORE_NO_DEFAULT_CAFILE 0x01
#define SPC_X509STORE_NO_DEFAULT_CAPATH 0x02

#define FORMAT_UNDEF 0
#define FORMAT_ASN1 1
#define FORMAT_TEXT 2
#define FORMAT_PEM 3
#define FORMAT_NETSCAPE 4
#define FORMAT_PKCS12 5
#define FORMAT_SMIME 6
#define FORMAT_ENGINE 7
#define FORMAT_IISSGC 8
#define NETSCAPE_CERT_HDR "certificate"

typedef int (*spc_x509verifycallback_t)(int, X509_STORE_CTX *);

typedef struct {
  char *cafile;
  char *capath;
  char *crlfile;
  spc_x509verifycallback_t callback;
  STACK_OF(X509) * certs;
  STACK_OF(X509_CRL) * crls;
  char *use_certfile;
  STACK_OF(X509) * use_certs;
  char *use_keyfile;
  EVP_PKEY *use_key;
  int flags;
} spc_x509store_t;

typedef struct pw_cb_data {
  const void *password;
  const char *prompt_info;
} PW_CB_DATA;

typedef struct {
  pem_password_cb *password_callback; /* Deprecated!  Only present for
                                       0260 backward compatibility! */
  UI_METHOD *ui_method;
  void *callback_data;
} HWCryptoHook_CallerContextValue;

typedef struct {
  char *url;
  X509 *cert;
  X509 *issuer;
  spc_x509store_t *store;
  X509 *sign_cert;
  EVP_PKEY *sign_key;
  long skew;
  long maxage;
} spc_ocsprequest_t;

typedef enum {
  SPC_OCSPRESULT_ERROR_INVALIDRESPONSE = -12,
  SPC_OCSPRESULT_ERROR_CONNECTFAILURE = -11,
  SPC_OCSPRESULT_ERROR_SIGNFAILURE = -10,
  SPC_OCSPRESULT_ERROR_BADOCSPADDRESS = -9,
  SPC_OCSPRESULT_ERROR_OUTOFMEMORY = -8,
  SPC_OCSPRESULT_ERROR_UNKNOWN = -7,
  SPC_OCSPRESULT_ERROR_UNAUTHORIZED = -6,
  SPC_OCSPRESULT_ERROR_SIGREQUIRED = -5,
  SPC_OCSPRESULT_ERROR_TRYLATER = -3,
  SPC_OCSPRESULT_ERROR_INTERNALERROR = -2,
  SPC_OCSPRESULT_ERROR_MALFORMEDREQUEST = -1,
  SPC_OCSPRESULT_CERTIFICATE_VALID = 0,
  SPC_OCSPRESULT_CERTIFICATE_REVOKED = 1
} spc_ocspresult_t;

/**
 *
 */
void spc_init_x509store(spc_x509store_t *spc_store) {
  spc_store->cafile = 0;
  spc_store->capath = 0;
  spc_store->crlfile = 0;
  spc_store->callback = 0;
  spc_store->certs = sk_X509_new_null();
  spc_store->crls = sk_X509_CRL_new_null();
  spc_store->use_certfile = 0;
  spc_store->use_certs = sk_X509_new_null();
  spc_store->use_keyfile = 0;
  spc_store->use_key = 0;
  spc_store->flags = 0;
}

/**
 *
 */
void spc_cleanup_x509store(spc_x509store_t *spc_store) {
  if (spc_store->cafile)
    free(spc_store->cafile);
  if (spc_store->capath)
    free(spc_store->capath);
  if (spc_store->crlfile)
    free(spc_store->crlfile);
  if (spc_store->use_certfile)
    free(spc_store->use_certfile);
  if (spc_store->use_keyfile)
    free(spc_store->use_keyfile);
  if (spc_store->use_key)
    EVP_PKEY_free(spc_store->use_key);
  sk_X509_free(spc_store->certs);
  //    sk_X509_free(spc_store->crls);
  sk_X509_free(spc_store->use_certs);
}

/**
 *
 */
X509_STORE *spc_create_x509store(spc_x509store_t *spc_store) {
  int i;
  X509_STORE *store;
  X509_LOOKUP *lookup;

  store = X509_STORE_new();
  /**
   if (spc_store->callback)
   X509_STORE_set_verify_cb_func(store, spc_store->callback);
   else
   X509_STORE_set_verify_cb_func(store, spc_verify_callback);
   **/

  if (!(lookup = X509_STORE_add_lookup(store, X509_LOOKUP_file())))
    goto error_exit;

  if (!spc_store->cafile) {
    printf("no CAFILE \n");
    if (!(spc_store->flags & SPC_X509STORE_NO_DEFAULT_CAFILE))
      X509_LOOKUP_load_file(lookup, 0, X509_FILETYPE_DEFAULT);
  } else {
    if (!X509_LOOKUP_load_file(lookup, spc_store->cafile, X509_FILETYPE_PEM))
      goto error_exit;
  }
  if (spc_store->crlfile) {
    if (!X509_load_crl_file(lookup, spc_store->crlfile, X509_FILETYPE_PEM))
      goto error_exit;
    X509_STORE_set_flags(store,
                         X509_V_FLAG_CRL_CHECK | X509_V_FLAG_CRL_CHECK_ALL);
  }

  if (!(lookup = X509_STORE_add_lookup(store, X509_LOOKUP_hash_dir())))
    goto error_exit;
  if (!spc_store->capath) {
    if (!(spc_store->flags & SPC_X509STORE_NO_DEFAULT_CAPATH))
      X509_LOOKUP_add_dir(lookup, 0, X509_FILETYPE_DEFAULT);
  } else if (!X509_LOOKUP_add_dir(lookup, spc_store->capath, X509_FILETYPE_PEM))
    goto error_exit;

  for (i = 0; i < sk_X509_num(spc_store->certs); i++)
    if (!X509_STORE_add_cert(store, sk_X509_value(spc_store->certs, i)))
      goto error_exit;
  for (i = 0; i < sk_X509_CRL_num(spc_store->crls); i++)
    if (!X509_STORE_add_crl(store, sk_X509_CRL_value(spc_store->crls, i)))
      goto error_exit;

  // printf("success spc_create_x509store\n");
  return store;

error_exit:
  printf("error_exit spc_create_x509store\n");

  if (store)
    X509_STORE_free(store);
  return 0;
}

/**
 *
 */
BIO *spc_connect(char *host, int port, int ssl, spc_x509store_t *spc_store,
                 SSL_CTX **ctx) {
  BIO *conn;
  *ctx = 0;
  if (!(conn = BIO_new_connect(host)))
    goto error_exit;
  BIO_set_conn_int_port(conn, &port);
  if (BIO_do_connect(conn) <= 0)
    goto error_exit;
  return conn;
error_exit:
  printf("error_exit  connect\n");

  if (conn)
    BIO_free_all(conn);
  return 0;
}

spc_ocspresult_t spc_verify_via_ocsp(spc_ocsprequest_t *data, char *file) {
  BIO *bio = 0;
  int rc, reason, ssl, status;
  char *host = 0, *path = 0, *port = 0;
  SSL_CTX *ctx = 0;
  X509_STORE *store = 0;
  OCSP_CERTID *id;
  OCSP_REQUEST *req = 0;
  OCSP_RESPONSE *resp = 0;
  OCSP_BASICRESP *basic = 0;
  spc_ocspresult_t result;
  STACK_OF(X509) * verify_cert;
  ASN1_GENERALIZEDTIME *producedAt, *thisUpdate, *nextUpdate;
  ENGINE *e;

  BIO *bio_err = NULL;
  const EVP_MD *cert_id_md;
  STACK_OF(OCSP_CERTID) *ids = NULL;
  BIO *out = NULL;
  STACK_OF(OPENSSL_STRING) *reqnames = NULL;
  result = SPC_OCSPRESULT_ERROR_UNKNOWN;
  if (!OCSP_parse_url(data->url, &host, &port, &path, &ssl)) {
    result = SPC_OCSPRESULT_ERROR_BADOCSPADDRESS;
    goto end;
  }
  if (!(req = OCSP_REQUEST_new())) {
    result = SPC_OCSPRESULT_ERROR_OUTOFMEMORY;
    goto end;
  }

  //
  // Here I guess is where you can add multiple certs" Right now we haev onlyone
  //
  cert_id_md = EVP_sha1();
  ids = sk_OCSP_CERTID_new_null();
  id = OCSP_cert_to_id(cert_id_md, data->cert, data->issuer);
  if (!id || !sk_OCSP_CERTID_push(ids, id))
    goto end;
  if (!id || !OCSP_request_add0_id(req, id))
    goto end;

  // lets do it twice what the heck
  // show how to do multiple x509s
  //      id = OCSP_cert_to_id(0, data->cert, data->issuer);
  //      if (!id || !OCSP_request_add0_id(req, id)) goto end;

  BIO_printf(bio_err, "OCSP utility\n");
  BIO_printf(bio_err, "Usage ocsp [options]\n");
  BIO_printf(bio_err, "where options are\n");
  BIO_printf(bio_err, "-out file          output filename\n");
  BIO_printf(bio_err, "-issuer file       issuer certificate\n");
  BIO_printf(bio_err, "-cert file         certificate to check\n");
  BIO_printf(bio_err, "-serial n          serial number to check\n");
  BIO_printf(bio_err,
             "-signer file       certificate to sign OCSP request with\n");
  BIO_printf(bio_err,
             "-signkey file      private key to sign OCSP request with\n");
  BIO_printf(bio_err, "-sign_other file   additional certificates to include "
                      "in signed request\n");
  BIO_printf(
      bio_err,
      "-no_certs          don't include any certificates in signed request\n");
  BIO_printf(bio_err, "-req_text          print text form of request\n");
  BIO_printf(bio_err, "-resp_text         print text form of response\n");
  BIO_printf(bio_err,
             "-text              print text form of request and response\n");
  BIO_printf(bio_err,
             "-reqout file       write DER encoded OCSP request to \"file\"\n");
  BIO_printf(bio_err,
             "-respout file      write DER encoded OCSP reponse to \"file\"\n");
  BIO_printf(
      bio_err,
      "-reqin file        read DER encoded OCSP request from \"file\"\n");
  BIO_printf(
      bio_err,
      "-respin file       read DER encoded OCSP reponse from \"file\"\n");
  BIO_printf(bio_err, "-nonce             add OCSP nonce to request\n");
  BIO_printf(bio_err, "-no_nonce          don't add OCSP nonce to request\n");
  BIO_printf(bio_err, "-url URL           OCSP responder URL\n");
  BIO_printf(bio_err,
             "-host host:n       send OCSP request to host on port n\n");
  BIO_printf(bio_err, "-path              path to use in OCSP request\n");
  BIO_printf(bio_err, "-CApath dir        trusted certificates directory\n");
  BIO_printf(bio_err, "-CAfile file       trusted certificates file\n");
  BIO_printf(bio_err, "-VAfile file       validator certificates file\n");
  BIO_printf(bio_err,
             "-validity_period n maximum validity discrepancy in seconds\n");
  BIO_printf(bio_err, "-status_age n      maximum status age in seconds\n");
  BIO_printf(bio_err, "-noverify          don't verify response at all\n");
  BIO_printf(
      bio_err,
      "-verify_other file additional certificates to search for signer\n");
  BIO_printf(bio_err,
             "-trust_other       don't verify additional certificates\n");
  BIO_printf(bio_err, "-no_intern         don't search certificates contained "
                      "in response for signer\n");
  BIO_printf(bio_err,
             "-no_signature_verify don't check signature on response\n");
  BIO_printf(bio_err, "-no_cert_verify    don't check signing certificate\n");
  BIO_printf(bio_err, "-no_chain          don't chain verify response\n");
  BIO_printf(
      bio_err,
      "-no_cert_checks    don't do additional checks on signing certificate\n");
  BIO_printf(bio_err, "-port num		 port to run responder on\n");
  BIO_printf(bio_err, "-index file	 certificate status index file\n");
  BIO_printf(bio_err, "-CA file		 CA certificate\n");
  BIO_printf(
      bio_err,
      "-rsigner file	 responder certificate to sign responses with\n");
  BIO_printf(bio_err, "-rkey file	 responder key to sign responses "
                      "with\n");
  BIO_printf(bio_err,
             "-rother file	 other certificates to include in response\n");
  BIO_printf(bio_err,
             "-resp_no_certs     don't include any certificates in response\n");
  BIO_printf(bio_err,
             "-nmin n	 	 number of minutes before next update\n");
  BIO_printf(bio_err, "-ndays n	 	 number of days before next update\n");
  BIO_printf(
      bio_err,
      "-resp_key_id       identify reponse by signing certificate key ID\n");
  BIO_printf(
      bio_err,
      "-nrequest n        number of requests to accept (default unlimited)\n");
  BIO_printf(bio_err, "-<dgst alg>     use specified digest in the request\n");

  // file = "/Users/ming/Desktop/1.pem";
  // CAFile = "/Users/tranha/Desktop/henhanvnpt.pem";
  reqnames = sk_OPENSSL_STRING_new_null();

  //    OCSP_request_add1_nonce(req, 0, -1);
  verify_cert =
      load_certs(bio_err, file, FORMAT_PEM, NULL, e, "validator certificate");

  if (!verify_cert)
    goto end;

  //    if (!store)
  //		store = setup_verify(bio_err, CAFile, NULL);
  //	if (!store)
  //		goto end;

  /* sign the request */
  //    if (data->sign_cert && data->sign_key &&
  //        !OCSP_request_sign(req, data->sign_cert, data->sign_key,
  //                           EVP_sha1(  ), 0,
  //                           0)) {
  //            result = SPC_OCSPRESULT_ERROR_SIGNFAILURE;
  //            goto end;
  //        }

  /* establish a connection to the OCSP responder */
  if (!(bio = spc_connect(host, atoi(port), ssl, data->store, &ctx))) {
    result = SPC_OCSPRESULT_ERROR_CONNECTFAILURE;
    goto end;
  }

  /* send the request and get a response */
  resp = OCSP_sendreq_bio(bio, path, req);
  if (resp == NULL)
    goto end;

  if ((rc = OCSP_response_status(resp)) != OCSP_RESPONSE_STATUS_SUCCESSFUL) {
    switch (rc) {
    case OCSP_RESPONSE_STATUS_MALFORMEDREQUEST:
      result = SPC_OCSPRESULT_ERROR_MALFORMEDREQUEST;
      break;
    case OCSP_RESPONSE_STATUS_INTERNALERROR:
      result = SPC_OCSPRESULT_ERROR_INTERNALERROR;
      break;
    case OCSP_RESPONSE_STATUS_TRYLATER:
      result = SPC_OCSPRESULT_ERROR_TRYLATER;
      break;
    case OCSP_RESPONSE_STATUS_SIGREQUIRED:
      result = SPC_OCSPRESULT_ERROR_SIGREQUIRED;
      break;
    case OCSP_RESPONSE_STATUS_UNAUTHORIZED:
      result = SPC_OCSPRESULT_ERROR_UNAUTHORIZED;
      break;
    }
    goto end;
  }

  /* verify the response */
  result = SPC_OCSPRESULT_ERROR_INVALIDRESPONSE;
  if (!(basic = OCSP_response_get1_basic(resp)))
    goto end;

  if (OCSP_check_nonce(req, basic) <= 0)
    goto end;

  if (data->store && !(store = spc_create_x509store(data->store)))
    goto end;

  // printf("verify signature\n");
  // verify signature
  rc = OCSP_basic_verify1(basic, verify_cert, store, OCSP_NOCHAIN);
  if (rc <= 0)
    rc = OCSP_basic_verify1(basic, NULL, store, 0);
  if (rc <= 0) {
    //    printf("verify signature failed\n");
    ERR_print_errors(bio_err);
  } else {
    BIO_printf(bio_err, "Response verify OK\n");
  }

  if (!OCSP_resp_find_status(basic, id, &status, &reason, &producedAt,
                             &thisUpdate, &nextUpdate)) {
    //     printf("verify signature failed\n");
    goto end;
  }

  //    if (!OCSP_check_validity(thisUpdate, nextUpdate, data->skew,
  //                             data->maxage))
  //        goto end;

  /* All done.  Set the return code based on the status from the
   response. */
  if (status == V_OCSP_CERTSTATUS_REVOKED)
    result = SPC_OCSPRESULT_CERTIFICATE_REVOKED;
  else
    result = SPC_OCSPRESULT_CERTIFICATE_VALID;

  if (!print_ocsp_summary(out, basic, req, reqnames, ids, NULL, NULL))
    ;
  goto end;
end:

  if (bio)
    BIO_free_all(bio);
  if (host)
    OPENSSL_free(host);
  if (port)
    OPENSSL_free(port);
  if (path)
    OPENSSL_free(path);
  if (req)
    OCSP_REQUEST_free(req);
  if (resp)
    OCSP_RESPONSE_free(resp);
  if (basic)
    OCSP_BASICRESP_free(basic);
  //      if (ctx) SSL_CTX_free(ctx);
  if (store)
    X509_STORE_free(store);
  return result;
}

void help() {
  printf("\nUsage:\n");
  printf("   ./OCSPrequest  <cert>  <issuer root>\n");
  printf("eg:\n");
  printf("    ./OCSPrequest 1000.pem   ./demoCA/cacert.pem\n\n");
  exit(0);
}

/**
 *
 */

+ (int)do_it:(char *)x509file inCAcert:(char *)inCAcert url:(char *)url;
{
  X509 *x = NULL;
  X509 *issuerRoot = NULL;

  printf("\nOCSP URL:       %s\n", url);
  printf("Cert checking:  %s\n", x509file);
  printf("Root issuer:    %s\n\n", inCAcert);

  ERR_load_BIO_strings();
  ERR_load_crypto_strings();
  OpenSSL_add_all_algorithms();
  OpenSSL_add_all_ciphers();
  OpenSSL_add_all_digests();

  FILE *fp = fopen(x509file, "rb");
  if (fp == NULL) {
    printf("X509 File not found %s which is to be verified\n", x509file);
    return 1;
  }
  x = PEM_read_X509(fp, &x, NULL, NULL);
  if (x == NULL) {
    fprintf(stderr, "null x509\n");
    return 1;
  }
  fclose(fp);

  fp = fopen(inCAcert, "rb");
  if (fp == NULL) {
    printf("INCA File not found %s which is to be verified\n", inCAcert);
    return 1;
  }
  issuerRoot = PEM_read_X509(fp, &issuerRoot, NULL, NULL);
  if (issuerRoot == NULL) {
    fprintf(stderr, "null x509 issuer Root\n");
    return 1;
  }
  fclose(fp);

  spc_ocsprequest_t *req =
      (spc_ocsprequest_t *)malloc(sizeof(spc_ocsprequest_t));
  req->url = url;
  req->cert = x;
  req->issuer = issuerRoot;
  req->store = (spc_x509store_t *)malloc(sizeof(spc_x509store_t));
  spc_init_x509store(req->store);
  req->store->cafile = inCAcert;

  req->sign_cert = NULL; // OCSP request is not optionally signed
  req->sign_key = NULL;
  req->skew = 5;   // 5 seconds
  req->maxage = 1; // recommended to set to one

  spc_ocspresult_t result = spc_verify_via_ocsp(req, x509file);

  switch (result) {
  case 0:
    printf("Verify result GOOD\n");
    break;
  case 1:
    printf("Verify result  REVOKED\n");
    break;
  default:
    printf("ERROR Verify result is %d \n", result);
    break;
  }
  return result;
}

STACK_OF(X509) * load_certs(BIO *err, const char *file, int format,
                            const char *pass, ENGINE *e, const char *desc) {
  STACK_OF(X509) * certs;
  if (!load_certs_crls(err, file, format, pass, e, desc, &certs, NULL))
    return NULL;
  return certs;
}

X509 *load_cert(BIO *err, const char *file, int format, const char *pass,
                ENGINE *e, const char *cert_descrip) {
  X509 *x = NULL;
  BIO *cert;
  HWCryptoHook_CallerContextValue *contextValue;
  if ((cert = BIO_new(BIO_s_file())) == NULL) {
    ERR_print_errors(err);
    goto end;
  }

  if (file == NULL) {
#ifdef _IONBF
#ifndef OPENSSL_NO_SETVBUF_IONBF
    setvbuf(stdin, NULL, _IONBF, 0);
#endif /* ndef OPENSSL_NO_SETVBUF_IONBF */
#endif
    BIO_set_fp(cert, stdin, BIO_NOCLOSE);
  } else {
    if (BIO_read_filename(cert, file) <= 0) {
      BIO_printf(err, "Error opening %s %s\n", cert_descrip, file);
      ERR_print_errors(err);
      goto end;
    }
  }

  if (format == FORMAT_ASN1)
    x = d2i_X509_bio(cert, NULL);
  else if (format == FORMAT_NETSCAPE) {
    NETSCAPE_X509 *nx;
    nx = (NETSCAPE_X509 *)(ASN1_ITEM_rptr(NETSCAPE_X509), cert, NULL);
    if (nx == NULL)
      goto end;

    if ((strncmp(NETSCAPE_CERT_HDR, (char *)nx->header->data,
                 nx->header->length) != 0)) {
      NETSCAPE_X509_free(nx);
      BIO_printf(err, "Error reading header on certificate\n");
      goto end;
    }
    x = nx->cert;
    nx->cert = NULL;
    NETSCAPE_X509_free(nx);
  } else if (format == FORMAT_PEM)
    x = PEM_read_bio_X509_AUX(cert, NULL, contextValue->password_callback,
                              NULL);
  else if (format == FORMAT_PKCS12) {

  } else {
    BIO_printf(err, "bad input format specified for %s\n", cert_descrip);
    goto end;
  }
end:
  if (x == NULL) {
    BIO_printf(err, "unable to load certificate\n");
    ERR_print_errors(err);
  }
  if (cert != NULL)
    BIO_free(cert);
  return (x);
}

static int load_certs_crls(BIO *err, const char *file, int format,
                           const char *pass, ENGINE *e, const char *desc,
                           STACK_OF(X509) * *pcerts,
                           STACK_OF(X509_CRL) * *pcrls) {
  int i;
  BIO *bio;
  STACK_OF(X509_INFO) *xis = NULL;
  X509_INFO *xi;
  PW_CB_DATA cb_data;
  int rv = 0;
  // HWCryptoHook_CallerContextValue *contextValue;

  cb_data.password = pass;
  cb_data.prompt_info = file;

  if (format != FORMAT_PEM) {
    BIO_printf(err, "bad input format specified for %s\n", desc);
    return 0;
  }

  if (file == NULL)
    bio = BIO_new_fp(stdin, BIO_NOCLOSE);
  else
    bio = BIO_new_file(file, "r");

  if (bio == NULL) {
    BIO_printf(err, "Error opening %s %s\n", desc, file ? file : "stdin");
    ERR_print_errors(err);
    return 0;
  }

  xis = PEM_X509_INFO_read_bio(bio, NULL, NULL, &cb_data);

  BIO_free(bio);

  if (pcerts) {
    *pcerts = sk_X509_new_null();
    if (!*pcerts)
      goto end;
  }

  if (pcrls) {
    *pcrls = sk_X509_CRL_new_null();
    if (!*pcrls)
      goto end;
  }

  for (i = 0; i < sk_X509_INFO_num(xis); i++) {
    xi = sk_X509_INFO_value(xis, i);
    if (xi->x509 && pcerts) {
      if (!sk_X509_push(*pcerts, xi->x509))
        goto end;
      xi->x509 = NULL;
    }
    if (xi->crl && pcrls) {
      if (!sk_X509_CRL_push(*pcrls, xi->crl))
        goto end;
      xi->crl = NULL;
    }
  }

  if (pcerts && sk_X509_num(*pcerts) > 0)
    rv = 1;

  if (pcrls && sk_X509_CRL_num(*pcrls) > 0)
    rv = 1;

end:

  if (xis)
    sk_X509_INFO_pop_free(xis, X509_INFO_free);

  if (rv == 0) {
    if (pcerts) {
      sk_X509_pop_free(*pcerts, X509_free);
      *pcerts = NULL;
    }
    if (pcrls) {
      sk_X509_CRL_pop_free(*pcrls, X509_CRL_free);
      *pcrls = NULL;
    }
    BIO_printf(err, "unable to load %s\n", pcerts ? "certificates" : "CRLs");
    ERR_print_errors(err);
  }
  return rv;
}

X509_STORE *setup_verify(BIO *bp, char *CAfile, char *CApath) {
  X509_STORE *store;
  X509_LOOKUP *lookup;
  if (!(store = X509_STORE_new()))
    goto end;
  lookup = X509_STORE_add_lookup(store, X509_LOOKUP_file());
  if (lookup == NULL)
    goto end;
  if (CAfile) {
    if (!X509_LOOKUP_load_file(lookup, CAfile, X509_FILETYPE_PEM)) {
      BIO_printf(bp, "Error loading file %s\n", CAfile);
      goto end;
    }
  } else
    X509_LOOKUP_load_file(lookup, NULL, X509_FILETYPE_DEFAULT);

  lookup = X509_STORE_add_lookup(store, X509_LOOKUP_hash_dir());
  if (lookup == NULL)
    goto end;
  if (CApath) {
    if (!X509_LOOKUP_add_dir(lookup, CApath, X509_FILETYPE_PEM)) {
      BIO_printf(bp, "Error loading directory %s\n", CApath);
      goto end;
    }
  } else
    X509_LOOKUP_add_dir(lookup, NULL, X509_FILETYPE_DEFAULT);

  ERR_clear_error();
  return store;
end:
  X509_STORE_free(store);
  return NULL;
}

int OCSP_basic_verify1(OCSP_BASICRESP *bs, STACK_OF(X509) * certs,
                       X509_STORE *st, unsigned long flags) {
  X509 *signer, *x;
  STACK_OF(X509) *chain = NULL;
  X509_STORE_CTX *ctx = X509_STORE_CTX_new();
  int ret = 0;
  ret = ocsp_find_signer(&signer, bs, certs, st, flags);
  if (!ret) {
    OCSPerr(OCSP_F_OCSP_BASIC_VERIFY, OCSP_R_SIGNER_CERTIFICATE_NOT_FOUND);
    goto end;
  }
  if ((ret == 2) && (flags & OCSP_TRUSTOTHER))
    flags |= OCSP_NOVERIFY;
  if (!(flags & OCSP_NOSIGS)) {
    EVP_PKEY *skey;
    skey = X509_get_pubkey(signer);
    if (skey) {
      ret = OCSP_BASICRESP_verify(bs, skey, 0);
      EVP_PKEY_free(skey);
    }
    if (!skey || ret <= 0) {
      OCSPerr(OCSP_F_OCSP_BASIC_VERIFY, OCSP_R_SIGNATURE_FAILURE);
      goto end;
    }
  }
  if (!(flags & OCSP_NOVERIFY)) {
    int init_res;
    if (flags & OCSP_NOCHAIN)
      init_res = X509_STORE_CTX_init(ctx, st, signer, NULL);
    else
      init_res = X509_STORE_CTX_init(ctx, st, signer, bs->certs);
    if (!init_res) {
      ret = -1;
      OCSPerr(OCSP_F_OCSP_BASIC_VERIFY, ERR_R_X509_LIB);
      goto end;
    }
    X509_STORE_CTX_set_flags(ctx, X509_V_FLAG_CB_ISSUER_CHECK);
    X509_STORE_CTX_set_purpose(ctx, X509_PURPOSE_OCSP_HELPER);
    ret = X509_verify_cert(ctx);
    chain = X509_STORE_CTX_get1_chain(ctx);
    X509_STORE_CTX_cleanup(ctx);
    if (ret <= 0) {
      //			i = X509_STORE_CTX_get_error(ctx);
      //			OCSPerr(OCSP_F_OCSP_BASIC_VERIFY,OCSP_R_CERTIFICATE_VERIFY_ERROR);
      //			ERR_add_error_data(2, "Verify error:",
      //                               X509_verify_cert_error_string(i));
      // printf("Verificatione error:
      // %s\n",X509_verify_cert_error_string(ctx->error));
      goto end;
    }
    if (flags & OCSP_NOCHECKS) {
      ret = 1;
      goto end;
    }
    /* At this point we have a valid certificate chain
     * need to verify it against the OCSP issuer criteria.
     */
    ret = ocsp_check_issuer(bs, chain, flags);

    /* If fatal error or valid match then finish */
    if (ret != 0)
      goto end;

    /* Easy case: explicitly trusted. Get root CA and
     * check for explicit trust
     */
    if (flags & OCSP_NOEXPLICIT)
      goto end;

    x = sk_X509_value(chain, sk_X509_num(chain) - 1);
    if (X509_check_trust(x, NID_OCSP_sign, 0) != X509_TRUST_TRUSTED) {
      OCSPerr(OCSP_F_OCSP_BASIC_VERIFY, OCSP_R_ROOT_CA_NOT_TRUSTED);
      goto end;
    }
    ret = 1;
  }

end:
  if (chain)
    sk_X509_pop_free(chain, X509_free);
  return ret;
}

static int ocsp_find_signer(X509 **psigner, OCSP_BASICRESP *bs,
                            STACK_OF(X509) * certs, X509_STORE *st,
                            unsigned long flags) {
  X509 *signer;
  OCSP_RESPID *rid = bs->tbsResponseData->responderId;
  if ((signer = ocsp_find_signer_sk(certs, rid))) {
    *psigner = signer;
    return 2;
  }
  if (!(flags & OCSP_NOINTERN) &&
      (signer = ocsp_find_signer_sk(bs->certs, rid))) {
    *psigner = signer;
    return 1;
  }
  /* Maybe lookup from store if by subject name */

  *psigner = NULL;
  return 0;
}

static X509 *ocsp_find_signer_sk(STACK_OF(X509) * certs, OCSP_RESPID *id) {
  int i;
  unsigned char tmphash[SHA_DIGEST_LENGTH], *keyhash;
  X509 *x;

  /* Easy if lookup by name */
  if (id->type == V_OCSP_RESPID_NAME)
    return X509_find_by_subject(certs, id->value.byName);

  /* Lookup by key hash */

  /* If key hash isn't SHA1 length then forget it */
  if (id->value.byKey->length != SHA_DIGEST_LENGTH)
    return NULL;
  keyhash = id->value.byKey->data;
  /* Calculate hash of each key and compare */
  for (i = 0; i < sk_X509_num(certs); i++) {
    x = sk_X509_value(certs, i);
    X509_pubkey_digest(x, EVP_sha1(), tmphash, NULL);
    if (!memcmp(keyhash, tmphash, SHA_DIGEST_LENGTH))
      return x;
  }
  return NULL;
}
static int ocsp_check_issuer(OCSP_BASICRESP *bs, STACK_OF(X509) * chain,
                             unsigned long flags) {
  STACK_OF(OCSP_SINGLERESP) * sresp;
  X509 *signer, *sca;
  OCSP_CERTID *caid = NULL;
  int i;
  sresp = bs->tbsResponseData->responses;

  if (sk_X509_num(chain) <= 0) {
    OCSPerr(OCSP_F_OCSP_CHECK_ISSUER, OCSP_R_NO_CERTIFICATES_IN_CHAIN);
    return -1;
  }

  /* See if the issuer IDs match. */
  i = ocsp_check_ids(sresp, &caid);

  /* If ID mismatch or other error then return */
  if (i <= 0)
    return i;

  signer = sk_X509_value(chain, 0);
  /* Check to see if OCSP responder CA matches request CA */
  if (sk_X509_num(chain) > 1) {
    sca = sk_X509_value(chain, 1);
    i = ocsp_match_issuerid(sca, caid, sresp);
    if (i < 0)
      return i;
    if (i) {
      /* We have a match, if extensions OK then success */
      if (ocsp_check_delegated(signer, (int)flags))
        return 1;
      return 0;
    }
  }

  /* Otherwise check if OCSP request signed directly by request CA */
  return ocsp_match_issuerid(signer, caid, sresp);
}

/* Check the issuer certificate IDs for equality. If there is a mismatch with
 * the same
 * algorithm then there's no point trying to match any certificates against the
 * issuer.
 * If the issuer IDs all match then we just need to check equality against one
 * of them.
 */

static int ocsp_check_ids(STACK_OF(OCSP_SINGLERESP) * sresp,
                          OCSP_CERTID **ret) {
  OCSP_CERTID *tmpid, *cid;
  int i, idcount;

  idcount = sk_OCSP_SINGLERESP_num(sresp);
  if (idcount <= 0) {
    OCSPerr(OCSP_F_OCSP_CHECK_IDS, OCSP_R_RESPONSE_CONTAINS_NO_REVOCATION_DATA);
    return -1;
  }

  cid = sk_OCSP_SINGLERESP_value(sresp, 0)->certId;

  *ret = NULL;

  for (i = 1; i < idcount; i++) {
    tmpid = sk_OCSP_SINGLERESP_value(sresp, i)->certId;
    /* Check to see if IDs match */
    if (OCSP_id_issuer_cmp(cid, tmpid)) {
      /* If algoritm mismatch let caller deal with it */
      if (OBJ_cmp(tmpid->hashAlgorithm->algorithm,
                  cid->hashAlgorithm->algorithm))
        return 2;
      /* Else mismatch */
      return 0;
    }
  }

  /* All IDs match: only need to check one ID */
  *ret = cid;
  return 1;
}

static int ocsp_match_issuerid(X509 *cert, OCSP_CERTID *cid,
                               STACK_OF(OCSP_SINGLERESP) * sresp) {
  /* If only one ID to match then do it */
  if (cid) {
    const EVP_MD *dgst;
    X509_NAME *iname;
    int mdlen;
    unsigned char md[EVP_MAX_MD_SIZE];
    if (!(dgst = EVP_get_digestbyobj(cid->hashAlgorithm->algorithm))) {
      OCSPerr(OCSP_F_OCSP_MATCH_ISSUERID, OCSP_R_UNKNOWN_MESSAGE_DIGEST);
      return -1;
    }

    mdlen = EVP_MD_size(dgst);
    if (mdlen < 0)
      return -1;
    if ((cid->issuerNameHash->length != mdlen) ||
        (cid->issuerKeyHash->length != mdlen))
      return 0;
    iname = X509_get_subject_name(cert);
    if (!X509_NAME_digest(iname, dgst, md, NULL))
      return -1;
    if (memcmp(md, cid->issuerNameHash->data, mdlen))
      return 0;
    X509_pubkey_digest(cert, dgst, md, NULL);
    if (memcmp(md, cid->issuerKeyHash->data, mdlen))
      return 0;

    return 1;

  } else {
    /* We have to match the whole lot */
    int i, ret;
    OCSP_CERTID *tmpid;
    for (i = 0; i < sk_OCSP_SINGLERESP_num(sresp); i++) {
      tmpid = sk_OCSP_SINGLERESP_value(sresp, i)->certId;
      ret = ocsp_match_issuerid(cert, tmpid, NULL);
      if (ret <= 0)
        return ret;
    }
    return 1;
  }
}

static int ocsp_check_delegated(X509 *x, int flags) {
  X509_check_purpose(x, -1, 0);
  if ((x->ex_flags & EXFLAG_XKUSAGE) && (x->ex_xkusage & XKU_OCSP_SIGN))
    return 1;
  OCSPerr(OCSP_F_OCSP_CHECK_DELEGATED, OCSP_R_MISSING_OCSPSIGNING_USAGE);
  return 0;
}

static int print_ocsp_summary(BIO *out, OCSP_BASICRESP *bs, OCSP_REQUEST *req,
                              STACK_OF(OPENSSL_STRING) * names,
                              STACK_OF(OCSP_CERTID) * ids, long nsec,
                              long maxage) {
  OCSP_CERTID *id;
  char *name;
  int i;

  int status, reason;

  ASN1_GENERALIZEDTIME *rev, *thisupd, *nextupd;

  if (!bs || !req || !sk_OPENSSL_STRING_num(names) || !sk_OCSP_CERTID_num(ids))
    return 1;

  for (i = 0; i < sk_OCSP_CERTID_num(ids); i++) {
    id = sk_OCSP_CERTID_value(ids, i);
    name = sk_OPENSSL_STRING_value(names, i);
    BIO_printf(out, "%s: ", name);

    if (!OCSP_resp_find_status(bs, id, &status, &reason, &rev, &thisupd,
                               &nextupd)) {
      BIO_puts(out, "ERROR: No Status found.\n");
      continue;
    }

    /* Check validity: if invalid write to output BIO so we
     * know which response this refers to.
     */
    if (!OCSP_check_validity(thisupd, nextupd, nsec, maxage)) {
      BIO_puts(out, "WARNING: Status times invalid.\n");
      ERR_print_errors(out);
    }
    BIO_printf(out, "%s\n", OCSP_cert_status_str(status));

    BIO_puts(out, "\tThis Update: ");
    ASN1_GENERALIZEDTIME_print(out, thisupd);
    BIO_puts(out, "\n");

    if (nextupd) {
      BIO_puts(out, "\tNext Update: ");
      ASN1_GENERALIZEDTIME_print(out, nextupd);
      BIO_puts(out, "\n");
    }

    if (status != V_OCSP_CERTSTATUS_REVOKED)
      continue;

    if (reason != -1)
      BIO_printf(out, "\tReason: %s\n", OCSP_crl_reason_str(reason));

    BIO_puts(out, "\tRevocation Time: ");
    ASN1_GENERALIZEDTIME_print(out, rev);
    BIO_puts(out, "\n");
  }

  return 1;
}
@end
