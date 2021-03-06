
** Wraps an 'InStream' to read BSON objects.
** 
** Note that `Binary` objects with a subtype of 'BIN_GENERIC' will be read and returned as a [Buf]`sys::Buf`.
class BsonReader {
	private static const Log 	log			:= BsonReader#.pod.log
	private static const Int[]	regexFlags	:= "dimsuxU".chars

	** The 'TimeZone' in which all 'DateTimes' are returned in.
	** 
	** This does not change the *instant* in the date time continuum, just time zone it is reported in.
	** This lets a stored date time of '12 Dec 2012 18:00 UTC' be returned as '12 Dec 2012 13:00 New_York'.
	TimeZone tz	:= TimeZone.cur
	
	** The underlying 'InStream'.
	InStream in {
		private set
	}

	** Creates a 'BsonReader', wrapping the given 'InSteam'.
	** As per the BSON spec, the stream's endian is to 'little'.
	new make(InStream in) {
		this.in = in
		this.in.endian = Endian.little
	}

	** Reads a BSON Document from the underlying 'InStream'.
	Str:Obj? readDocument() {
		_readDocument(BsonBasicTypeReader(in))
	}

	** Reads a (null terminated) BSON String from the underlying 'InStream'.
	Str readCString() {
		_readCString(BsonBasicTypeReader(in))
	}

	** Reads a BSON Integer32 from the underlying 'InStream'.
	Int readInteger32() {
		_readInteger32(BsonBasicTypeReader(in))
	}

	** Reads a BSON Integer64 from the underlying 'InStream'.
	Int readInteger64() {
		_readInteger64(BsonBasicTypeReader(in))
	}

	private Str:Obj? _readDocument(BsonBasicTypeReader reader) {
		bson 	:= Str:Obj?[:] { ordered = true }
		posMark	:= reader.bytesRead
		objSize	:= reader.readInteger32
		
		while ((reader.bytesRead - posMark) < objSize) {
			type := BsonType.fromValue(reader.readByte, true)
			name := (type == BsonType.EOO) ? null : reader.readCString
			val  := null

			switch (type) {
				case BsonType.EOO:
					bytesRead := reader.bytesRead - posMark
					if (bytesRead < objSize)
						log.warn(bsonReader_sizeMismatch("Document", objSize - bytesRead))
					break

				case BsonType.DOUBLE:
					val = reader.readDouble

				case BsonType.STRING:
					val = reader.readString

				case BsonType.DOCUMENT:
					val = _readDocument(reader)

				case BsonType.ARRAY:
					doc := _readDocument(reader)
					val = doc.vals
					
				case BsonType.BINARY:
					size := reader.readInteger32
					subtype := reader.readByte
					if (subtype == 2) {
						newSize := reader.readInteger32
						if ((newSize + 4) != size)
							log.warn(bsonReader_sizeMismatch("Binary", size - (newSize + 4)))
						size = newSize
					}
					buf := reader.readBinary(size)
					val = (subtype == Binary.BIN_GENERIC) ? buf : Binary(buf, subtype) 

				case BsonType.UNDEFINED:
					log.warn(bsonReader_deprecatedType("UNDEFINED", name))

				case BsonType.OBJECT_ID:
					val = reader.readObjectId

				case BsonType.BOOLEAN:
					val = (reader.readByte == 0x01)

				case BsonType.DATE:
					val = DateTime.fromJava(reader.readInteger64, tz, false) 

				case BsonType.NULL:
					val = null

				case BsonType.REGEX:
					// Regex flags are not supported by Fantom but flag characters can be embedded into 
					// the pattern itself --> /(?i)case-insensitive/
					// see Java's Pattern class for a list of supported flags --> dimsuxU
					// see http://docs.oracle.com/javase/7/docs/api/java/util/regex/Pattern.html#special
					pattern := reader.readCString
					flags 	:= reader.readCString
					
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
					str  := reader.readString
					data := reader.readBinary(12)
					log.warn(bsonReader_deprecatedType("DB_POINTER", name))

				case BsonType.CODE:
					code := reader.readString
					val = Code(code)

				case BsonType.SYMBOL:
					symbol := reader.readString
					log.warn(bsonReader_deprecatedType("SYMBOL", name))

				case BsonType.CODE_W_SCOPE:
					mark := reader.bytesRead
					size := reader.readInteger32
					code := reader.readString
					scope := _readDocument(reader)
					bytesRead := reader.bytesRead - mark
					if (size != bytesRead)
						log.warn(bsonReader_sizeMismatch("CODE_W_SCOPE", size - bytesRead))
					val = Code(code, scope)

				case BsonType.INTEGER_32:
					val = reader.readInteger32

				case BsonType.TIMESTAMP:
					sec := reader.readInteger32
					inc := reader.readInteger32
					val = Timestamp(sec, inc)

				case BsonType.INTEGER_64:
					val = reader.readInteger64

				case BsonType.MIN_KEY:
					val = MinKey.val

				case BsonType.MAX_KEY:
					val = MaxKey.val
			}
			
			if (name != null)
				bson[name] = val
		}
		return bson
	}
	
