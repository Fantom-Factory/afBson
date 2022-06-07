
** Reads a BSON document from an 'InStream'.
internal class BsonReader {
	private static const Log 	log			:= BsonReader#.pod.log
	private static const Int[]	regexFlags	:= "dimsuxU".chars

	private	TimeZone tz
	private InStream in
	
	new make(InStream in, TimeZone tz) {
		this.in		= in
		this.tz		= tz
	}

	Str:Obj? readDocument() {
		endian		:= in.endian
		in.endian	 = Endian.little
		try return	_readDocument
		finally		in.endian = endian
	}
	
	private Str:Obj? _readDocument() {
		bson 	:= Str:Obj?[:] { ordered = true }
		objSize	:= in.readS4
		
		while (true) {
			byte := in.readU1
			type := BsonType.fromValue(byte, true)
			
			if (type == BsonType.EOO)
				break
			
			name := in.readNullTerminatedStr(null)
			val  := null

			switch (type) {
				case BsonType.DOUBLE:
					val = in.readF8

				case BsonType.STRING:
					val = _readString

				case BsonType.DOCUMENT:
					val = _readDocument

				case BsonType.ARRAY:
					doc := _readDocument
					val = doc.vals
					
				case BsonType.BINARY:
					size	:= in.readS4
					subtype := in.readU1
					if (subtype == 2)
						size = in.readS4
					buf := in.readBufFully(null, size)
					val = (subtype == Binary.BIN_GENERIC) ? buf : Binary(buf, subtype) 

				case BsonType.UNDEFINED:
					log.warn(bsonReader_deprecatedType("UNDEFINED", name))

				case BsonType.OBJECT_ID:
					val = ObjectId(in)

				case BsonType.BOOLEAN:
					val = (in.readU1 == 0x01)

				case BsonType.DATE:
					val = DateTime.fromJava(in.readS8, tz, false) 

				case BsonType.NULL:
					val = null

				case BsonType.REGEX:
					// Regex flags are not supported by Fantom but flag characters can be embedded into 
					// the pattern itself --> /(?i)case-insensitive/
					// see Java's Pattern class for a list of supported flags --> dimsuxU
					// see http://docs.oracle.com/javase/7/docs/api/java/util/regex/Pattern.html#special
					pattern := in.readNullTerminatedStr(null)
					flags 	:= in.readNullTerminatedStr(null)

					// convert what flags we can into embedded flag characters
					if (!flags.isEmpty) {
						notSupported := Str.fromChars(flags.chars.findAll { !regexFlags.contains(it) })
						if (!notSupported.isEmpty)
							log.warn(bsonReader_regexFlagsNotSupported(pattern, notSupported, flags))
						
						supported := Str.fromChars(flags.chars.intersection(regexFlags))
						if (!supported.isEmpty) {
							oldRegex := "/${pattern}/${supported}"
							newRegex := "(?${supported})${pattern}"
							log.info(bsonReader_convertedRegexFlags(pattern, supported, newRegex))							
							pattern = newRegex
						}
					}
					val = Regex.fromStr(pattern)

				case BsonType.DB_POINTER:
					str  := _readString
					data := in.readBufFully(null, 12)
					log.warn(bsonReader_deprecatedType("DB_POINTER", name))

				case BsonType.CODE:
					val = _readString

				case BsonType.SYMBOL:
					symbol := _readString
					log.warn(bsonReader_deprecatedType("SYMBOL", name))

				case BsonType.CODE_W_SCOPE:
					size := in.readS4
					code := _readString
					scope := _readDocument
					log.warn(bsonReader_deprecatedType("CODE_W_SCOPE", name))

				case BsonType.INTEGER_32:
					val = in.readS4

				case BsonType.TIMESTAMP:
					inc := in.readS4
					sec := in.readS4
					val = Timestamp(sec, inc)

				case BsonType.INTEGER_64:
					val = in.readS8

				case BsonType.DECIMAL_128:
					num1 := in.readS8
					num2 := in.readS8
					// okay - so it's more "Unsupported" than "Deprecated"!
					log.warn(bsonReader_unsupportedType("DECIMAL_128", name))

				case BsonType.MIN_KEY:
					val = MinKey.val

				case BsonType.MAX_KEY:
					val = MaxKey.val
			}
			
			bson[name] = val
		}
		return bson
	}

	private Str _readString() {
		size := in.readS4 - 1
		// readBufFully() 'cos size is the no. of *bytes*, not chars
		buf  := in.readBufFully(null, size)
		try {
			nul := in.readU1
			if (nul != 0)
				log.warn(bsonReader_nullTerminatorNotZero(nul))
			// read the str *after* reading the null, in case of UTF-8 errors - see below
			return buf.readAllStr(false)

		} catch (IOErr err) {
			// Some MongoDB err msgs DO contain invalid UTF8! (fixed in MongoDB 5.1)
			// so just recover what info we can as ASCII
			// https://jira.mongodb.org/browse/SERVER-50454
			if (err.msg == "Invalid UTF-8 encoding") {
				buf.seek(0)
				str := StrBuf()
				for (i := 0; i < buf.size; ++i) {
					chr := buf.read
					if (chr >= 32 && chr <= 126)	// >= ' ' && <= '~' 
						str.addChar(chr)
					else
						str.addChar('*')
				}
				return str.toStr
			}

			throw err
		}
	}


	
	private static Str bsonReader_deprecatedType(Str type, Str name) {
		"Deprecated BSON type (${type}) for property (${name}) - returning null"
	}

	private static Str bsonReader_unsupportedType(Str type, Str name) {
		"Unsupported BSON type (${type}) for property (${name}) - returning null"
	}

	private static Str bsonReader_regexFlagsNotSupported(Str regex, Str notSupported, Str flags) {
		"BSON Regex flag(s) '${notSupported}' are not supported by Fantom: /${regex}/${flags}"
	}

	private static Str bsonReader_convertedRegexFlags(Str oldRegex, Str flags, Str newRegex) {
		"Converted BSON Regex flag(s) '${flags}' to embedded chars: /${oldRegex}/${flags} --> /${newRegex}/"
	}

	private static Str bsonReader_nullTerminatorNotZero(Int terminator) {
		"BSON string terminator was not zero, but '0x${terminator.toHex}'"
	}
}
