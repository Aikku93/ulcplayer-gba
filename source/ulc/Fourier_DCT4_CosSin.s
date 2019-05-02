/**************************************/
.section .rodata
.balign 4
/**************************************/

@ Table[{Cos[(n+0.5)*Pi/2 / N], Sin[(n+0.5)*Pi/2 / N]}, {n,0,N/2-1}]
@ Could probably use an oscillator, but already out of registers :/

Fourier_DCT4_CosSin:
	.hword 0x7FD9,0x0648,0x7E9D,0x12C8,0x7C2A,0x1F1A,0x7885,0x2B1F,0x73B6,0x36BA,0x6DCA,0x41CE,0x66D0,0x4C40,0x5ED7,0x55F6 @ N=16
	.hword 0x7FF6,0x0324,0x7FA7,0x096B,0x7F0A,0x0FAB,0x7E1E,0x15E2,0x7CE4,0x1C0C,0x7B5D,0x2224,0x798A,0x2827,0x776C,0x2E11 @ N=32
	.hword 0x7505,0x33DF,0x7255,0x398D,0x6F5F,0x3F17,0x6C24,0x447B,0x68A7,0x49B4,0x64E9,0x4EC0,0x60EC,0x539B,0x5CB4,0x5843
	.hword 0x7FFE,0x0192,0x7FEA,0x04B6,0x7FC2,0x07D9,0x7F87,0x0AFB,0x7F38,0x0E1C,0x7ED6,0x113A,0x7E60,0x1455,0x7DD6,0x176E @ N=64
	.hword 0x7D3A,0x1A83,0x7C89,0x1D93,0x7BC6,0x209F,0x7AEF,0x23A7,0x7A06,0x26A8,0x790A,0x29A4,0x77FB,0x2C99,0x76D9,0x2F87
	.hword 0x75A6,0x326E,0x7460,0x354E,0x7308,0x3825,0x719E,0x3AF3,0x7023,0x3DB8,0x6E97,0x4074,0x6CF9,0x4326,0x6B4B,0x45CD
	.hword 0x698C,0x486A,0x67BD,0x4AFB,0x65DE,0x4D81,0x63EF,0x4FFB,0x61F1,0x5269,0x5FE4,0x54CA,0x5DC8,0x571E,0x5B9D,0x5964
	.hword 0x7FFF,0x00C9,0x7FFA,0x025B,0x7FF1,0x03ED,0x7FE2,0x057F,0x7FCE,0x0711,0x7FB5,0x08A2,0x7F98,0x0A33,0x7F75,0x0BC4 @ N=128
	.hword 0x7F4E,0x0D54,0x7F22,0x0EE4,0x7EF0,0x1073,0x7EBA,0x1201,0x7E7F,0x138F,0x7E3F,0x151C,0x7DFB,0x16A8,0x7DB1,0x1833
	.hword 0x7D63,0x19BE,0x7D0F,0x1B47,0x7CB7,0x1CD0,0x7C5A,0x1E57,0x7BF9,0x1FDD,0x7B92,0x2162,0x7B27,0x22E5,0x7AB7,0x2467
	.hword 0x7A42,0x25E8,0x79C9,0x2768,0x794A,0x28E5,0x78C8,0x2A62,0x7840,0x2BDC,0x77B4,0x2D55,0x7723,0x2ECC,0x768E,0x3042
	.hword 0x75F4,0x31B5,0x7556,0x3327,0x74B3,0x3497,0x740B,0x3604,0x735F,0x3770,0x72AF,0x38D9,0x71FA,0x3A40,0x7141,0x3BA5
	.hword 0x7083,0x3D08,0x6FC2,0x3E68,0x6EFB,0x3FC6,0x6E31,0x4121,0x6D62,0x427A,0x6C8F,0x43D1,0x6BB8,0x4524,0x6ADD,0x4675
	.hword 0x69FD,0x47C4,0x691A,0x490F,0x6832,0x4A58,0x6747,0x4B9E,0x6657,0x4CE1,0x6564,0x4E21,0x646C,0x4F5E,0x6371,0x5098
	.hword 0x6272,0x51CF,0x616F,0x5303,0x6068,0x5433,0x5F5E,0x5560,0x5E50,0x568A,0x5D3E,0x57B1,0x5C29,0x58D4,0x5B10,0x59F4
	.hword 0x8000,0x0065,0x7FFF,0x012E,0x7FFC,0x01F7,0x7FF8,0x02C0,0x7FF4,0x0389,0x7FED,0x0452,0x7FE6,0x051B,0x7FDD,0x05E3 @ N=256
	.hword 0x7FD3,0x06AC,0x7FC8,0x0775,0x7FBC,0x083E,0x7FAE,0x0906,0x7FA0,0x09CF,0x7F90,0x0A97,0x7F7E,0x0B60,0x7F6C,0x0C28
	.hword 0x7F58,0x0CF0,0x7F43,0x0DB8,0x7F2D,0x0E80,0x7F16,0x0F47,0x7EFD,0x100F,0x7EE3,0x10D6,0x7EC8,0x119E,0x7EAC,0x1265
	.hword 0x7E8E,0x132B,0x7E70,0x13F2,0x7E50,0x14B9,0x7E2F,0x157F,0x7E0C,0x1645,0x7DE9,0x170B,0x7DC4,0x17D1,0x7D9E,0x1896
	.hword 0x7D77,0x195B,0x7D4E,0x1A20,0x7D25,0x1AE5,0x7CFA,0x1BA9,0x7CCE,0x1C6E,0x7CA0,0x1D31,0x7C72,0x1DF5,0x7C42,0x1EB8
	.hword 0x7C11,0x1F7B,0x7BDF,0x203E,0x7BAC,0x2101,0x7B78,0x21C3,0x7B42,0x2284,0x7B0B,0x2346,0x7AD3,0x2407,0x7A9A,0x24C8
	.hword 0x7A60,0x2588,0x7A24,0x2648,0x79E7,0x2708,0x79AA,0x27C7,0x796A,0x2886,0x792A,0x2945,0x78E9,0x2A03,0x78A6,0x2AC1
	.hword 0x7863,0x2B7E,0x781E,0x2C3B,0x77D8,0x2CF7,0x7790,0x2DB3,0x7748,0x2E6F,0x76FE,0x2F2A,0x76B4,0x2FE5,0x7668,0x309F
	.hword 0x761B,0x3159,0x75CD,0x3212,0x757E,0x32CB,0x752D,0x3383,0x74DC,0x343B,0x7489,0x34F2,0x7436,0x35A9,0x73E1,0x365F
	.hword 0x738B,0x3715,0x7334,0x37CA,0x72DC,0x387F,0x7282,0x3933,0x7228,0x39E7,0x71CC,0x3A9A,0x7170,0x3B4C,0x7112,0x3BFE
	.hword 0x70B3,0x3CAF,0x7053,0x3D60,0x6FF2,0x3E10,0x6F90,0x3EC0,0x6F2D,0x3F6F,0x6EC9,0x401D,0x6E64,0x40CB,0x6DFE,0x4178
	.hword 0x6D96,0x4224,0x6D2E,0x42D0,0x6CC4,0x437B,0x6C5A,0x4426,0x6BEE,0x44D0,0x6B82,0x4579,0x6B14,0x4621,0x6AA5,0x46C9
	.hword 0x6A36,0x4770,0x69C5,0x4817,0x6953,0x48BD,0x68E0,0x4962,0x686D,0x4A06,0x67F8,0x4AAA,0x6782,0x4B4D,0x670B,0x4BEF
	.hword 0x6693,0x4C91,0x661B,0x4D31,0x65A1,0x4DD1,0x6526,0x4E71,0x64AB,0x4F0F,0x642E,0x4FAD,0x63B0,0x504A,0x6332,0x50E6
	.hword 0x62B2,0x5181,0x6232,0x521C,0x61B0,0x52B6,0x612E,0x534F,0x60AA,0x53E7,0x6026,0x547F,0x5FA1,0x5515,0x5F1B,0x55AB
	.hword 0x5E94,0x5640,0x5E0C,0x56D4,0x5D83,0x5767,0x5CF9,0x57FA,0x5C6F,0x588C,0x5BE3,0x591C,0x5B57,0x59AC,0x5AC9,0x5A3B
	.hword 0x8000,0x0032,0x8000,0x0097,0x7FFF,0x00FB,0x7FFE,0x0160,0x7FFD,0x01C4,0x7FFB,0x0229,0x7FF9,0x028D,0x7FF7,0x02F2 @ N=512
	.hword 0x7FF5,0x0356,0x7FF2,0x03BB,0x7FEF,0x041F,0x7FEC,0x0484,0x7FE8,0x04E8,0x7FE4,0x054D,0x7FE0,0x05B1,0x7FDB,0x0616
	.hword 0x7FD6,0x067A,0x7FD1,0x06DE,0x7FCB,0x0743,0x7FC5,0x07A7,0x7FBF,0x080C,0x7FB9,0x0870,0x7FB2,0x08D4,0x7FAB,0x0938
	.hword 0x7FA3,0x099D,0x7F9C,0x0A01,0x7F94,0x0A65,0x7F8B,0x0AC9,0x7F83,0x0B2D,0x7F7A,0x0B92,0x7F71,0x0BF6,0x7F67,0x0C5A
	.hword 0x7F5D,0x0CBE,0x7F53,0x0D22,0x7F49,0x0D86,0x7F3E,0x0DEA,0x7F33,0x0E4E,0x7F27,0x0EB2,0x7F1C,0x0F15,0x7F10,0x0F79
	.hword 0x7F03,0x0FDD,0x7EF7,0x1041,0x7EEA,0x10A4,0x7EDD,0x1108,0x7ECF,0x116C,0x7EC1,0x11CF,0x7EB3,0x1233,0x7EA5,0x1296
	.hword 0x7E96,0x12FA,0x7E87,0x135D,0x7E78,0x13C1,0x7E68,0x1424,0x7E58,0x1487,0x7E48,0x14EA,0x7E37,0x154D,0x7E26,0x15B1
	.hword 0x7E15,0x1614,0x7E03,0x1677,0x7DF2,0x16DA,0x7DE0,0x173C,0x7DCD,0x179F,0x7DBA,0x1802,0x7DA7,0x1865,0x7D94,0x18C7
	.hword 0x7D81,0x192A,0x7D6D,0x198D,0x7D58,0x19EF,0x7D44,0x1A51,0x7D2F,0x1AB4,0x7D1A,0x1B16,0x7D05,0x1B78,0x7CEF,0x1BDA
	.hword 0x7CD9,0x1C3D,0x7CC2,0x1C9F,0x7CAC,0x1D01,0x7C95,0x1D62,0x7C7E,0x1DC4,0x7C66,0x1E26,0x7C4E,0x1E88,0x7C36,0x1EE9
	.hword 0x7C1E,0x1F4B,0x7C05,0x1FAC,0x7BEC,0x200E,0x7BD3,0x206F,0x7BB9,0x20D0,0x7B9F,0x2131,0x7B85,0x2192,0x7B6A,0x21F3
	.hword 0x7B50,0x2254,0x7B34,0x22B5,0x7B19,0x2316,0x7AFD,0x2376,0x7AE1,0x23D7,0x7AC5,0x2437,0x7AA8,0x2498,0x7A8C,0x24F8
	.hword 0x7A6E,0x2558,0x7A51,0x25B8,0x7A33,0x2618,0x7A15,0x2678,0x79F7,0x26D8,0x79D8,0x2738,0x79B9,0x2797,0x799A,0x27F7
	.hword 0x797A,0x2856,0x795B,0x28B6,0x793A,0x2915,0x791A,0x2974,0x78F9,0x29D3,0x78D8,0x2A32,0x78B7,0x2A91,0x7895,0x2AF0
	.hword 0x7874,0x2B4F,0x7851,0x2BAD,0x782F,0x2C0C,0x780C,0x2C6A,0x77E9,0x2CC8,0x77C6,0x2D26,0x77A2,0x2D84,0x777E,0x2DE2
	.hword 0x775A,0x2E40,0x7736,0x2E9E,0x7711,0x2EFB,0x76EC,0x2F59,0x76C7,0x2FB6,0x76A1,0x3013,0x767B,0x3070,0x7655,0x30CD
	.hword 0x762E,0x312A,0x7608,0x3187,0x75E1,0x31E4,0x75B9,0x3240,0x7592,0x329D,0x756A,0x32F9,0x7542,0x3355,0x7519,0x33B1
	.hword 0x74F0,0x340D,0x74C7,0x3469,0x749E,0x34C4,0x7475,0x3520,0x744B,0x357B,0x7421,0x35D7,0x73F6,0x3632,0x73CB,0x368D
	.hword 0x73A0,0x36E8,0x7375,0x3742,0x734A,0x379D,0x731E,0x37F7,0x72F2,0x3852,0x72C5,0x38AC,0x7299,0x3906,0x726C,0x3960
	.hword 0x723F,0x39BA,0x7211,0x3A13,0x71E3,0x3A6D,0x71B5,0x3AC6,0x7187,0x3B20,0x7158,0x3B79,0x712A,0x3BD2,0x70FA,0x3C2A
	.hword 0x70CB,0x3C83,0x709B,0x3CDC,0x706B,0x3D34,0x703B,0x3D8C,0x700B,0x3DE4,0x6FDA,0x3E3C,0x6FA9,0x3E94,0x6F78,0x3EEC
	.hword 0x6F46,0x3F43,0x6F14,0x3F9A,0x6EE2,0x3FF1,0x6EB0,0x4048,0x6E7D,0x409F,0x6E4A,0x40F6,0x6E17,0x414D,0x6DE4,0x41A3
	.hword 0x6DB0,0x41F9,0x6D7C,0x424F,0x6D48,0x42A5,0x6D14,0x42FB,0x6CDF,0x4351,0x6CAA,0x43A6,0x6C75,0x43FB,0x6C3F,0x4450
	.hword 0x6C09,0x44A5,0x6BD3,0x44FA,0x6B9D,0x454F,0x6B66,0x45A3,0x6B30,0x45F7,0x6AF8,0x464B,0x6AC1,0x469F,0x6A89,0x46F3
	.hword 0x6A52,0x4747,0x6A1A,0x479A,0x69E1,0x47ED,0x69A9,0x4840,0x6970,0x4893,0x6937,0x48E6,0x68FD,0x4939,0x68C4,0x498B
	.hword 0x688A,0x49DD,0x6850,0x4A2F,0x6815,0x4A81,0x67DA,0x4AD3,0x67A0,0x4B24,0x6764,0x4B75,0x6729,0x4BC7,0x66ED,0x4C17
	.hword 0x66B2,0x4C68,0x6675,0x4CB9,0x6639,0x4D09,0x65FC,0x4D59,0x65C0,0x4DA9,0x6582,0x4DF9,0x6545,0x4E49,0x6507,0x4E98
	.hword 0x64CA,0x4EE8,0x648B,0x4F37,0x644D,0x4F85,0x640F,0x4FD4,0x63D0,0x5023,0x6391,0x5071,0x6351,0x50BF,0x6312,0x510D
	.hword 0x62D2,0x515B,0x6292,0x51A8,0x6252,0x51F5,0x6211,0x5243,0x61D1,0x5290,0x6190,0x52DC,0x614E,0x5329,0x610D,0x5375
	.hword 0x60CB,0x53C1,0x6089,0x540D,0x6047,0x5459,0x6005,0x54A4,0x5FC2,0x54F0,0x5F80,0x553B,0x5F3C,0x5586,0x5EF9,0x55D0
	.hword 0x5EB6,0x561B,0x5E72,0x5665,0x5E2E,0x56AF,0x5DEA,0x56F9,0x5DA5,0x5743,0x5D61,0x578C,0x5D1C,0x57D5,0x5CD7,0x581E
	.hword 0x5C91,0x5867,0x5C4C,0x58B0,0x5C06,0x58F8,0x5BC0,0x5940,0x5B7A,0x5988,0x5B34,0x59D0,0x5AED,0x5A18,0x5AA6,0x5A5F
	.hword 0x8000,0x0019,0x8000,0x004B,0x8000,0x007E,0x8000,0x00B0,0x7FFF,0x00E2,0x7FFF,0x0114,0x7FFE,0x0147,0x7FFE,0x0179 @ N=1024
	.hword 0x7FFD,0x01AB,0x7FFD,0x01DE,0x7FFC,0x0210,0x7FFB,0x0242,0x7FFA,0x0274,0x7FF9,0x02A7,0x7FF8,0x02D9,0x7FF7,0x030B
	.hword 0x7FF6,0x033D,0x7FF4,0x0370,0x7FF3,0x03A2,0x7FF1,0x03D4,0x7FF0,0x0406,0x7FEE,0x0439,0x7FEC,0x046B,0x7FEB,0x049D
	.hword 0x7FE9,0x04CF,0x7FE7,0x0501,0x7FE5,0x0534,0x7FE3,0x0566,0x7FE1,0x0598,0x7FDE,0x05CA,0x7FDC,0x05FD,0x7FDA,0x062F
	.hword 0x7FD7,0x0661,0x7FD5,0x0693,0x7FD2,0x06C5,0x7FCF,0x06F8,0x7FCD,0x072A,0x7FCA,0x075C,0x7FC7,0x078E,0x7FC4,0x07C0
	.hword 0x7FC1,0x07F2,0x7FBE,0x0825,0x7FBA,0x0857,0x7FB7,0x0889,0x7FB4,0x08BB,0x7FB0,0x08ED,0x7FAD,0x091F,0x7FA9,0x0951
	.hword 0x7FA5,0x0984,0x7FA2,0x09B6,0x7F9E,0x09E8,0x7F9A,0x0A1A,0x7F96,0x0A4C,0x7F92,0x0A7E,0x7F8E,0x0AB0,0x7F89,0x0AE2
	.hword 0x7F85,0x0B14,0x7F81,0x0B47,0x7F7C,0x0B79,0x7F78,0x0BAB,0x7F73,0x0BDD,0x7F6E,0x0C0F,0x7F6A,0x0C41,0x7F65,0x0C73
	.hword 0x7F60,0x0CA5,0x7F5B,0x0CD7,0x7F56,0x0D09,0x7F50,0x0D3B,0x7F4B,0x0D6D,0x7F46,0x0D9F,0x7F41,0x0DD1,0x7F3B,0x0E03
	.hword 0x7F36,0x0E35,0x7F30,0x0E67,0x7F2A,0x0E99,0x7F24,0x0ECB,0x7F1F,0x0EFC,0x7F19,0x0F2E,0x7F13,0x0F60,0x7F0D,0x0F92
	.hword 0x7F06,0x0FC4,0x7F00,0x0FF6,0x7EFA,0x1028,0x7EF4,0x105A,0x7EED,0x108C,0x7EE7,0x10BD,0x7EE0,0x10EF,0x7ED9,0x1121
	.hword 0x7ED3,0x1153,0x7ECC,0x1185,0x7EC5,0x11B6,0x7EBE,0x11E8,0x7EB7,0x121A,0x7EB0,0x124C,0x7EA8,0x127D,0x7EA1,0x12AF
	.hword 0x7E9A,0x12E1,0x7E92,0x1313,0x7E8B,0x1344,0x7E83,0x1376,0x7E7B,0x13A8,0x7E74,0x13D9,0x7E6C,0x140B,0x7E64,0x143D
	.hword 0x7E5C,0x146E,0x7E54,0x14A0,0x7E4C,0x14D1,0x7E43,0x1503,0x7E3B,0x1535,0x7E33,0x1566,0x7E2A,0x1598,0x7E22,0x15C9
	.hword 0x7E19,0x15FB,0x7E11,0x162C,0x7E08,0x165E,0x7DFF,0x168F,0x7DF6,0x16C1,0x7DED,0x16F2,0x7DE4,0x1724,0x7DDB,0x1755
	.hword 0x7DD2,0x1787,0x7DC9,0x17B8,0x7DBF,0x17E9,0x7DB6,0x181B,0x7DAC,0x184C,0x7DA3,0x187D,0x7D99,0x18AF,0x7D8F,0x18E0
	.hword 0x7D85,0x1911,0x7D7C,0x1943,0x7D72,0x1974,0x7D68,0x19A5,0x7D5D,0x19D6,0x7D53,0x1A08,0x7D49,0x1A39,0x7D3F,0x1A6A
	.hword 0x7D34,0x1A9B,0x7D2A,0x1ACC,0x7D1F,0x1AFE,0x7D15,0x1B2F,0x7D0A,0x1B60,0x7CFF,0x1B91,0x7CF4,0x1BC2,0x7CE9,0x1BF3
	.hword 0x7CDE,0x1C24,0x7CD3,0x1C55,0x7CC8,0x1C86,0x7CBD,0x1CB7,0x7CB1,0x1CE8,0x7CA6,0x1D19,0x7C9B,0x1D4A,0x7C8F,0x1D7B
	.hword 0x7C83,0x1DAC,0x7C78,0x1DDD,0x7C6C,0x1E0E,0x7C60,0x1E3E,0x7C54,0x1E6F,0x7C48,0x1EA0,0x7C3C,0x1ED1,0x7C30,0x1F02
	.hword 0x7C24,0x1F32,0x7C18,0x1F63,0x7C0B,0x1F94,0x7BFF,0x1FC5,0x7BF2,0x1FF5,0x7BE6,0x2026,0x7BD9,0x2057,0x7BCC,0x2087
	.hword 0x7BBF,0x20B8,0x7BB3,0x20E8,0x7BA6,0x2119,0x7B99,0x2149,0x7B8B,0x217A,0x7B7E,0x21AA,0x7B71,0x21DB,0x7B64,0x220B
	.hword 0x7B56,0x223C,0x7B49,0x226C,0x7B3B,0x229D,0x7B2E,0x22CD,0x7B20,0x22FD,0x7B12,0x232E,0x7B04,0x235E,0x7AF6,0x238E
	.hword 0x7AE8,0x23BF,0x7ADA,0x23EF,0x7ACC,0x241F,0x7ABE,0x244F,0x7AB0,0x2480,0x7AA1,0x24B0,0x7A93,0x24E0,0x7A84,0x2510
	.hword 0x7A76,0x2540,0x7A67,0x2570,0x7A58,0x25A0,0x7A49,0x25D0,0x7A3B,0x2600,0x7A2C,0x2630,0x7A1D,0x2660,0x7A0E,0x2690
	.hword 0x79FE,0x26C0,0x79EF,0x26F0,0x79E0,0x2720,0x79D0,0x2750,0x79C1,0x2780,0x79B1,0x27AF,0x79A2,0x27DF,0x7992,0x280F
	.hword 0x7982,0x283F,0x7972,0x286E,0x7962,0x289E,0x7953,0x28CE,0x7942,0x28FD,0x7932,0x292D,0x7922,0x295C,0x7912,0x298C
	.hword 0x7901,0x29BC,0x78F1,0x29EB,0x78E1,0x2A1B,0x78D0,0x2A4A,0x78BF,0x2A79,0x78AF,0x2AA9,0x789E,0x2AD8,0x788D,0x2B08
	.hword 0x787C,0x2B37,0x786B,0x2B66,0x785A,0x2B95,0x7849,0x2BC5,0x7838,0x2BF4,0x7826,0x2C23,0x7815,0x2C52,0x7803,0x2C81
	.hword 0x77F2,0x2CB1,0x77E0,0x2CE0,0x77CF,0x2D0F,0x77BD,0x2D3E,0x77AB,0x2D6D,0x7799,0x2D9C,0x7787,0x2DCB,0x7775,0x2DFA
	.hword 0x7763,0x2E28,0x7751,0x2E57,0x773F,0x2E86,0x772D,0x2EB5,0x771A,0x2EE4,0x7708,0x2F13,0x76F5,0x2F41,0x76E3,0x2F70
	.hword 0x76D0,0x2F9F,0x76BD,0x2FCD,0x76AA,0x2FFC,0x7698,0x302A,0x7685,0x3059,0x7672,0x3088,0x765E,0x30B6,0x764B,0x30E5
	.hword 0x7638,0x3113,0x7625,0x3141,0x7611,0x3170,0x75FE,0x319E,0x75EA,0x31CC,0x75D7,0x31FB,0x75C3,0x3229,0x75AF,0x3257
	.hword 0x759C,0x3285,0x7588,0x32B4,0x7574,0x32E2,0x7560,0x3310,0x754C,0x333E,0x7538,0x336C,0x7523,0x339A,0x750F,0x33C8
	.hword 0x74FB,0x33F6,0x74E6,0x3424,0x74D2,0x3452,0x74BD,0x3480,0x74A8,0x34AD,0x7494,0x34DB,0x747F,0x3509,0x746A,0x3537
	.hword 0x7455,0x3564,0x7440,0x3592,0x742B,0x35C0,0x7416,0x35ED,0x7401,0x361B,0x73EB,0x3648,0x73D6,0x3676,0x73C1,0x36A3
	.hword 0x73AB,0x36D1,0x7396,0x36FE,0x7380,0x372C,0x736A,0x3759,0x7355,0x3786,0x733F,0x37B4,0x7329,0x37E1,0x7313,0x380E
	.hword 0x72FD,0x383B,0x72E7,0x3868,0x72D0,0x3895,0x72BA,0x38C2,0x72A4,0x38F0,0x728D,0x391D,0x7277,0x3949,0x7260,0x3976
	.hword 0x724A,0x39A3,0x7233,0x39D0,0x721C,0x39FD,0x7206,0x3A2A,0x71EF,0x3A57,0x71D8,0x3A83,0x71C1,0x3AB0,0x71AA,0x3ADD
	.hword 0x7193,0x3B09,0x717B,0x3B36,0x7164,0x3B62,0x714D,0x3B8F,0x7135,0x3BBB,0x711E,0x3BE8,0x7106,0x3C14,0x70EF,0x3C41
	.hword 0x70D7,0x3C6D,0x70BF,0x3C99,0x70A7,0x3CC5,0x708F,0x3CF2,0x7077,0x3D1E,0x705F,0x3D4A,0x7047,0x3D76,0x702F,0x3DA2
	.hword 0x7017,0x3DCE,0x6FFF,0x3DFA,0x6FE6,0x3E26,0x6FCE,0x3E52,0x6FB5,0x3E7E,0x6F9D,0x3EAA,0x6F84,0x3ED6,0x6F6B,0x3F01
	.hword 0x6F53,0x3F2D,0x6F3A,0x3F59,0x6F21,0x3F85,0x6F08,0x3FB0,0x6EEF,0x3FDC,0x6ED6,0x4007,0x6EBD,0x4033,0x6EA3,0x405E
	.hword 0x6E8A,0x408A,0x6E71,0x40B5,0x6E57,0x40E0,0x6E3E,0x410C,0x6E24,0x4137,0x6E0A,0x4162,0x6DF1,0x418D,0x6DD7,0x41B9
	.hword 0x6DBD,0x41E4,0x6DA3,0x420F,0x6D89,0x423A,0x6D6F,0x4265,0x6D55,0x4290,0x6D3B,0x42BB,0x6D21,0x42E6,0x6D06,0x4310
	.hword 0x6CEC,0x433B,0x6CD2,0x4366,0x6CB7,0x4391,0x6C9D,0x43BB,0x6C82,0x43E6,0x6C67,0x4411,0x6C4C,0x443B,0x6C32,0x4466
	.hword 0x6C17,0x4490,0x6BFC,0x44BA,0x6BE1,0x44E5,0x6BC6,0x450F,0x6BAA,0x4539,0x6B8F,0x4564,0x6B74,0x458E,0x6B59,0x45B8
	.hword 0x6B3D,0x45E2,0x6B22,0x460C,0x6B06,0x4636,0x6AEB,0x4660,0x6ACF,0x468A,0x6AB3,0x46B4,0x6A97,0x46DE,0x6A7C,0x4708
	.hword 0x6A60,0x4732,0x6A44,0x475C,0x6A28,0x4785,0x6A0B,0x47AF,0x69EF,0x47D9,0x69D3,0x4802,0x69B7,0x482C,0x699A,0x4855
	.hword 0x697E,0x487F,0x6961,0x48A8,0x6945,0x48D1,0x6928,0x48FB,0x690C,0x4924,0x68EF,0x494D,0x68D2,0x4976,0x68B5,0x49A0
	.hword 0x6898,0x49C9,0x687B,0x49F2,0x685E,0x4A1B,0x6841,0x4A44,0x6824,0x4A6D,0x6806,0x4A95,0x67E9,0x4ABE,0x67CC,0x4AE7
	.hword 0x67AE,0x4B10,0x6791,0x4B38,0x6773,0x4B61,0x6756,0x4B8A,0x6738,0x4BB2,0x671A,0x4BDB,0x66FC,0x4C03,0x66DE,0x4C2C
	.hword 0x66C1,0x4C54,0x66A3,0x4C7C,0x6684,0x4CA5,0x6666,0x4CCD,0x6648,0x4CF5,0x662A,0x4D1D,0x660C,0x4D45,0x65ED,0x4D6D
	.hword 0x65CF,0x4D95,0x65B0,0x4DBD,0x6592,0x4DE5,0x6573,0x4E0D,0x6554,0x4E35,0x6536,0x4E5D,0x6517,0x4E84,0x64F8,0x4EAC
	.hword 0x64D9,0x4ED4,0x64BA,0x4EFB,0x649B,0x4F23,0x647C,0x4F4A,0x645D,0x4F72,0x643E,0x4F99,0x641E,0x4FC0,0x63FF,0x4FE8
	.hword 0x63DF,0x500F,0x63C0,0x5036,0x63A0,0x505D,0x6381,0x5084,0x6361,0x50AC,0x6342,0x50D3,0x6322,0x50F9,0x6302,0x5120
	.hword 0x62E2,0x5147,0x62C2,0x516E,0x62A2,0x5195,0x6282,0x51BB,0x6262,0x51E2,0x6242,0x5209,0x6221,0x522F,0x6201,0x5256
	.hword 0x61E1,0x527C,0x61C0,0x52A3,0x61A0,0x52C9,0x617F,0x52EF,0x615F,0x5316,0x613E,0x533C,0x611D,0x5362,0x60FD,0x5388
	.hword 0x60DC,0x53AE,0x60BB,0x53D4,0x609A,0x53FA,0x6079,0x5420,0x6058,0x5446,0x6037,0x546C,0x6016,0x5491,0x5FF4,0x54B7
	.hword 0x5FD3,0x54DD,0x5FB2,0x5502,0x5F90,0x5528,0x5F6F,0x554E,0x5F4D,0x5573,0x5F2C,0x5598,0x5F0A,0x55BE,0x5EE8,0x55E3
	.hword 0x5EC7,0x5608,0x5EA5,0x562D,0x5E83,0x5653,0x5E61,0x5678,0x5E3F,0x569D,0x5E1D,0x56C2,0x5DFB,0x56E7,0x5DD9,0x570C
	.hword 0x5DB7,0x5730,0x5D94,0x5755,0x5D72,0x577A,0x5D50,0x579F,0x5D2D,0x57C3,0x5D0B,0x57E8,0x5CE8,0x580C,0x5CC5,0x5831
	.hword 0x5CA3,0x5855,0x5C80,0x5879,0x5C5D,0x589E,0x5C3A,0x58C2,0x5C18,0x58E6,0x5BF5,0x590A,0x5BD2,0x592E,0x5BAF,0x5952
	.hword 0x5B8C,0x5976,0x5B68,0x599A,0x5B45,0x59BE,0x5B22,0x59E2,0x5AFF,0x5A06,0x5ADB,0x5A29,0x5AB8,0x5A4D,0x5A94,0x5A71
	.hword 0x8000,0x000D,0x8000,0x0026,0x8000,0x003F,0x8000,0x0058,0x8000,0x0071,0x8000,0x008A,0x8000,0x00A3,0x7FFF,0x00BC @ N=2048
	.hword 0x7FFF,0x00D6,0x7FFF,0x00EF,0x7FFF,0x0108,0x7FFF,0x0121,0x7FFE,0x013A,0x7FFE,0x0153,0x7FFE,0x016C,0x7FFE,0x0186
	.hword 0x7FFD,0x019F,0x7FFD,0x01B8,0x7FFD,0x01D1,0x7FFC,0x01EA,0x7FFC,0x0203,0x7FFC,0x021C,0x7FFB,0x0235,0x7FFB,0x024F
	.hword 0x7FFA,0x0268,0x7FFA,0x0281,0x7FF9,0x029A,0x7FF9,0x02B3,0x7FF8,0x02CC,0x7FF8,0x02E5,0x7FF7,0x02FE,0x7FF6,0x0318
	.hword 0x7FF6,0x0331,0x7FF5,0x034A,0x7FF5,0x0363,0x7FF4,0x037C,0x7FF3,0x0395,0x7FF2,0x03AE,0x7FF2,0x03C7,0x7FF1,0x03E1
	.hword 0x7FF0,0x03FA,0x7FEF,0x0413,0x7FEF,0x042C,0x7FEE,0x0445,0x7FED,0x045E,0x7FEC,0x0477,0x7FEB,0x0490,0x7FEA,0x04AA
	.hword 0x7FE9,0x04C3,0x7FE8,0x04DC,0x7FE7,0x04F5,0x7FE6,0x050E,0x7FE5,0x0527,0x7FE4,0x0540,0x7FE3,0x0559,0x7FE2,0x0572
	.hword 0x7FE1,0x058C,0x7FE0,0x05A5,0x7FDF,0x05BE,0x7FDE,0x05D7,0x7FDD,0x05F0,0x7FDC,0x0609,0x7FDA,0x0622,0x7FD9,0x063B
	.hword 0x7FD8,0x0654,0x7FD7,0x066E,0x7FD5,0x0687,0x7FD4,0x06A0,0x7FD3,0x06B9,0x7FD1,0x06D2,0x7FD0,0x06EB,0x7FCF,0x0704
	.hword 0x7FCD,0x071D,0x7FCC,0x0736,0x7FCB,0x074F,0x7FC9,0x0768,0x7FC8,0x0782,0x7FC6,0x079B,0x7FC5,0x07B4,0x7FC3,0x07CD
	.hword 0x7FC2,0x07E6,0x7FC0,0x07FF,0x7FBE,0x0818,0x7FBD,0x0831,0x7FBB,0x084A,0x7FBA,0x0863,0x7FB8,0x087C,0x7FB6,0x0895
	.hword 0x7FB5,0x08AF,0x7FB3,0x08C8,0x7FB1,0x08E1,0x7FAF,0x08FA,0x7FAE,0x0913,0x7FAC,0x092C,0x7FAA,0x0945,0x7FA8,0x095E
	.hword 0x7FA6,0x0977,0x7FA4,0x0990,0x7FA3,0x09A9,0x7FA1,0x09C2,0x7F9F,0x09DB,0x7F9D,0x09F4,0x7F9B,0x0A0D,0x7F99,0x0A27
	.hword 0x7F97,0x0A40,0x7F95,0x0A59,0x7F93,0x0A72,0x7F91,0x0A8B,0x7F8F,0x0AA4,0x7F8D,0x0ABD,0x7F8A,0x0AD6,0x7F88,0x0AEF
	.hword 0x7F86,0x0B08,0x7F84,0x0B21,0x7F82,0x0B3A,0x7F80,0x0B53,0x7F7D,0x0B6C,0x7F7B,0x0B85,0x7F79,0x0B9E,0x7F76,0x0BB7
	.hword 0x7F74,0x0BD0,0x7F72,0x0BE9,0x7F6F,0x0C02,0x7F6D,0x0C1B,0x7F6B,0x0C34,0x7F68,0x0C4D,0x7F66,0x0C66,0x7F63,0x0C7F
	.hword 0x7F61,0x0C98,0x7F5E,0x0CB1,0x7F5C,0x0CCA,0x7F59,0x0CE3,0x7F57,0x0CFC,0x7F54,0x0D15,0x7F52,0x0D2E,0x7F4F,0x0D47
	.hword 0x7F4D,0x0D60,0x7F4A,0x0D79,0x7F47,0x0D92,0x7F45,0x0DAB,0x7F42,0x0DC4,0x7F3F,0x0DDD,0x7F3C,0x0DF6,0x7F3A,0x0E0F
	.hword 0x7F37,0x0E28,0x7F34,0x0E41,0x7F31,0x0E5A,0x7F2F,0x0E73,0x7F2C,0x0E8C,0x7F29,0x0EA5,0x7F26,0x0EBE,0x7F23,0x0ED7
	.hword 0x7F20,0x0EF0,0x7F1D,0x0F09,0x7F1A,0x0F22,0x7F17,0x0F3B,0x7F14,0x0F54,0x7F11,0x0F6D,0x7F0E,0x0F86,0x7F0B,0x0F9F
	.hword 0x7F08,0x0FB8,0x7F05,0x0FD1,0x7F02,0x0FEA,0x7EFF,0x1002,0x7EFC,0x101B,0x7EF8,0x1034,0x7EF5,0x104D,0x7EF2,0x1066
	.hword 0x7EEF,0x107F,0x7EEB,0x1098,0x7EE8,0x10B1,0x7EE5,0x10CA,0x7EE2,0x10E3,0x7EDE,0x10FC,0x7EDB,0x1115,0x7ED8,0x112D
	.hword 0x7ED4,0x1146,0x7ED1,0x115F,0x7ECD,0x1178,0x7ECA,0x1191,0x7EC6,0x11AA,0x7EC3,0x11C3,0x7EC0,0x11DC,0x7EBC,0x11F5
	.hword 0x7EB8,0x120E,0x7EB5,0x1226,0x7EB1,0x123F,0x7EAE,0x1258,0x7EAA,0x1271,0x7EA6,0x128A,0x7EA3,0x12A3,0x7E9F,0x12BC
	.hword 0x7E9B,0x12D4,0x7E98,0x12ED,0x7E94,0x1306,0x7E90,0x131F,0x7E8D,0x1338,0x7E89,0x1351,0x7E85,0x136A,0x7E81,0x1382
	.hword 0x7E7D,0x139B,0x7E79,0x13B4,0x7E76,0x13CD,0x7E72,0x13E6,0x7E6E,0x13FF,0x7E6A,0x1417,0x7E66,0x1430,0x7E62,0x1449
	.hword 0x7E5E,0x1462,0x7E5A,0x147B,0x7E56,0x1493,0x7E52,0x14AC,0x7E4E,0x14C5,0x7E4A,0x14DE,0x7E46,0x14F7,0x7E41,0x150F
	.hword 0x7E3D,0x1528,0x7E39,0x1541,0x7E35,0x155A,0x7E31,0x1573,0x7E2D,0x158B,0x7E28,0x15A4,0x7E24,0x15BD,0x7E20,0x15D6
	.hword 0x7E1B,0x15EE,0x7E17,0x1607,0x7E13,0x1620,0x7E0E,0x1639,0x7E0A,0x1651,0x7E06,0x166A,0x7E01,0x1683,0x7DFD,0x169C
	.hword 0x7DF8,0x16B4,0x7DF4,0x16CD,0x7DEF,0x16E6,0x7DEB,0x16FF,0x7DE6,0x1717,0x7DE2,0x1730,0x7DDD,0x1749,0x7DD9,0x1761
	.hword 0x7DD4,0x177A,0x7DCF,0x1793,0x7DCB,0x17AC,0x7DC6,0x17C4,0x7DC2,0x17DD,0x7DBD,0x17F6,0x7DB8,0x180E,0x7DB3,0x1827
	.hword 0x7DAF,0x1840,0x7DAA,0x1858,0x7DA5,0x1871,0x7DA0,0x188A,0x7D9B,0x18A2,0x7D97,0x18BB,0x7D92,0x18D4,0x7D8D,0x18EC
	.hword 0x7D88,0x1905,0x7D83,0x191E,0x7D7E,0x1936,0x7D79,0x194F,0x7D74,0x1968,0x7D6F,0x1980,0x7D6A,0x1999,0x7D65,0x19B1
	.hword 0x7D60,0x19CA,0x7D5B,0x19E3,0x7D56,0x19FB,0x7D51,0x1A14,0x7D4C,0x1A2D,0x7D46,0x1A45,0x7D41,0x1A5E,0x7D3C,0x1A76
	.hword 0x7D37,0x1A8F,0x7D32,0x1AA8,0x7D2C,0x1AC0,0x7D27,0x1AD9,0x7D22,0x1AF1,0x7D1D,0x1B0A,0x7D17,0x1B22,0x7D12,0x1B3B
	.hword 0x7D0D,0x1B53,0x7D07,0x1B6C,0x7D02,0x1B85,0x7CFC,0x1B9D,0x7CF7,0x1BB6,0x7CF2,0x1BCE,0x7CEC,0x1BE7,0x7CE7,0x1BFF
	.hword 0x7CE1,0x1C18,0x7CDC,0x1C30,0x7CD6,0x1C49,0x7CD0,0x1C61,0x7CCB,0x1C7A,0x7CC5,0x1C92,0x7CC0,0x1CAB,0x7CBA,0x1CC3
	.hword 0x7CB4,0x1CDC,0x7CAF,0x1CF4,0x7CA9,0x1D0D,0x7CA3,0x1D25,0x7C9E,0x1D3E,0x7C98,0x1D56,0x7C92,0x1D6F,0x7C8C,0x1D87
	.hword 0x7C86,0x1DA0,0x7C81,0x1DB8,0x7C7B,0x1DD0,0x7C75,0x1DE9,0x7C6F,0x1E01,0x7C69,0x1E1A,0x7C63,0x1E32,0x7C5D,0x1E4B
	.hword 0x7C57,0x1E63,0x7C51,0x1E7B,0x7C4B,0x1E94,0x7C45,0x1EAC,0x7C3F,0x1EC5,0x7C39,0x1EDD,0x7C33,0x1EF5,0x7C2D,0x1F0E
	.hword 0x7C27,0x1F26,0x7C21,0x1F3F,0x7C1B,0x1F57,0x7C14,0x1F6F,0x7C0E,0x1F88,0x7C08,0x1FA0,0x7C02,0x1FB8,0x7BFC,0x1FD1
	.hword 0x7BF5,0x1FE9,0x7BEF,0x2001,0x7BE9,0x201A,0x7BE3,0x2032,0x7BDC,0x204A,0x7BD6,0x2063,0x7BCF,0x207B,0x7BC9,0x2093
	.hword 0x7BC3,0x20AC,0x7BBC,0x20C4,0x7BB6,0x20DC,0x7BAF,0x20F4,0x7BA9,0x210D,0x7BA2,0x2125,0x7B9C,0x213D,0x7B95,0x2156
	.hword 0x7B8F,0x216E,0x7B88,0x2186,0x7B82,0x219E,0x7B7B,0x21B7,0x7B74,0x21CF,0x7B6E,0x21E7,0x7B67,0x21FF,0x7B60,0x2218
	.hword 0x7B5A,0x2230,0x7B53,0x2248,0x7B4C,0x2260,0x7B45,0x2278,0x7B3F,0x2291,0x7B38,0x22A9,0x7B31,0x22C1,0x7B2A,0x22D9
	.hword 0x7B23,0x22F1,0x7B1C,0x230A,0x7B16,0x2322,0x7B0F,0x233A,0x7B08,0x2352,0x7B01,0x236A,0x7AFA,0x2382,0x7AF3,0x239A
	.hword 0x7AEC,0x23B3,0x7AE5,0x23CB,0x7ADE,0x23E3,0x7AD7,0x23FB,0x7AD0,0x2413,0x7AC9,0x242B,0x7AC1,0x2443,0x7ABA,0x245B
	.hword 0x7AB3,0x2474,0x7AAC,0x248C,0x7AA5,0x24A4,0x7A9E,0x24BC,0x7A96,0x24D4,0x7A8F,0x24EC,0x7A88,0x2504,0x7A81,0x251C
	.hword 0x7A79,0x2534,0x7A72,0x254C,0x7A6B,0x2564,0x7A63,0x257C,0x7A5C,0x2594,0x7A55,0x25AC,0x7A4D,0x25C4,0x7A46,0x25DC
	.hword 0x7A3E,0x25F4,0x7A37,0x260C,0x7A2F,0x2624,0x7A28,0x263C,0x7A20,0x2654,0x7A19,0x266C,0x7A11,0x2684,0x7A0A,0x269C
	.hword 0x7A02,0x26B4,0x79FB,0x26CC,0x79F3,0x26E4,0x79EB,0x26FC,0x79E4,0x2714,0x79DC,0x272C,0x79D4,0x2744,0x79CC,0x275C
	.hword 0x79C5,0x2774,0x79BD,0x278B,0x79B5,0x27A3,0x79AD,0x27BB,0x79A6,0x27D3,0x799E,0x27EB,0x7996,0x2803,0x798E,0x281B
	.hword 0x7986,0x2833,0x797E,0x284B,0x7976,0x2862,0x796E,0x287A,0x7966,0x2892,0x795F,0x28AA,0x7957,0x28C2,0x794E,0x28DA
	.hword 0x7946,0x28F1,0x793E,0x2909,0x7936,0x2921,0x792E,0x2939,0x7926,0x2951,0x791E,0x2968,0x7916,0x2980,0x790E,0x2998
	.hword 0x7906,0x29B0,0x78FD,0x29C7,0x78F5,0x29DF,0x78ED,0x29F7,0x78E5,0x2A0F,0x78DC,0x2A26,0x78D4,0x2A3E,0x78CC,0x2A56
	.hword 0x78C4,0x2A6E,0x78BB,0x2A85,0x78B3,0x2A9D,0x78AA,0x2AB5,0x78A2,0x2ACC,0x789A,0x2AE4,0x7891,0x2AFC,0x7889,0x2B13
	.hword 0x7880,0x2B2B,0x7878,0x2B43,0x786F,0x2B5A,0x7867,0x2B72,0x785E,0x2B8A,0x7856,0x2BA1,0x784D,0x2BB9,0x7845,0x2BD0
	.hword 0x783C,0x2BE8,0x7833,0x2C00,0x782B,0x2C17,0x7822,0x2C2F,0x7819,0x2C46,0x7811,0x2C5E,0x7808,0x2C76,0x77FF,0x2C8D
	.hword 0x77F6,0x2CA5,0x77EE,0x2CBC,0x77E5,0x2CD4,0x77DC,0x2CEB,0x77D3,0x2D03,0x77CA,0x2D1A,0x77C1,0x2D32,0x77B9,0x2D49
	.hword 0x77B0,0x2D61,0x77A7,0x2D78,0x779E,0x2D90,0x7795,0x2DA7,0x778C,0x2DBF,0x7783,0x2DD6,0x777A,0x2DEE,0x7771,0x2E05
	.hword 0x7768,0x2E1D,0x775F,0x2E34,0x7756,0x2E4C,0x774D,0x2E63,0x7743,0x2E7A,0x773A,0x2E92,0x7731,0x2EA9,0x7728,0x2EC1
	.hword 0x771F,0x2ED8,0x7716,0x2EEF,0x770C,0x2F07,0x7703,0x2F1E,0x76FA,0x2F36,0x76F1,0x2F4D,0x76E7,0x2F64,0x76DE,0x2F7C
	.hword 0x76D5,0x2F93,0x76CB,0x2FAA,0x76C2,0x2FC2,0x76B9,0x2FD9,0x76AF,0x2FF0,0x76A6,0x3008,0x769C,0x301F,0x7693,0x3036
	.hword 0x7689,0x304D,0x7680,0x3065,0x7676,0x307C,0x766D,0x3093,0x7663,0x30AA,0x765A,0x30C2,0x7650,0x30D9,0x7646,0x30F0
	.hword 0x763D,0x3107,0x7633,0x311F,0x762A,0x3136,0x7620,0x314D,0x7616,0x3164,0x760D,0x317B,0x7603,0x3193,0x75F9,0x31AA
	.hword 0x75EF,0x31C1,0x75E6,0x31D8,0x75DC,0x31EF,0x75D2,0x3206,0x75C8,0x321D,0x75BE,0x3235,0x75B4,0x324C,0x75AA,0x3263
	.hword 0x75A1,0x327A,0x7597,0x3291,0x758D,0x32A8,0x7583,0x32BF,0x7579,0x32D6,0x756F,0x32ED,0x7565,0x3304,0x755B,0x331B
	.hword 0x7551,0x3332,0x7547,0x3349,0x753D,0x3360,0x7532,0x3377,0x7528,0x338E,0x751E,0x33A5,0x7514,0x33BC,0x750A,0x33D3
	.hword 0x7500,0x33EA,0x74F6,0x3401,0x74EB,0x3418,0x74E1,0x342F,0x74D7,0x3446,0x74CD,0x345D,0x74C2,0x3474,0x74B8,0x348B
	.hword 0x74AE,0x34A2,0x74A3,0x34B9,0x7499,0x34D0,0x748F,0x34E7,0x7484,0x34FE,0x747A,0x3514,0x746F,0x352B,0x7465,0x3542
	.hword 0x745A,0x3559,0x7450,0x3570,0x7445,0x3587,0x743B,0x359D,0x7430,0x35B4,0x7426,0x35CB,0x741B,0x35E2,0x7411,0x35F9
	.hword 0x7406,0x360F,0x73FB,0x3626,0x73F1,0x363D,0x73E6,0x3654,0x73DB,0x366B,0x73D1,0x3681,0x73C6,0x3698,0x73BB,0x36AF
	.hword 0x73B1,0x36C5,0x73A6,0x36DC,0x739B,0x36F3,0x7390,0x370A,0x7385,0x3720,0x737B,0x3737,0x7370,0x374E,0x7365,0x3764
	.hword 0x735A,0x377B,0x734F,0x3792,0x7344,0x37A8,0x7339,0x37BF,0x732E,0x37D5,0x7323,0x37EC,0x7318,0x3803,0x730D,0x3819
	.hword 0x7302,0x3830,0x72F7,0x3846,0x72EC,0x385D,0x72E1,0x3874,0x72D6,0x388A,0x72CB,0x38A1,0x72C0,0x38B7,0x72B5,0x38CE
	.hword 0x72A9,0x38E4,0x729E,0x38FB,0x7293,0x3911,0x7288,0x3928,0x727D,0x393E,0x7271,0x3955,0x7266,0x396B,0x725B,0x3982
	.hword 0x7250,0x3998,0x7244,0x39AF,0x7239,0x39C5,0x722E,0x39DB,0x7222,0x39F2,0x7217,0x3A08,0x720B,0x3A1F,0x7200,0x3A35
	.hword 0x71F5,0x3A4B,0x71E9,0x3A62,0x71DE,0x3A78,0x71D2,0x3A8E,0x71C7,0x3AA5,0x71BB,0x3ABB,0x71B0,0x3AD1,0x71A4,0x3AE8
	.hword 0x7198,0x3AFE,0x718D,0x3B14,0x7181,0x3B2B,0x7176,0x3B41,0x716A,0x3B57,0x715E,0x3B6D,0x7153,0x3B84,0x7147,0x3B9A
	.hword 0x713B,0x3BB0,0x712F,0x3BC6,0x7124,0x3BDD,0x7118,0x3BF3,0x710C,0x3C09,0x7100,0x3C1F,0x70F5,0x3C35,0x70E9,0x3C4C
	.hword 0x70DD,0x3C62,0x70D1,0x3C78,0x70C5,0x3C8E,0x70B9,0x3CA4,0x70AD,0x3CBA,0x70A1,0x3CD0,0x7095,0x3CE7,0x7089,0x3CFD
	.hword 0x707D,0x3D13,0x7071,0x3D29,0x7065,0x3D3F,0x7059,0x3D55,0x704D,0x3D6B,0x7041,0x3D81,0x7035,0x3D97,0x7029,0x3DAD
	.hword 0x701D,0x3DC3,0x7011,0x3DD9,0x7005,0x3DEF,0x6FF9,0x3E05,0x6FEC,0x3E1B,0x6FE0,0x3E31,0x6FD4,0x3E47,0x6FC8,0x3E5D
	.hword 0x6FBB,0x3E73,0x6FAF,0x3E89,0x6FA3,0x3E9F,0x6F97,0x3EB5,0x6F8A,0x3ECB,0x6F7E,0x3EE1,0x6F72,0x3EF6,0x6F65,0x3F0C
	.hword 0x6F59,0x3F22,0x6F4C,0x3F38,0x6F40,0x3F4E,0x6F34,0x3F64,0x6F27,0x3F7A,0x6F1B,0x3F8F,0x6F0E,0x3FA5,0x6F02,0x3FBB
	.hword 0x6EF5,0x3FD1,0x6EE9,0x3FE7,0x6EDC,0x3FFC,0x6ECF,0x4012,0x6EC3,0x4028,0x6EB6,0x403E,0x6EAA,0x4053,0x6E9D,0x4069
	.hword 0x6E90,0x407F,0x6E84,0x4095,0x6E77,0x40AA,0x6E6A,0x40C0,0x6E5E,0x40D6,0x6E51,0x40EB,0x6E44,0x4101,0x6E37,0x4117
	.hword 0x6E2A,0x412C,0x6E1E,0x4142,0x6E11,0x4157,0x6E04,0x416D,0x6DF7,0x4183,0x6DEA,0x4198,0x6DDD,0x41AE,0x6DD1,0x41C3
	.hword 0x6DC4,0x41D9,0x6DB7,0x41EE,0x6DAA,0x4204,0x6D9D,0x421A,0x6D90,0x422F,0x6D83,0x4245,0x6D76,0x425A,0x6D69,0x4270
	.hword 0x6D5C,0x4285,0x6D4F,0x429A,0x6D41,0x42B0,0x6D34,0x42C5,0x6D27,0x42DB,0x6D1A,0x42F0,0x6D0D,0x4306,0x6D00,0x431B
	.hword 0x6CF3,0x4330,0x6CE5,0x4346,0x6CD8,0x435B,0x6CCB,0x4371,0x6CBE,0x4386,0x6CB0,0x439B,0x6CA3,0x43B1,0x6C96,0x43C6
	.hword 0x6C89,0x43DB,0x6C7B,0x43F1,0x6C6E,0x4406,0x6C61,0x441B,0x6C53,0x4430,0x6C46,0x4446,0x6C38,0x445B,0x6C2B,0x4470
	.hword 0x6C1D,0x4485,0x6C10,0x449B,0x6C02,0x44B0,0x6BF5,0x44C5,0x6BE7,0x44DA,0x6BDA,0x44EF,0x6BCC,0x4505,0x6BBF,0x451A
	.hword 0x6BB1,0x452F,0x6BA4,0x4544,0x6B96,0x4559,0x6B88,0x456E,0x6B7B,0x4583,0x6B6D,0x4599,0x6B5F,0x45AE,0x6B52,0x45C3
	.hword 0x6B44,0x45D8,0x6B36,0x45ED,0x6B29,0x4602,0x6B1B,0x4617,0x6B0D,0x462C,0x6AFF,0x4641,0x6AF2,0x4656,0x6AE4,0x466B
	.hword 0x6AD6,0x4680,0x6AC8,0x4695,0x6ABA,0x46AA,0x6AAC,0x46BF,0x6A9E,0x46D4,0x6A90,0x46E9,0x6A83,0x46FE,0x6A75,0x4712
	.hword 0x6A67,0x4727,0x6A59,0x473C,0x6A4B,0x4751,0x6A3D,0x4766,0x6A2F,0x477B,0x6A21,0x4790,0x6A12,0x47A5,0x6A04,0x47B9
	.hword 0x69F6,0x47CE,0x69E8,0x47E3,0x69DA,0x47F8,0x69CC,0x480D,0x69BE,0x4821,0x69B0,0x4836,0x69A1,0x484B,0x6993,0x4860
	.hword 0x6985,0x4874,0x6977,0x4889,0x6969,0x489E,0x695A,0x48B2,0x694C,0x48C7,0x693E,0x48DC,0x692F,0x48F0,0x6921,0x4905
	.hword 0x6913,0x491A,0x6904,0x492E,0x68F6,0x4943,0x68E8,0x4958,0x68D9,0x496C,0x68CB,0x4981,0x68BC,0x4995,0x68AE,0x49AA
	.hword 0x689F,0x49BE,0x6891,0x49D3,0x6882,0x49E7,0x6874,0x49FC,0x6865,0x4A10,0x6857,0x4A25,0x6848,0x4A39,0x683A,0x4A4E
	.hword 0x682B,0x4A62,0x681C,0x4A77,0x680E,0x4A8B,0x67FF,0x4AA0,0x67F0,0x4AB4,0x67E2,0x4AC8,0x67D3,0x4ADD,0x67C4,0x4AF1
	.hword 0x67B6,0x4B06,0x67A7,0x4B1A,0x6798,0x4B2E,0x6789,0x4B43,0x677B,0x4B57,0x676C,0x4B6B,0x675D,0x4B80,0x674E,0x4B94
	.hword 0x673F,0x4BA8,0x6730,0x4BBC,0x6722,0x4BD1,0x6713,0x4BE5,0x6704,0x4BF9,0x66F5,0x4C0D,0x66E6,0x4C22,0x66D7,0x4C36
	.hword 0x66C8,0x4C4A,0x66B9,0x4C5E,0x66AA,0x4C72,0x669B,0x4C86,0x668C,0x4C9B,0x667D,0x4CAF,0x666E,0x4CC3,0x665F,0x4CD7
	.hword 0x6650,0x4CEB,0x6641,0x4CFF,0x6631,0x4D13,0x6622,0x4D27,0x6613,0x4D3B,0x6604,0x4D4F,0x65F5,0x4D63,0x65E6,0x4D77
	.hword 0x65D6,0x4D8B,0x65C7,0x4D9F,0x65B8,0x4DB3,0x65A9,0x4DC7,0x6599,0x4DDB,0x658A,0x4DEF,0x657B,0x4E03,0x656B,0x4E17
	.hword 0x655C,0x4E2B,0x654D,0x4E3F,0x653D,0x4E53,0x652E,0x4E67,0x651F,0x4E7A,0x650F,0x4E8E,0x6500,0x4EA2,0x64F0,0x4EB6
	.hword 0x64E1,0x4ECA,0x64D1,0x4EDE,0x64C2,0x4EF1,0x64B2,0x4F05,0x64A3,0x4F19,0x6493,0x4F2D,0x6484,0x4F40,0x6474,0x4F54
	.hword 0x6465,0x4F68,0x6455,0x4F7C,0x6445,0x4F8F,0x6436,0x4FA3,0x6426,0x4FB7,0x6416,0x4FCA,0x6407,0x4FDE,0x63F7,0x4FF2
	.hword 0x63E7,0x5005,0x63D8,0x5019,0x63C8,0x502C,0x63B8,0x5040,0x63A8,0x5054,0x6399,0x5067,0x6389,0x507B,0x6379,0x508E
	.hword 0x6369,0x50A2,0x6359,0x50B5,0x6349,0x50C9,0x633A,0x50DC,0x632A,0x50F0,0x631A,0x5103,0x630A,0x5117,0x62FA,0x512A
	.hword 0x62EA,0x513E,0x62DA,0x5151,0x62CA,0x5164,0x62BA,0x5178,0x62AA,0x518B,0x629A,0x519E,0x628A,0x51B2,0x627A,0x51C5
	.hword 0x626A,0x51D8,0x625A,0x51EC,0x624A,0x51FF,0x623A,0x5212,0x622A,0x5226,0x6219,0x5239,0x6209,0x524C,0x61F9,0x525F
	.hword 0x61E9,0x5273,0x61D9,0x5286,0x61C9,0x5299,0x61B8,0x52AC,0x61A8,0x52BF,0x6198,0x52D3,0x6188,0x52E6,0x6177,0x52F9
	.hword 0x6167,0x530C,0x6157,0x531F,0x6146,0x5332,0x6136,0x5345,0x6126,0x5358,0x6115,0x536C,0x6105,0x537F,0x60F4,0x5392
	.hword 0x60E4,0x53A5,0x60D4,0x53B8,0x60C3,0x53CB,0x60B3,0x53DE,0x60A2,0x53F1,0x6092,0x5404,0x6081,0x5417,0x6071,0x542A
	.hword 0x6060,0x543C,0x6050,0x544F,0x603F,0x5462,0x602E,0x5475,0x601E,0x5488,0x600D,0x549B,0x5FFD,0x54AE,0x5FEC,0x54C1
	.hword 0x5FDB,0x54D3,0x5FCB,0x54E6,0x5FBA,0x54F9,0x5FA9,0x550C,0x5F99,0x551F,0x5F88,0x5531,0x5F77,0x5544,0x5F66,0x5557
	.hword 0x5F56,0x556A,0x5F45,0x557C,0x5F34,0x558F,0x5F23,0x55A2,0x5F12,0x55B4,0x5F02,0x55C7,0x5EF1,0x55DA,0x5EE0,0x55EC
	.hword 0x5ECF,0x55FF,0x5EBE,0x5612,0x5EAD,0x5624,0x5E9C,0x5637,0x5E8B,0x5649,0x5E7A,0x565C,0x5E69,0x566E,0x5E58,0x5681
	.hword 0x5E48,0x5693,0x5E37,0x56A6,0x5E25,0x56B8,0x5E14,0x56CB,0x5E03,0x56DD,0x5DF2,0x56F0,0x5DE1,0x5702,0x5DD0,0x5715
	.hword 0x5DBF,0x5727,0x5DAE,0x573A,0x5D9D,0x574C,0x5D8C,0x575E,0x5D7A,0x5771,0x5D69,0x5783,0x5D58,0x5795,0x5D47,0x57A8
	.hword 0x5D36,0x57BA,0x5D24,0x57CC,0x5D13,0x57DF,0x5D02,0x57F1,0x5CF1,0x5803,0x5CDF,0x5815,0x5CCE,0x5828,0x5CBD,0x583A
	.hword 0x5CAB,0x584C,0x5C9A,0x585E,0x5C89,0x5870,0x5C77,0x5882,0x5C66,0x5895,0x5C55,0x58A7,0x5C43,0x58B9,0x5C32,0x58CB
	.hword 0x5C20,0x58DD,0x5C0F,0x58EF,0x5BFD,0x5901,0x5BEC,0x5913,0x5BDA,0x5925,0x5BC9,0x5937,0x5BB7,0x5949,0x5BA6,0x595B
	.hword 0x5B94,0x596D,0x5B83,0x597F,0x5B71,0x5991,0x5B60,0x59A3,0x5B4E,0x59B5,0x5B3C,0x59C7,0x5B2B,0x59D9,0x5B19,0x59EB
	.hword 0x5B07,0x59FD,0x5AF6,0x5A0F,0x5AE4,0x5A21,0x5AD2,0x5A32,0x5AC1,0x5A44,0x5AAF,0x5A56,0x5A9D,0x5A68,0x5A8B,0x5A7A

/**************************************/
.size   Fourier_DCT4_CosSin, .-Fourier_DCT4_CosSin
.global Fourier_DCT4_CosSin
/**************************************/
/* EOF                                */
/**************************************/
