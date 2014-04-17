
** Wraps an 'OutStream' to write BSON objects.
** 
** > **CAUTION:** 'INTEGER_32' values will be read as [Int]`sys::Int` values. 
** If you then write its containing document, the storage type will be converted to 'INTEGER_64'. 
** 
** This is only of concern if other, non Fantom drivers, are writing to the database.
class BsonWriter {
	private static const Log log	:= Utils.getLog(BsonReader#)

	private OutStream	out
	
	** Creates a 'BsonWriter', wrapping the given 'OutSteam'
	new make(OutStream out) {
		this.out = out
		this.out.endian = Endian.little
	}
	
	** Serialises the given BSON object to the underlying 'OutStream'.
	Void writeObject(Obj? object) {
		_writeObject(object, BsonBasicTypeWriter(out))
	}

	** Calculates the size (in bytes) of the given BSON object should it be serialised.
	Int sizeObject(Obj? object) {
		_writeObject(object, BsonBasicTypeWriter(null)).bytesWritten
	}
	
	** Writes a 'null' terminated string to the 'OutStream'.
	Void writeCString(Str cstr) {
		BsonBasicTypeWriter(out).writeCString(cstr)
	}

	** Writes a 32 bit integer value to the 'OutStream'.
	Void writeInteger32(Int int32) {
		BsonBasicTypeWriter(out).writeInteger32(int32)
	}

	private Int _sizeObject(Obj? object, BsonBasicTypeWriter writer) {
		// prevent us from recursively sizing objects when we're not actually writing any data
		(writer.out == null) ? -1 : sizeObject(object)
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
				(obj as Obj:Obj?).each |val, name| {
					// a controversial decision - we check individual key types, not the map key type
					// because with [:] it's far too easy to declare Obj maps without knowing it
					// if I were to check the paramaterized Map type, people would soon hate me!
					if (name isnot Str)
						throw ArgErr(ErrMsgs.bsonType_unknownNameType(name))
					
					valType := BsonType.fromObj(val, true)
					writer.writeByte(valType.id)
					writer.writeCString(name)
					_writeObject(val, writer)
				}
				writer.writeByte(BsonType.EOO.id)

			case BsonType.ARRAY:
			    doc := Str:Obj?[:] { ordered = true }.addList(obj) |v, i->Str| { i.toStr }
			    _writeObject(doc, writer)

			case BsonType.BINARY:
				if (obj is Buf) 
					obj = Binary(obj, Binary.BIN_GENERIC)

				binary := obj as Binary
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
				millisecs := (obj as DateTime).toJava
				writer.writeInteger64(millisecs)

			case BsonType.NULL:
				null?.toStr	// No-op

			case BsonType.REGEX:
				writer.writeCString(obj.toStr)	// --> pattern
				writer.writeCString("")		// --> flags
				// TODO: Implement Regex flags -> http://docs.oracle.com/javase/7/docs/api/java/util/regex/Pattern.html#special
				// Options are identified by characters, which must be stored in alphabetical order. 
				// Valid options are 
				//  - 'i' for case insensitive matching, 
				//  - 'm' for multiline matching, 
				//  - 'x' for verbose mode, 
				//  - 'l' to make \w, \W, etc. locale dependent, 
				//  - 's' for dotall mode ('.' matches everything), and 
				//  - 'u' to make \w, \W, etc. match unicode.

			case BsonType.CODE:
				writer.writeString((obj as Code).code)

			case BsonType.CODE_W_SCOPE:
				code := obj as Code
				codeSize := _sizeObject(code, writer)
				writer.writeInteger32(codeSize)
				writer.writeString(code.code)
				_writeObject(code.scope, writer)

			case BsonType.TIMESTAMP:
				timestamp := obj as Timestamp
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
}


** Writes basic BSON types and keeps count of the number of bytes written.
internal class BsonBasicTypeWriter {
	private static const Log log	:= Utils.getLog(BsonBasicTypeWriter#)

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
