
internal const mixin ErrMsgs {
	
	static Str bsonType_unknownId(Int id) {
		"Unknown BSON type id '${id}'"
	}

	static Str bsonType_unknownType(Type type) {
		"Unknown BSON type '${type.signature}'"
	}

	static Str bsonType_unknownNameType(Obj name) {
		"BSON Document names must be 'Str', not : ${name.typeof.signature} - ${name}"
	}
}
