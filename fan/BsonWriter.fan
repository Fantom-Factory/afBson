
** Wraps an 'OutStream' to write BSON objects.
** 
** > **CAUTION:** 'INTEGER_32' values will be read as [Int]`sys::Int` values. 
** If you then write its containing document, the storage type will be converted to 'INTEGER_64'. 
** 
** This is only of concern if other, non Fantom drivers, are writing to the database.
class BsonWriter {
	private static const Log log	:= Utils.getLog(BsonReader#)

	private Str[] 	nameStack		:= [,]
	private Str:Int sizeCache		:= [:]

	** The underlying 'OutStream'.
	OutStream? out {
		private set
	}
	
	** Creates a 'BsonWriter', wrapping the given 'OutSteam'
	** As per the BSON spec, the stream's endian is set to 'little'.
	** 
	** 'out' may be 'null' if the writer is just being used to size documents. 
	new make(OutStream? out) {
		this.out = out
		if (out != null)
			out.endian = Endian.little
	}
	
	** Serialises the given BSON Document to the underlying 'OutStream'.
	This writeDocument([Obj:Obj?]? document) {
		(BsonWriter) cache |->Obj?| {
			if (document != null)
				_writeObject(document, BsonBasicTypeWriter(out))
			return this
		}
	}

	** Calculates the size (in bytes) of the given BSON Document should it be serialised.
	** Nothing is written to the 'OutStream'.
	Int sizeDocument([Obj:Obj?]? document) {
		cache |->Int| {
			(document == null) ? 0 : _writeObject(document, BsonBasicTypeWriter(null)).bytesWritten
		}
	}
	
	** Writes a 'null' terminated BSON string to 'OutStream'.
	This writeCString(Str cstr) {
		BsonBasicTypeWriter(out).writeCString(cstr)
		return this
	}

	** Calculates the size (in bytes) of the given Str should it be serialised as a null terminated 
	** 'CString'.
	** Nothing is written to the 'OutStream'.
	Int sizeCString(Str cstr) {
		BsonBasicTypeWriter(null).writeCString(cstr).bytesWritten
	}
	
	** Writes a 32 bit integer value to 'OutStream'.
	** Unlike storing 'Ints' in a Document, this method *will* write an actual 'INTEGER_32'. 
	This writeInteger32(Int int32) {
		BsonBasicTypeWriter(out).writeInteger32(int32)
		return this
	}

	** Writes a 64 bit integer value to 'OutStream'.
	This writeInteger64(Int int64) {
		BsonBasicTypeWriter(out).writeInteger64(int64)
		return this
	}

	** Flushes the underlying 'OutStream'.
	This flush() {
		out?.flush
		return this
	}

	private Int _sizeObject(Obj? object, BsonBasicTypeWriter writer) {
		// use toCode() to prevent names from masquerading as multiple keys, e.g. func.code.scope 
		name := nameStack.toCode
		if (sizeCache.containsKey(name))
			return sizeCache[name]

		// prevent us from recursively sizing objects when we're not actually writing any data
		if (writer.out == null)
			return -1

		size := _writeObject(object, BsonBasicTypeWriter(null)).bytesWritten
		sizeCache.add(name, size)	// use add() to make sure we don't overwrite any existing keys!
		return size
	}

	private BsonBasicTypeWriter _writeObject(Obj? obj, BsonBasicTypeWriter writer) {
		type := BsonType.fromObj(obj, true)

		switch (type) {
			case BsonType.DOUBLE:
				writer.writeDouble(obj)

			case BsonType.STRING:
				writer.writeString(obj)

			case BsonType.DOCUMENT:
				docSize := _sizeObject(obj, writer)
				writer.writeInteger32(docSize)
				((Obj:Obj?) obj).each |val, name| {
					// a controversial decision - we check individual key types, not the map key type
					// because with [:] it's far too easy to declare Obj maps without knowing it
					// if I were to check the paramaterized Map type, people would soon hate me!
					if (name isnot Str)
						throw ArgErr(ErrMsgs.bsonType_unknownNameType(name))
					
					nameStack.push(name)
					valType := BsonType.fromObj(val, true)
					writer.writeByte(valType.value)
					writer.writeCString(name)
					_writeObject(val, writer)
					nameStack.pop
				}
				writer.writeByte(BsonType.EOO.value)

			case BsonType.ARRAY:
			    doc := Str:Obj?[:] { ordered = true }.addList(obj) |v, i->Str| { i.toStr }
			    _writeObject(doc, writer)

			case BsonType.BINARY:
				if (obj is Buf) 
					obj = Binary(obj, Binary.BIN_GENERIC)

				binary := (Binary) obj
				dataSize := (binary.subtype == Binary.BIN_BINARY_OLD) ? 4 : 0
				dataSize += binary.data.size
				writer.writeInteger32(dataSize)
				writer.writeByte(binary.subtype)
				if (binary.subtype == Binary.BIN_BINARY_OLD) 
					writer.writeInteger32(binary.data.size)
				writer.writeBinary(binary.data)

			case BsonType.OBJECT_ID:
				writer.writeObjectId(obj)

			case BsonType.BOOLEAN:
				writer.writeByte(obj ? 0x01 : 0x00)

			case BsonType.DATE:
				millisecs := ((DateTime) obj).toJava
				writer.writeInteger64(millisecs)

			case BsonType.NULL:
				null?.toStr	// No-op

			case BsonType.REGEX:
				// Regex flags are not supported by Fantom but flag characters can be embedded into 
				// the pattern itself --> /(?i)case-insensitive/
				// see Java's Pattern class for a list of supported flags --> dimsuxU
				// see http://docs.oracle.com/javase/7/docs/api/java/util/regex/Pattern.html#special
				writer.writeCString(obj.toStr)	// --> pattern
				writer.writeCString("")			// --> flags

			case BsonType.CODE:
				writer.writeString(((Code) obj).code)

			case BsonType.CODE_W_SCOPE:
				code := (Code) obj
				nameStack.push("code")
				codeSize := _sizeObject(code, writer)
				writer.writeInteger32(codeSize)
				writer.writeString(code.code)
				nameStack.push("scope")
				_writeObject(code.scope, writer)
				nameStack.pop
				nameStack.pop

			case BsonType.TIMESTAMP:
				timestamp := (Timestamp) obj
				writer.writeInteger32(timestamp.seconds.toSec)
				writer.writeInteger32(timestamp.increment)

			case BsonType.INTEGER_64:
				writer.writeInteger64(obj)
			
			case BsonType.MIN_KEY:
				null?.toStr	// No-op

			case BsonType.MAX_KEY:
				null?.toStr	// No-op
		}
		
		return writer
	}
	
	Obj? cache(|->Obj?| c) {
		try {
			return c.call()
		} finally {
			// clear nameStack in case we're exiting use to an Err and it wasn't popped 
			nameStack.clear
			sizeCache.clear
		}
	}
}


** Writes basic BSON types and keeps count of the number of bytes written.
internal class BsonBasicTypeWriter {
	Int bytesWritten
	OutStream?	out
	
