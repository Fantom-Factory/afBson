
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
	
	** Undefined.
	** 
	** (Deprecated, not used.)
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
	
	** DBPointer. 
	** 
	** (Deprecated, not used.)
	DB_POINTER	(12, null),
	
	** Maps to [Str]`sys::Str` (read only).
	CODE		(13, null),
	
	** Symbol. 
	** 
	** (Deprecated, not used.)
	SYMBOL		(14, null),
	
	** Code with scope.
	** 
	** (Deprecated, not used.)
	CODE_W_SCOPE(15, null),
	
	** Maps to [Int]`sys::Int` (read only).
	INTEGER_32	(16, null),
	
	** Maps to `Timestamp`.
	TIMESTAMP	(17, Timestamp#),
	
	** Maps to [Int]`sys::Int`.
	INTEGER_64	(18, Int#),
	
	** 128-bit decimal floating point number.
	** 
	** (Not supported.)
	DECIMAL_128	(19, null),
	
	** Maps to `MinKey`. For internal use.
	MIN_KEY		(255, MinKey#),
	
	** Maps to `MaxKey`. For internal use.
	MAX_KEY		(127, MaxKey#);
	
	** The value that uniquely identifies the type as per the [BSON spec]`http://bsonspec.org/spec.html`.
	const Int value

	** The Fantom 'Type' (if any) this BSON type maps to.
	const Type? type

	private static const Int:BsonType	valueMap
	private static const Type:BsonType	typeMap

	static {
		// a static ctor in an enum is pretty dodgy,
		// but having a valueMap / typeMap is the most efficient way to code fromValue() / isBsonLiteral()
		valueMap :=  Int:BsonType[:]
		typeMap	 := Type:BsonType[:]
		BsonType.vals.each {
			valueMap[it.value] = it
			if (it.type != null)
				typeMap[it.type] = it
		}
		BsonType.valueMap = valueMap
		BsonType.typeMap  = typeMap
	}
	
	private new make(Int value, Type? type) {
		this.value	= value
		this.type	= type
	}

	** Throws an 'ArgErr' if invalid.
	static new fromValue(Int value, Bool checked := true) {
		valueMap[value] ?: (checked ? throw ArgErr("Unknown BSON value ID: ${value}") : null)
	}
	
	** Throws an 'ArgErr' if invalid.
	static new fromType(Type? type, Bool checked := true) {
		type == null
			? NULL
			: (typeMap[type.toNonNullable] ?: (checked ? throw ArgErr("Unknown BSON type: ${type}") : null))
	}
	
	** Determines a BSON type from the type of the given object.
	** Throws an 'ArgErr' if invalid.
	static new fromObj(Obj? obj, Bool checked := true) {
		type := obj?.typeof?.toNonNullable
			
		// switch on final / native types
		switch (type) {
			case Float#		: return DOUBLE
			case Str#		: return STRING
			case Binary#	: return BINARY
			case ObjectId#	: return OBJECT_ID
			case Bool#		: return BOOLEAN
			case DateTime#	: return DATE
			case null		: return NULL
			case Regex#		: return REGEX
			case Timestamp#	: return TIMESTAMP 
			case Int#		: return INTEGER_64
			case MinKey#	: return MIN_KEY
			case MaxKey#	: return MAX_KEY
		}

		// can't switch on parameterized / non final types
		if (obj is Map)		return DOCUMENT	
		if (obj is List)	return ARRAY
		if (obj is Buf)		return BINARY
		
		if (checked)
			throw ArgErr("Unknown BSON type: ${type.signature}")
		return null
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
		
		fanType := fromType(type, false)
		if (fanType != null && fanType != DOCUMENT && fanType != ARRAY)
			return true

		if (type.fits(Buf#))	return true
		return false
	}
}
