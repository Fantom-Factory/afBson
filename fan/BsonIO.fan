
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
	Str:Obj? readDocument(InStream in, TimeZone tz := TimeZone.cur) {
		BsonReader(in, tz).readDocument
	}

	** Writes the BSON document to a Buf. 
	** 
	** As per BSON spec, the returned 'Buf' is set to be little endian.
	Buf writeDocument(Str:Obj? document) {
		BsonWriter().writeDocument(document)
	}
}