	new make(OutStream? out) {
		this.out = out
	}

	This writeCString(Str str) {
		writeBinary(str.toBuf).writeNull
		return this
	}
	
	This writeString(Str str) {
		buf := str.toBuf
		writeInteger32(buf.size + 1)
		writeBinary(buf).writeNull
		return this
	}
	
	This writeByte(Int byte) {
		out?.write(byte)
		bytesWritten += 1
		return this
	}

	This writeBinary(Buf binary) {
		origPos := binary.pos
		binary.seek(0)
		out?.writeBuf(binary)
		bytesWritten += binary.size
		binary.seek(origPos)
		return this
	}

	This writeDouble(Float double) {
		out?.writeF8(double)
		bytesWritten += 8
		return this
	}

	This writeInteger32(Int int) {
		out?.writeI4(int)
		bytesWritten += 4
		return this
	}

	This writeInteger64(Int int) {
		out?.writeI8(int)
		bytesWritten += 8
		return this
	}

	This writeObjectId(ObjectId objectId) {
		if (out != null) {
			origEndian 	:= out.endian
			out.endian	= Endian.big
			out.writeBuf(objectId.toBuf)
			out.endian 	= origEndian			
		}
		bytesWritten += 12
		return this
	}

	private This writeNull() {
		out?.write(0)
		bytesWritten += 1
		return this
	}
}
