
internal const mixin ErrMsgs {
	
	static Str bsonType_unknownValue(Int value) {
		"Unknown BSON type id '${value}'"
	}

	static Str bsonType_unknownType(Type type) {
		"Unknown BSON type '${type.signature}'"
	}

	static Str bsonType_unknownNameType(Obj name) {
		"BSON Document names must be 'Str', not : ${name.typeof.signature} - ${name}"
	}
}
