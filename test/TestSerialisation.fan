
internal class TestSerialisation : BsonTest {
	
	private ObjectId objId 	:= ObjectId()
	private DateTime now	:= DateTime.now
	
	// test regex with (?:xui) options - see if flags are part of regex
	
	Void testBsonSerialisation() {
		b := Buf()

		BsonWriter(b.out).writeDocument(bsonValueMap)
		doc := BsonReader(b.flip.in).readDocument
		
		verifyBsonValueMap(doc)
	}

	Void testFantomSerialisation() {
		b := Buf()

		b.writeObj(bsonValueMap(true), ["indent":2])
		doc := b.flip.readObj
		
		verifyBsonValueMap(doc, true)
	}
	
	Void testBadDocName() {
		verifyErrMsg(ArgErr#, ErrMsgs.bsonType_unknownNameType(666)) {
			BsonWriter(Buf().out).writeDocument([666:"ever"])
		}		
	}
	
	Map bsonValueMap(Bool fudge := false) {
		doc := [
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
			"timestamp"		: Timestamp(6969, 69),
			"int64"			: 666,
			"minKey"		: MinKey(),
			"maxKey"		: MaxKey()
		]
		if (fudge) {
			doc.remove("binary-buf")
			doc.remove("regex")			// http://fantom.org/sidewalk/topic/2266
		}
		return doc
	}

	Void verifyBsonValueMap(Map doc, Bool fudge := false) {
		verifyEq(doc["double"], 	69f)
		verifyEq(doc["string"], 	"string")
		verifyEq(doc["document"]->get("wot"), "ever")
		verifyEq(doc["array"]->get(0), 	"wot")
		verifyEq(doc["array"]->get(1), 	"ever")
		verifyEq(doc["binary-md5"]->subtype,			Binary.BIN_MD5)
		verifyEq(doc["binary-md5"]->data->readAllStr,	"dragon")
		verifyEq(doc["binary-old"]->subtype,			Binary.BIN_BINARY_OLD)
		verifyEq(doc["binary-old"]->data->readAllStr,	"dragon")
		if (!fudge)
			verifyEq(doc["binary-buf"]->readAllStr,			"dragon")
		verifyEq(doc["objectId"], 	objId)
		verifyEq(doc["boolean"], 	true)
		verifyEq(doc["date"], 		now)
		verifyEq(doc["null"], 		null)
		if (!fudge)
			verifyEq(doc["regex"], 		"wotever".toRegex)
		verifyEq(doc["code"]->code,				"func() { ... }")
		verifyEq(doc["code"]->scope->isEmpty,	true)
		verifyEq(doc["code_w_scope"]->code,		"func() { ... }")
		verifyEq(doc["code_w_scope"]->scope,	Str:Obj?["wot":"ever"])
		verifyEq(doc["timestamp"],	Timestamp(6969, 69))
		verifyEq(doc["int64"],		666)
		verifyEq(doc["minKey"],		MinKey())
		verifyEq(doc["maxKey"],		MaxKey())
	}
	
	Void testQuirkyDateTimeFromJava() {
		atEpoch := DateTime.fromJava(1) - 1ms
		b4Epoch := DateTime.fromJava(1) - 1day
		b := Buf()
		BsonWriter(b.out).writeDocument(["at":atEpoch, "b4":b4Epoch])
		doc := BsonReader(b.flip.in).readDocument
		
//		verifyEq(doc["at"], atEpoch)
		verifyEq(doc["b4"], b4Epoch)
	}

}

