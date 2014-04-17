
internal class TestBsonReadWrite : BsonTest {
	
	// test regex with (?:xui) options - see if flags are part of regex
	
	Void testReadWrite() {
		objId 	:= ObjectId()
		now		:= DateTime.now
		
		bsonValueMap := [
			"double"		: 69f,
			"string"		: "string",
			"document"		: ["wot":"ever"],
			"array"			: ["wot","ever"],
			"binary-md5"	: Binary("dragon".toBuf, Binary.BIN_MD5),
			"binary-old"	: Binary("dragon".toBuf, Binary.BIN_BINARY_OLD),
			"binary-buf"	: "dragon".toBuf,
			"objectId"		: objId,
			"boolean"		: true,
			"date"			: now,
			"null"			: null,
			"regex"			: "wotever".toRegex,
			"code"			: Code("func() { ... }"),
			"code_w_scope"	: Code("func() { ... }", ["wot":"ever"]),
			"timestamp"		: Timestamp(3sec, 69),
			"int64"			: 666,
			"minKey"		: MinKey(),
			"maxKey"		: MaxKey()
		]

		b := Buf()
		BsonWriter(b.out).writeObject(bsonValueMap)
		doc := BsonReader(b.flip.in).readDocument
		
		verifyEq(doc["double"], 	69f)
		verifyEq(doc["string"], 	"string")
		verifyEq(doc["document"], 	Str:Obj?["wot":"ever"])
		verifyEq(doc["array"], 		Obj?["wot","ever"])
		verifyEq(doc["binary-md5"]->subtype,			Binary.BIN_MD5)
		verifyEq(doc["binary-md5"]->data->readAllStr,	"dragon")
		verifyEq(doc["binary-old"]->subtype,			Binary.BIN_BINARY_OLD)
		verifyEq(doc["binary-old"]->data->readAllStr,	"dragon")
		verifyEq(doc["binary-buf"]->readAllStr,			"dragon")
		verifyEq(doc["objectId"], 	objId)
		verifyEq(doc["boolean"], 	true)
		verifyEq(doc["date"], 		now)
		verifyEq(doc["null"], 		null)
		verifyEq(doc["regex"], 		"wotever".toRegex)
		verifyEq(doc["code"]->code,		"func() { ... }")
		verifyEq(doc["code"]->scope,	[:])
		verifyEq(doc["code_w_scope"]->code,		"func() { ... }")
		verifyEq(doc["code_w_scope"]->scope,	Str:Obj?["wot":"ever"])
		verifyEq(doc["timestamp"],	Timestamp(3sec, 69))
		verifyEq(doc["int64"],		666)
		verifyEq(doc["minKey"],		MinKey())
		verifyEq(doc["maxKey"],		MaxKey())
	}
	
	Void testBadDocName() {
		verifyErrMsg(ArgErr#, ErrMsgs.bsonType_unknownNameType(666)) {
			BsonWriter(Buf().out).writeObject([666:"ever"])
		}		
	}
}
