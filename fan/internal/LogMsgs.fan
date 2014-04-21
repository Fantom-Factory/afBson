
internal const mixin LogMsgs {
	
	static Str bsonReader_nullTerminatorNotZero(Int terminator, Str str) {
		"BSON string terminator was not zero, but '0x${terminator.toHex}' for string : ${str}"
	}

	static Str bsonReader_sizeMismatch(Str what, Int remaining) {
		"BSON size mismatch - read ${what} with ${remaining} bytes remaining"
	}

	static Str bsonReader_deprecatedType(Str type, Str name) {
		"Read deprecated BSON type '${type}' for property '${name}' - returning null"
	}

	static Str bsonReader_arrayIndexMismatch(Str key, Int index) {
		"BSON Array index mismatach '${key}' != ${index}"
	}

	static Str bsonReader_regexFlagsNotSupported(Str regex, Str notSupported, Str flags) {
		"BSON Regex flag(s) '${notSupported}' are not supported by Fantom: /${regex}/${flags}"
	}

	static Str bsonReader_convertedRegexFlags(Str oldRegex, Str flags, Str newRegex) {
		"Converted BSON Regex flag(s) '${flags}' to embedded chars: /${oldRegex}/${flags}  --->  /${newRegex}/"
	}
}
