
** Wraps an 'InStream' to read BSON objects.
class BsonReader {
	private static const Log log	:= Utils.getLog(BsonReader#)

	private InStream in

	** Creates a 'BsonReader', wrapping the given 'InSteam'.
	new make(InStream in) {
		this.in = in
		this.in.endian = Endian.little
	}

	** Reads a BSON Double from the underlying 'InStream'.
	Float readDouble() {
		_readDouble(BsonBasicTypeReader(in))
	}

	** Reads a BSON String from the underlying 'InStream'.
	Str readString() {
		_readString(BsonBasicTypeReader(in))
	}

	** Reads a BSON Document from the underlying 'InStream'.
	Str:Obj? readDocument() {
		_readDocument(BsonBasicTypeReader(in))
	}

	** Reads a BSON Array from the underlying 'InStream'.
	Obj?[] readArray() {
		_readArray(BsonBasicTypeReader(in))
	}

	** Reads a BSON Binary object from the underlying 'InStream'.
	Binary readBinary() {
		_readBinary(BsonBasicTypeReader(in))
	}

	** Reads a BSON ObjectId from the underlying 'InStream'.
	ObjectId readObjectId() {
		_readObjectId(BsonBasicTypeReader(in))
	}

	** Reads a BSON Boolean from the underlying 'InStream'.
	Bool readBoolean() {
		_readBoolean(BsonBasicTypeReader(in))
	}

	** Reads a BSON Date from the underlying 'InStream'.
	DateTime readDate() {
		_readDate(BsonBasicTypeReader(in))
	}

	** Reads a BSON Regex from the underlying 'InStream'.
	Regex readRegex() {
		_readRegex(BsonBasicTypeReader(in))
	}

	** Reads a BSON Code object from the underlying 'InStream'.
	Code readCode() {
		_readCode(BsonBasicTypeReader(in))
	}

	** Reads a BSON Code object from the underlying 'InStream'.
	Code readCodeWithScope() {
		_readCodeWithScope(BsonBasicTypeReader(in))
	}

	** Reads a BSON Timestamp object from the underlying 'InStream'.
	Timestamp readTimestamp() {
		_readTimestamp(BsonBasicTypeReader(in))
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
			type := BsonType.fromId(reader.readByte, true)
			name := (type == BsonType.EOO) ? null : reader.readCString
			val  := null

			switch (type) {
				case BsonType.EOO:
					bytesRead := reader.bytesRead - posMark
					if (bytesRead < objSize)
						log.warn(LogMsgs.bsonReader_sizeMismatch("Document", objSize - bytesRead))
					break

				case BsonType.DOUBLE:
					val = _readDouble(reader)

				case BsonType.STRING:
					val = _readString(reader)

				case BsonType.DOCUMENT:
					val = _readDocument(reader)

				case BsonType.ARRAY:
					val = _readArray(reader)
					
				case BsonType.BINARY:
					bin := _readBinary(reader)
					val = (bin.subtype == Binary.BIN_GENERIC) ? bin.data : bin 

				case BsonType.UNDEFINED:
					log.warn(LogMsgs.bsonReader_deprecatedType("UNDEFINED", name))

				case BsonType.OBJECT_ID:
					val = _readObjectId(reader)

				case BsonType.BOOLEAN:
					val = _readBoolean(reader)

				case BsonType.DATE:
					val = _readDate(reader)

				case BsonType.NULL:
					val = null

				case BsonType.REGEX:
					val = _readRegex(reader)

				case BsonType.DB_POINTER:
					str  := reader.readString
					data := reader.readBinary(12)
					log.warn(LogMsgs.bsonReader_deprecatedType("DB_POINTER", name))

				case BsonType.CODE:
					val = _readCode(reader)

				case BsonType.SYMBOL:
					symbol := reader.readString
					log.warn(LogMsgs.bsonReader_deprecatedType("SYMBOL", name))

				case BsonType.CODE_W_SCOPE:
					val = _readCodeWithScope(reader)

				case BsonType.INTEGER_32:
					val = reader.readInteger32

				case BsonType.TIMESTAMP:
					val = _readTimestamp(reader)

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
	
	private Float _readDouble(BsonBasicTypeReader reader) {
		reader.readDouble
	}
	
	private Str _readString(BsonBasicTypeReader reader) {
		reader.readString
	}
	
	private Obj?[] _readArray(BsonBasicTypeReader reader) {
		doc := _readDocument(reader)
		doc.keys.each |key, index| {
			if (key != index.toStr)
				log.warn(LogMsgs.bsonReader_arrayIndexMismatch(key, index))
		}
		return doc.vals
	}

	private Binary _readBinary(BsonBasicTypeReader reader) {
		size := reader.readInteger32
		subtype := reader.readByte
		if (subtype == 2) {
			newSize := reader.readInteger32
			if ((newSize + 4) != size)
				log.warn(LogMsgs.bsonReader_sizeMismatch("Binary", size - (newSize + 4)))
			size = newSize
		}
		buf := reader.readBinary(size)
		return Binary(buf, subtype)
	}
	
	private ObjectId _readObjectId(BsonBasicTypeReader reader) {
		reader.readObjectId
	}
	
	private Bool _readBoolean(BsonBasicTypeReader reader) {
		reader.readByte == 0x01
	}
	
	private DateTime _readDate(BsonBasicTypeReader reader) {
		DateTime.fromJava(reader.readInteger64)
	}
	
	private Regex _readRegex(BsonBasicTypeReader reader) {
		pattern := reader.readCString
		flags := reader.readCString
		// TODO: Implement Regex flags -> http://docs.oracle.com/javase/7/docs/api/java/util/regex/Pattern.html#special
		// Options are identified by characters, which must be stored in alphabetical order. 
		// Valid options are 
		//  - 'i' for case insensitive matching, 
		//  - 'm' for multiline matching, 
		//  - 'x' for verbose mode, 
		//  - 'l' to make \w, \W, etc. locale dependent, 
		//  - 's' for dotall mode ('.' matches everything), and 
		//  - 'u' to make \w, \W, etc. match unicode.
		if (flags != "")
			log.warn(LogMsgs.bsonReader_regexFlagsNotSupported(pattern, flags))
		return Regex.fromStr(pattern)
	}
	
	private Code _readCode(BsonBasicTypeReader reader) {
		code := reader.readString
		return Code(code)
	}

	private Code _readCodeWithScope(BsonBasicTypeReader reader) {
		mark := reader.bytesRead
		size := reader.readInteger32
		code := reader.readString
		scope := _readDocument(reader)
		bytesRead := reader.bytesRead - mark
		if (size != bytesRead)
			log.warn(LogMsgs.bsonReader_sizeMismatch("CODE_W_SCOPE", size - bytesRead))
		return Code(code, scope)
	}

	private Timestamp _readTimestamp(BsonBasicTypeReader reader) {
		sec := reader.readInteger32
		inc := reader.readInteger32
		return Timestamp(Duration.fromStr("${sec}sec"), inc)
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
