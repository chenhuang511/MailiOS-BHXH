/*
 * X.509 Certificate Options
 * (C) 1999-2007 Jack Lloyd
 *
 * Distributed under the terms of the Botan license
 */

#include "../botan/x509self.h"
#include "../botan/oids.h"
#include "../botan/parsing.h"
#include "../botan/time.h"

//#include <android/log.h>
//#define  LOG_TAG    "x509opt.cpp"
//#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)

namespace Botan {

/*
 * Set when the certificate should become valid
 */
void X509_Cert_Options::not_before(const std::string& time_string) {
	start = X509_Time(time_string);
}

/*
 * Set when the certificate should expire
 */
void X509_Cert_Options::not_after(const std::string& time_string) {
	end = X509_Time(time_string);
}

/*
 * Set key constraint information
 */
void X509_Cert_Options::add_constraints(Key_Constraints usage) {
	constraints = usage;
}

/*
 * Set key constraint information
 */
void X509_Cert_Options::add_ex_constraint(const OID& oid) {
	ex_constraints.push_back(oid);
}

/*
 * Set key constraint information
 */
void X509_Cert_Options::add_ex_constraint(const std::string& oid_str) {
	ex_constraints.push_back(OIDS::lookup(oid_str));
}

/*
 * Mark this certificate for CA usage
 */
void X509_Cert_Options::CA_key(size_t limit) {
	is_CA = true;
	path_limit = limit;
}

/*
 * Do basic sanity checks
 */
void X509_Cert_Options::sanity_check() const {
	if (common_name == "" || country == "") {
//		LOGI("Name hoac Country null");
    }
	if (country.size() != 2) {
    }
//		LOGI("country nhieu hon 2 ky tu");
//	if (start >= end)
//		LOGI("?????");
}

/*
 * Initialize the certificate options
 */
X509_Cert_Options::X509_Cert_Options(const std::string& initial_opts,
		u32bit expiration_time_in_seconds) {
	is_CA = false;
	path_limit = 0;
	constraints = NO_CONSTRAINTS;

	const u64bit now = system_time();

	start = X509_Time(now);
	end = X509_Time(now + expiration_time_in_seconds);

	if (initial_opts == "")
		return;

	std::vector<std::string> parsed = split_on(initial_opts, '/');

	if (parsed.size() > 4)
		throw Invalid_Argument("X.509 cert options: Too many names: "
				+ initial_opts);

	if (parsed.size() >= 1)
		common_name = parsed[0];
	if (parsed.size() >= 2)
		country = parsed[1];
	if (parsed.size() >= 3)
		organization = parsed[2];
	if (parsed.size() == 4)
		org_unit = parsed[3];
}

}
