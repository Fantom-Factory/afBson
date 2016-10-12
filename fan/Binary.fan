
** (BSON Type) - 
** Wraps binary data and its subType.
** Subtypes from zero to 127 are predefined or reserved. Subtypes from 128-255 are user-defined.
** 
** Binary objects with a default subtype of 'BIN_GENERIC' will be read and returned as a [Buf]`sys::Buf`. 
@Serializable { simple=true }
const class Binary {

	** BSON binary subtype.
	** The default subtype.
	static const Int BIN_GENERIC	:= 0x00
	** BSON binary subtype.
	static const Int BIN_FUNCTION	:= 0x01
	** BSON binary subtype.
	** Depreated, do not use.
	static const Int BIN_BINARY_OLD	:= 0x02
	** BSON binary subtype.
	** Depreated, do not use.
	static const Int BIN_UUID_OLD	:= 0x03
	** BSON binary subtype.
	static const Int BIN_UUID		:= 0x04
	** BSON binary subtype.
	static const Int BIN_MD5		:= 0x05
	** BSON binary subtype.
	static const Int BIN_USER		:= 0x80

	** The binary subtype
	const Int subtype
	
	** The binary data 
	@Transient
	const Buf data

	** Creates a BSON Binary instance. 
	** Note that by creating a 'Binary' instance, the data in 'Buf' will be cleared. See [Buf docs]`sys::Buf` for more info. 
	new make(Buf data, Int subtype := BIN_GENERIC) {
		this.subtype = subtype
		this.data    = data.toImmutable	// note this clears the existing 'Buf' instance
	}
	
	** For Fantom serialisation
	@NoDoc
	override Str toStr() {
		StrBuf().add(subtype).addChar('-').add(data.toBase64).toStr
	}
	
	** For Fantom serialisation
	@NoDoc
	static new fromStr(Str str) {
		dIdx	:= str.index("-")
		sub		:= str[0..<dIdx].toInt
		base64	:= str[dIdx+1..-1]
		return Binary(Buf.fromBase64(base64), sub)
	}
}
