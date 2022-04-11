
** Writes documents of BSON values to a 'Buf'.
class BsonBuf {
	
	Buf buf	{ private set }
	
	private OutStream	out
	
	** Creates a new BSON writer.
	** 
	** The wrapped 'Buf' is set to be little endian (as per BSON spec).
	new make() {
		this.buf		= Buf()
		this.buf.endian	= Endian.little
		this.out		= buf.out
	}
	
	** Writes a BSON document.
	This writeDocument(Obj:Obj? document) {
		_writeDocument(document)
		return this
	}	
	
	private Void _writeObject(Obj? obj) {
		type := BsonType.fromObj(obj, true)

		switch (type) {
			case BsonType.DOUBLE:
				buf.writeF8(obj)

			case BsonType.STRING:
				_writeString(obj)

			case BsonType.DOCUMENT:
				_writeDocument(obj)

			case BsonType.ARRAY:
				_writeArray(obj)

			case BsonType.BINARY:
				_writeBuf(obj)

			case BsonType.OBJECT_ID:
				((ObjectId) obj).writeToStream(out)

			case BsonType.BOOLEAN:
				out.write(obj ? 0x01 : 0x00)

			case BsonType.DATE:
				millisecs := ((DateTime) obj).toJava
				out.writeI8(millisecs)

			case BsonType.NULL:
				null?.toStr	// No-op

			case BsonType.REGEX:
				// Regex flags are not supported by Fantom but flag characters can be embedded into 
				// the pattern itself --> /(?i)case-insensitive/
				// see Java's Pattern class for a list of supported flags --> dimsuxU
				// see http://docs.oracle.com/javase/7/docs/api/java/util/regex/Pattern.html#special
				_writeCString(obj)	// --> pattern
				_writeCString("")	// --> flags

			case BsonType.TIMESTAMP:
				timestamp := (Timestamp) obj
				out.writeI4(timestamp.seconds)
				out.writeI4(timestamp.increment)

			case BsonType.INTEGER_64:
				out.writeI8(obj)
			
			case BsonType.MIN_KEY:
				null?.toStr	// No-op

			case BsonType.MAX_KEY:
				null?.toStr	// No-op
			
			default:
				throw UnsupportedErr("Can not write a BSON ${type.name}")
		}
	}
	
	private Void _writeDocument(Obj:Obj? doc) {
		// save position anf write a placeholder size
		sizePos	:= buf.size
		out.writeI4(0)

		doc.each |val, name| {
			// a controversial decision - we check individual key types, not the map key type
			// because with [:] it's far too easy to declare Obj maps without knowing it
			// if I were to check the paramaterized Map type, people would soon hate me!
			if (name isnot Str)
				throw ArgErr("BSON Document names must be Str, not ${name.typeof.signature} - ${name}")
			
			valType := BsonType.fromObj(val, true)
			out.write(valType.value)
			_writeCString(name)
			_writeObject(val)
		}
		out.write(BsonType.EOO.value)
		
		// go back and re-write the document size
		docSize := buf.size - sizePos
		buf.seek(sizePos)
		out.writeI4(docSize)
		buf.seek(buf.size)
	}
	
	private Void _writeArray(Obj?[] array) {
		// save position anf write a placeholder size
		sizePos	:= buf.size
		out.writeI4(0)

		for (i := 0; i < array.size; ++i) {
			val		:= array.get(i)
			valType := BsonType.fromObj(val, true)
			out.write(valType.value)
			_writeCString(i.toStr)
			_writeObject(val)
		}
		out.write(BsonType.EOO.value)
		
		// go back and re-write the document size
		docSize := buf.size - sizePos
		buf.seek(sizePos)
		out.writeI4(docSize)
		buf.seek(buf.size)
	}
	
	private Void _writeBuf(Obj obj) {
		buff := (Buf) (obj is Buf ? obj                : ((Binary) obj).data)
		bint := (Int) (obj is Buf ? Binary.BIN_GENERIC : ((Binary) obj).subtype)

		dataSize := (bint == Binary.BIN_BINARY_OLD) ? 4 : 0
		dataSize += buff.size
		out.writeI4(dataSize)
		out.write(bint)
		if (bint == Binary.BIN_BINARY_OLD) 
			out.writeI4(buff.size)

		if (buff.isImmutable)
			// we can't seek on immutable bufs
			out.writeBuf(buff)

		else {
			origPos := buff.pos
			buff.seek(0)
			out.writeBuf(buff)
			buff.seek(origPos)
		}
	}
	
	private Void _writeString(Str str) {
		out.writeI4(sizeUtf8(str) + 1)
		out.writeChars(str)
		out.write(0)
	}
	
	private Void _writeCString(Str cstr) {
		out.writeChars(cstr)
		out.write(0)
	}
	
	** Nicked from HttpClient
	private static Int sizeUtf8(Str str) {
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
}