	private Str _readCString(BsonBasicTypeReader reader) {
		reader.readCString
	}
	
	private Int _readInteger32(BsonBasicTypeReader reader) {
		reader.readInteger32
	}

	private Int _readInteger64(BsonBasicTypeReader reader) {
		reader.readInteger64
	}
	
	private static Str bsonReader_sizeMismatch(Str what, Int remaining) {
		"BSON size mismatch - read ${what} with ${remaining} bytes remaining"
	}

	private static Str bsonReader_deprecatedType(Str type, Str name) {
		"Read deprecated BSON type '${type}' for property '${name}' - returning null"
	}

	private static Str bsonReader_regexFlagsNotSupported(Str regex, Str notSupported, Str flags) {
		"BSON Regex flag(s) '${notSupported}' are not supported by Fantom: /${regex}/${flags}"
	}

	private static Str bsonReader_convertedRegexFlags(Str oldRegex, Str flags, Str newRegex) {
		"Converted BSON Regex flag(s) '${flags}' to embedded chars: /${oldRegex}/${flags}  --->  /${newRegex}/"
	}
}

** Reads basic BSON types and keeps count of the number of bytes read.
internal class BsonBasicTypeReader {
	private static const Log log	:= BsonBasicTypeReader#.pod.log

	Int bytesRead
	
	private InStream				in
	private BsonBasicTypeReader?	reader
	
	new make(InStream in) {
		this.in = in
	}
	new makeReader(BsonBasicTypeReader reader) {
		this.reader = reader
		this.in	= reader.in
	}

	Str readCString() {
		str := in.readNullTerminatedStr(null)
		bytesRead += utf8Size(str) + 1
		return str
	}
	
	Str readString() {
		size := readInteger32 - 1
		// readBufFully() 'cos size is the no. of *bytes*, not chars
		str  := in.readBufFully(null, size).readAllStr(false)
		bytesRead += size
		readNull(str)
		return str
	}
	
	Int readByte() {
		val := in.readU1
		bytesRead += 1
		return val
	}

	Buf readBinary(Int size) {
		val := in.readBufFully(null, size)
		bytesRead += size
		return val
	}

	Float readDouble() {
		val := in.readF8
		bytesRead += 8
		return val
	}

	Int readInteger32() {
		val := in.readS4
		bytesRead += 4
		return val
	}

	Int readInteger64() {
		val := in.readS8
		bytesRead += 8
		return val
	}

	ObjectId readObjectId() {
		val := ObjectId(in)
		bytesRead += 12
		return val
	}

	** Eat the null terminator
	private Void readNull(Str str) {
		nul := readByte
		if (nul != 0)
			log.warn(bsonReader_nullTerminatorNotZero(nul, str))
	}

	** Nicked from HttpClient
	private static Int utf8Size(Str str) {
		size := 0
		chars := str.chars
		for (i := 0; i < chars.size; ++i) {
			ch := chars[i]
			if (ch < 0x0080)	size += 1; else
			if (ch < 0x0800)	size += 2; else
			if (ch < 0x8000)	size += 3; else
			throw Err("Unsupported UTF-8 char: 0x${ch.toHex(4).upper}")
		}
		return size
	}
	
	private static Str bsonReader_nullTerminatorNotZero(Int terminator, Str str) {
		"BSON string terminator was not zero, but '0x${terminator.toHex}' for string : ${str}"
	}
}
