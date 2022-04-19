
** Reads and writes BSON documents to and from Streams and Bufs.
class BsonIO {
	
	** Reads a BSON document from an 'InStream'.
	** 
	** Notes:
	**  - 'BINARY' objects with a subtype of 'BIN_GENERIC' are returned as a 'Buf'.
	**  - 'CODE' objects are returned as 'Strs'.
	**  - 'INTEGER_32' values are returned as 64-bit 'Ints'.
	**  - 'REGEX' flags are converted to embedded character flags.
	**  - Deprecated BSON objects are returned as 'null'. 
	** 
	** All 'DATE' objects are returned in the given 'TimeZone'.
	** 
	** This does not change the *instant* in the date time continuum, just time zone it is reported in.
	** This lets a stored date time of '12 Dec 2012 18:00 UTC' be returned as '12 Dec 2012 13:00 New_York'.
	Str:Obj? readDoc(InStream in, TimeZone tz := TimeZone.cur) {
		BsonReader(in, tz).readDocument
	}

	** Writes the BSON document to a Buf. 
	** 
	** As per BSON spec, the returned 'Buf' is set to be little endian.
	Buf writeDoc(Str:Obj? document, Buf? buf := null) {
		BsonWriter(buf).writeDocument(document)
	}
	
	** Pretty prints MongoDB documents to a JSON-esque string.
	** Useful for debugging.
	** 
	** Note PrettyPrinter only pretty prints if the resulting text string if greater than 'maxWidth'.
	** So if 'PrettyPrinter' appears not to be working, then try setting a smaller 'maxWidth'.
	** 
	**   syntax: fantom
	**   str := BsonIO.print(doc, 20)
	** 
	Str print(Obj? val, Int maxWidth := 80, Str indent := "  ") {
		BsonPrinter {
			it.maxWidth	= maxWidth
			it.indent 	= indent
		}.print(val)
	}
}
