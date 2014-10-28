
** Wraps an 'InStream' to read BSON objects.
** 
** Note that `Binary` objects with a subtype of 'BIN_GENERIC' will be read and returned as a [Buf]`sys::Buf`.
class BsonReader {
	private static const Log 	log			:= Utils.getLog(BsonReader#)
	private static const Int[]	regexFlags	:= "dimsuxU".chars

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
						log.warn(LogMsgs.bsonReader_sizeMismatch("Document", objSize - bytesRead))
					break

				case BsonType.DOUBLE:
					val = reader.readDouble

				case BsonType.STRING:
					val = reader.readString

				case BsonType.DOCUMENT:
					val = _readDocument(reader)

				case BsonType.ARRAY:
					doc := _readDocument(reader)
					doc.keys.each |key, index| {
						if (key != index.toStr)
							log.warn(LogMsgs.bsonReader_arrayIndexMismatch(key, index))
					}
					val = doc.vals
					
				case BsonType.BINARY:
					size := reader.readInteger32
					subtype := reader.readByte
					if (subtype == 2) {
						newSize := reader.readInteger32
						if ((newSize + 4) != size)
							log.warn(LogMsgs.bsonReader_sizeMismatch("Binary", size - (newSize + 4)))
						size = newSize
					}
					buf := reader.readBinary(size)
					val = (subtype == Binary.BIN_GENERIC) ? buf : Binary(buf, subtype) 

				case BsonType.UNDEFINED:
					log.warn(LogMsgs.bsonReader_deprecatedType("UNDEFINED", name))

				case BsonType.OBJECT_ID:
					val = reader.readObjectId

				case BsonType.BOOLEAN:
					val = (reader.readByte == 0x01)

				case BsonType.DATE:
//					val = DateTime.fromJava(reader.readInteger64)
					val = Utils.fromUnixEpoch(reader.readInteger64)

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
							log.warn(LogMsgs.bsonReader_regexFlagsNotSupported(pattern, notSupported, flags))
						
						supported := Str.fromChars(flags.chars.intersection(regexFlags))
						if (!supported.isEmpty) {
							oldRegex := "/${pattern}/${supported}"
							newRegex := "(?${supported})${pattern}"
							log.info(LogMsgs.bsonReader_convertedRegexFlags(pattern, supported, newRegex))							
							pattern = newRegex
						}
					}
					val = Regex.fromStr(pattern)

				case BsonType.DB_POINTER:
					str  := reader.readString
					data := reader.readBinary(12)
					log.warn(LogMsgs.bsonReader_deprecatedType("DB_POINTER", name))

				case BsonType.CODE:
					code := reader.readString
					val = Code(code)

				case BsonType.SYMBOL:
					symbol := reader.readString
					log.warn(LogMsgs.bsonReader_deprecatedType("SYMBOL", name))

				case BsonType.CODE_W_SCOPE:
					mark := reader.bytesRead
					size := reader.readInteger32
					code := reader.readString
					scope := _readDocument(reader)
					bytesRead := reader.bytesRead - mark
					if (size != bytesRead)
						log.warn(LogMsgs.bsonReader_sizeMismatch("CODE_W_SCOPE", size - bytesRead))
					val = Code(code, scope)

				case BsonType.INTEGER_32:
					val = reader.readInteger32

				case BsonType.TIMESTAMP:
					sec := reader.readInteger32
					inc := reader.readInteger32
					val = Timestamp(Duration.fromStr("${sec}sec"), inc)

				case BsonType.INTEGER_64:
					val = reader.readInteger64

				case BsonType.MIN_KEY:
					val = MinKey()

				case BsonType.MAX_KEY:
					val = MaxKey()
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
}

** Reads basic BSON types and keeps count of the number of bytes read.
internal class BsonBasicTypeReader {
	private static const Log log	:= Utils.getLog(BsonBasicTypeReader#)

	Int bytesRead
	
	private InStream	in
	private BsonBasicTypeReader?	reader
	
	new make(InStream in) {
		this.in = in
	}
	new makeReader(BsonBasicTypeReader reader) {
		this.reader = reader
		this.in	= reader.in
	}

	Str readCString() {
		str := in.readStrToken(null) { it == 0 } ?: throw IOErr("Could not read CString, End Of Stream.")
		bytesRead += str.toBuf.size
		readNull(str)
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
		read(1) { in.readU1 }
	}

	Buf readBinary(Int size) {
		read(size) { in.readBufFully(null, size) }
	}

	Float readDouble() {
		read(8) { in.readF8 }
	}

	Int readInteger32() {
		read(4) { in.readS4 }
	}

	Int readInteger64() {
		read(8) { in.readS8 }
	}

	ObjectId readObjectId() {
		read(12) { ObjectId(in) }
	}

	** Eat the null terminator
	private Void readNull(Str str) {
		nul := readByte
		if (nul != 0)
			log.warn(LogMsgs.bsonReader_nullTerminatorNotZero(nul, str))
	}
	
	private Obj? read(Int bytes, |Obj?->Obj| func) {
		val := func(null)
		bytesRead += bytes
		return val
	}
}
