/*
* Tables for Turing
* (C) 1999-2007 Jack Lloyd
*
* Distributed under the terms of the Botan license
*/

#include "../botan/turing.h"

namespace Botan {

const byte Turing::SBOX[256] = {
   0x61, 0x51, 0xEB, 0x19, 0xB9, 0x5D, 0x60, 0x38, 0x7C, 0xB2, 0x06, 0x12,
   0xC4, 0x5B, 0x16, 0x3B, 0x2B, 0x18, 0x83, 0xB0, 0x7F, 0x75, 0xFA, 0xA0,
   0xE9, 0xDD, 0x6D, 0x7A, 0x6B, 0x68, 0x2D, 0x49, 0xB5, 0x1C, 0x90, 0xF7,
   0xED, 0x9F, 0xE8, 0xCE, 0xAE, 0x77, 0xC2, 0x13, 0xFD, 0xCD, 0x3E, 0xCF,
   0x37, 0x6A, 0xD4, 0xDB, 0x8E, 0x65, 0x1F, 0x1A, 0x87, 0xCB, 0x40, 0x15,
   0x88, 0x0D, 0x35, 0xB3, 0x11, 0x0F, 0xD0, 0x30, 0x48, 0xF9, 0xA8, 0xAC,
   0x85, 0x27, 0x0E, 0x8A, 0xE0, 0x50, 0x64, 0xA7, 0xCC, 0xE4, 0xF1, 0x98,
   0xFF, 0xA1, 0x04, 0xDA, 0xD5, 0xBC, 0x1B, 0xBB, 0xD1, 0xFE, 0x31, 0xCA,
   0xBA, 0xD9, 0x2E, 0xF3, 0x1D, 0x47, 0x4A, 0x3D, 0x71, 0x4C, 0xAB, 0x7D,
   0x8D, 0xC7, 0x59, 0xB8, 0xC1, 0x96, 0x1E, 0xFC, 0x44, 0xC8, 0x7B, 0xDC,
   0x5C, 0x78, 0x2A, 0x9D, 0xA5, 0xF0, 0x73, 0x22, 0x89, 0x05, 0xF4, 0x07,
   0x21, 0x52, 0xA6, 0x28, 0x9A, 0x92, 0x69, 0x8F, 0xC5, 0xC3, 0xF5, 0xE1,
   0xDE, 0xEC, 0x09, 0xF2, 0xD3, 0xAF, 0x34, 0x23, 0xAA, 0xDF, 0x7E, 0x82,
   0x29, 0xC0, 0x24, 0x14, 0x03, 0x32, 0x4E, 0x39, 0x6F, 0xC6, 0xB1, 0x9B,
   0xEA, 0x72, 0x79, 0x41, 0xD8, 0x26, 0x6C, 0x5E, 0x2C, 0xB4, 0xA2, 0x53,
   0x57, 0xE2, 0x9C, 0x86, 0x54, 0x95, 0xB6, 0x80, 0x8C, 0x36, 0x67, 0xBD,
   0x08, 0x93, 0x2F, 0x99, 0x5A, 0xF8, 0x3A, 0xD7, 0x56, 0x84, 0xD2, 0x01,
   0xF6, 0x66, 0x4D, 0x55, 0x8B, 0x0C, 0x0B, 0x46, 0xB7, 0x3C, 0x45, 0x91,
   0xA4, 0xE3, 0x70, 0xD6, 0xFB, 0xE6, 0x10, 0xA9, 0xC9, 0x00, 0x9E, 0xE7,
   0x4F, 0x76, 0x25, 0x3F, 0x5F, 0xA3, 0x33, 0x20, 0x02, 0xEF, 0x62, 0x74,
   0xEE, 0x17, 0x81, 0x42, 0x58, 0x0A, 0x4B, 0x63, 0xE5, 0xBE, 0x6E, 0xAD,
   0xBF, 0x43, 0x94, 0x97 };

const u32bit Turing::Q_BOX[256] = {
   0x1FAA1887, 0x4E5E435C, 0x9165C042, 0x250E6EF4, 0x5957EE20, 0xD484FED3,
   0xA666C502, 0x7E54E8AE, 0xD12EE9D9, 0xFC1F38D4, 0x49829B5D, 0x1B5CDF3C,
   0x74864249, 0xDA2E3963, 0x28F4429F, 0xC8432C35, 0x4AF40325, 0x9FC0DD70,
   0xD8973DED, 0x1A02DC5E, 0xCD175B42, 0xF10012BF, 0x6694D78C, 0xACAAB26B,
   0x4EC11B9A, 0x3F168146, 0xC0EA8EC5, 0xB38AC28F, 0x1FED5C0F, 0xAAB4101C,
   0xEA2DB082, 0x470929E1, 0xE71843DE, 0x508299FC, 0xE72FBC4B, 0x2E3915DD,
   0x9FA803FA, 0x9546B2DE, 0x3C233342, 0x0FCEE7C3, 0x24D607EF, 0x8F97EBAB,
   0xF37F859B, 0xCD1F2E2F, 0xC25B71DA, 0x75E2269A, 0x1E39C3D1, 0xEDA56B36,
   0xF8C9DEF2, 0x46C9FC5F, 0x1827B3A3, 0x70A56DDF, 0x0D25B510, 0x000F85A7,
   0xB2E82E71, 0x68CB8816, 0x8F951E2A, 0x72F5F6AF, 0xE4CBC2B3, 0xD34FF55D,
   0x2E6B6214, 0x220B83E3, 0xD39EA6F5, 0x6FE041AF, 0x6B2F1F17, 0xAD3B99EE,
   0x16A65EC0, 0x757016C6, 0xBA7709A4, 0xB0326E01, 0xF4B280D9, 0x4BFB1418,
   0xD6AFF227, 0xFD548203, 0xF56B9D96, 0x6717A8C0, 0x00D5BF6E, 0x10EE7888,
   0xEDFCFE64, 0x1BA193CD, 0x4B0D0184, 0x89AE4930, 0x1C014F36, 0x82A87088,
   0x5EAD6C2A, 0xEF22C678, 0x31204DE7, 0xC9C2E759, 0xD200248E, 0x303B446B,
   0xB00D9FC2, 0x9914A895, 0x906CC3A1, 0x54FEF170, 0x34C19155, 0xE27B8A66,
   0x131B5E69, 0xC3A8623E, 0x27BDFA35, 0x97F068CC, 0xCA3A6ACD, 0x4B55E936,
   0x86602DB9, 0x51DF13C1, 0x390BB16D, 0x5A80B83C, 0x22B23763, 0x39D8A911,
   0x2CB6BC13, 0xBF5579D7, 0x6C5C2FA8, 0xA8F4196E, 0xBCDB5476, 0x6864A866,
   0x416E16AD, 0x897FC515, 0x956FEB3C, 0xF6C8A306, 0x216799D9, 0x171A9133,
   0x6C2466DD, 0x75EB5DCD, 0xDF118F50, 0xE4AFB226, 0x26B9CEF3, 0xADB36189,
   0x8A7A19B1, 0xE2C73084, 0xF77DED5C, 0x8B8BC58F, 0x06DDE421, 0xB41E47FB,
   0xB1CC715E, 0x68C0FF99, 0x5D122F0F, 0xA4D25184, 0x097A5E6C, 0x0CBF18BC,
   0xC2D7C6E0, 0x8BB7E420, 0xA11F523F, 0x35D9B8A2, 0x03DA1A6B, 0x06888C02,
   0x7DD1E354, 0x6BBA7D79, 0x32CC7753, 0xE52D9655, 0xA9829DA1, 0x301590A7,
   0x9BC1C149, 0x13537F1C, 0xD3779B69, 0x2D71F2B7, 0x183C58FA, 0xACDC4418,
   0x8D8C8C76, 0x2620D9F0, 0x71A80D4D, 0x7A74C473, 0x449410E9, 0xA20E4211,
   0xF9C8082B, 0x0A6B334A, 0xB5F68ED2, 0x8243CC1B, 0x453C0FF3, 0x9BE564A0,
   0x4FF55A4F, 0x8740F8E7, 0xCCA7F15F, 0xE300FE21, 0x786D37D6, 0xDFD506F1,
   0x8EE00973, 0x17BBDE36, 0x7A670FA8, 0x5C31AB9E, 0xD4DAB618, 0xCC1F52F5,
   0xE358EB4F, 0x19B9E343, 0x3A8D77DD, 0xCDB93DA6, 0x140FD52D, 0x395412F8,
   0x2BA63360, 0x37E53AD0, 0x80700F1C, 0x7624ED0B, 0x703DC1EC, 0xB7366795,
   0xD6549D15, 0x66CE46D7, 0xD17ABE76, 0xA448E0A0, 0x28F07C02, 0xC31249B7,
   0x6E9ED6BA, 0xEAA47F78, 0xBBCFFFBD, 0xC507CA84, 0xE965F4DA, 0x8E9F35DA,
   0x6AD2AA44, 0x577452AC, 0xB5D674A7, 0x5461A46A, 0x6763152A, 0x9C12B7AA,
   0x12615927, 0x7B4FB118, 0xC351758D, 0x7E81687B, 0x5F52F0B3, 0x2D4254ED,
   0xD4C77271, 0x0431ACAB, 0xBEF94AEC, 0xFEE994CD, 0x9C4D9E81, 0xED623730,
   0xCF8A21E8, 0x51917F0B, 0xA7A9B5D6, 0xB297ADF8, 0xEED30431, 0x68CAC921,
   0xF1B35D46, 0x7A430A36, 0x51194022, 0x9ABCA65E, 0x85EC70BA, 0x39AEA8CC,
   0x737BAE8B, 0x582924D5, 0x03098A5A, 0x92396B81, 0x18DE2522, 0x745C1CB8,
   0xA1B8FE1D, 0x5DB3C697, 0x29164F83, 0x97C16376, 0x8419224C, 0x21203B35,
   0x833AC0FE, 0xD966A19A, 0xAAF0B24F, 0x40FDA998, 0xE7D52D71, 0x390896A8,
   0xCEE6053F, 0xD0B0D300, 0xFF99CBCC, 0x065E3D40 };

}
