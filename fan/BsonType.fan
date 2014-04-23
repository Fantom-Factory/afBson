
** A list of BSON types.
** 
** @see `http://bsonspec.org/spec.html`
enum class BsonType {

	** End-Of-Object. For internal use.
	EOO			( 0, null),
	** Maps to [Float]`sys::Float`.
	DOUBLE		( 1, Float#),
	** Maps to [Str]`sys::Str`.
	STRING		( 2, Str#),
	** Maps to [Map]`sys::Map`. All keys must be 'Str' and all vals must be valid BSON types.
	DOCUMENT	( 3, Map#),
	** Maps to [List]`sys::List`. All vals must be valid BSON types.
	ARRAY		( 4, List#),
	** Maps to `Binary`, or a [Buf]`sys::Buf` if the sub-type is 'BIN_GENERIC'.
	BINARY		( 5, Binary#),
	** Deprecated, do not use.
	UNDEFINED	( 6, null),
	** Maps to `ObjectId`.
	OBJECT_ID	( 7, ObjectId#),
	** Maps to [Bool]`sys::Bool`.
	BOOLEAN		( 8, Bool#),
	** Maps to [DateTime]`sys::DateTime`.
	DATE		( 9, DateTime#),
	** Maps to 'null'.
	NULL		(10, null),
	** Maps to [Regex]`sys::Regex`.
	REGEX		(11, Regex#),
	** Deprecated, do not use.
	DB_POINTER	(12, null),
	** Maps to `Code`.
	CODE		(13, Code#),
	** Deprecated, do not use.
	SYMBOL		(14, null),
	** Maps to `Code`.
	CODE_W_SCOPE(15, Code#),
	** > **CAUTION:** 'INTEGER_32' values will be read as [Int]`sys::Int` values. 
	** If you then write its containing document, the storage type will be converted to 'INTEGER_64'.
	** 
	** This is only of concern if other, non Fantom drivers, are writing to the database.
	INTEGER_32	(16, null),
	** Maps to `Timestamp`.
	TIMESTAMP	(17, Timestamp#),
	** Maps to [Int]`sys::Int`.
	INTEGER_64	(18, Int#),
	** Maps to `MinKey`. For internal use.
	MIN_KEY		(255, MinKey#),
	** Maps to `MaxKey`. For internal use.
	MAX_KEY		(127, MaxKey#);
	
	** The value that uniquely identifies the type as per the [BSON spec]`http://bsonspec.org/spec.html`.
	const Int value

	** The Fantom 'Type' (if any) this BSON type maps to.
	const Type? type

	private new make(Int value, Type? type) {
		this.value	= value
		this.type	= type
	}

	** Throws an 'ArgErr' if invalid.
	static new fromValue(Int value, Bool checked := true) {
		BsonType.vals.find { it.value == value } ?: (checked ? throw ArgErr(ErrMsgs.bsonType_unknownValue(value)) : null)
	}
	
	** Determines a BSON type from the type of the given object.
	** Throws an 'ArgErr' if invalid.
	** 
	** 'Obj' is needed (as oppose to just the type) because a `Code` instance may be mapped to 
	** either 'CODE' or 'CODE_W_SCOPE'.
	static new fromObj(Obj? obj, Bool checked := true) {
		type := obj?.typeof?.toNonNullable
			
		// switch on final / native types
		switch (type) {
			case Float#:	return DOUBLE
			case Str#:		return STRING
			case Bool#:		return BOOLEAN
			case DateTime#:	return DATE
			case Date#:		return DATE
			case null:		return NULL
			case Regex#:	return REGEX
			case Int#:		return INTEGER_64
		}

		// can't switch on parameterized types
		if (obj is List)	return ARRAY
		// a controversial decision - we check individual key types, not the map key type
		if (obj is Map)		return DOCUMENT	

		// test non-final types
		if (obj is Binary)		return BINARY
		if (obj is Buf)			return BINARY
		if (obj is ObjectId)	return OBJECT_ID
		if (obj is Code)		return (obj as Code).scope.isEmpty ? CODE : CODE_W_SCOPE
		if (obj is Timestamp)	return TIMESTAMP
		if (obj is MinKey)		return MIN_KEY
		if (obj is MaxKey)		return MAX_KEY
		
		return null ?: (checked ? throw ArgErr(ErrMsgs.bsonType_unknownType(type)) : null)
	}
	
	** Returns true if the given 'Type' is a BSON literal. 
	** 'null' and 'Buf' are considered literals, whereas 'Maps' and 'Lists' are not.
	** 
	**   BsonType.isBsonLiteral(Int#)      // --> true
	**   BsonType.isBsonLiteral(Code#)     // --> true
	**   BsonType.isBsonLiteral(null)      // --> true
	** 
	**   BsonType.isBsonLiteral(List#)     // --> false
	**   BsonType.isBsonLiteral(Str:Obj?#) // --> false
	static Bool isBsonLiteral(Type? type) {
		if (type == null)		return true
		if (type.fits(Buf#))	return true
		fanType := BsonType.vals.find { type.fits(it.type ?: Void#) }.type
		return fanType != null && fanType != Map# && fanType != List#
	}
}
