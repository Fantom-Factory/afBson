
internal class TestSerialisation : BsonTest {
	
	private ObjectId objId 	:= ObjectId()
	private DateTime now	:= DateTime.now.toTimeZone(TimeZone("London"))
	
	// test regex with (?:xui) options - see if flags are part of regex
	
	Void testBsonSerialisation() {
		buf := BsonIO().writeDoc(bsonValueMap)
		doc := BsonIO().readDoc(buf.flip.in, TimeZone("New_York"))
		
		verifyBsonValueMap(doc)
	}

	Void testFantomSerialisation() {
		buf := Buf()

		buf.writeObj(bsonValueMap(true), ["indent":2])
		doc := buf.flip.readObj
		
		verifyBsonValueMap(doc, true)
	}
	
	Void testBadDocName() {
		verifyErrMsg(ArgErr#, "BSON Document names must be Str, not sys::Int - 666") {
			BsonIO().writeDoc((Obj) [666:"ever"])
		}		
	}
	
	Map bsonValueMap(Bool fudge := false) {
		doc := [
			"double"		: 69f,
			"string"		: "string",
			"document"		: ["wot":"ever"],
			"array"			: ["wot","ever"],
			"binary-md5"	: Binary("dragon-md5".toBuf, Binary.BIN_MD5),
			"binary-old"	: Binary("dragon-old".toBuf, Binary.BIN_BINARY_OLD),
			"binary-buf"	: "dragon-buf".toBuf,
			"objectId"		: objId,
			"boolean"		: true,
			"date"			: now,
			"null"			: null,
			"regex"			: "wotever".toRegex,
			"timestamp"		: Timestamp(6969, 69),
			"int64"			: 666,
			"minKey"		: MinKey.val,
			"maxKey"		: MaxKey.val
		]
		if (fudge)
			doc.remove("binary-buf")
		return doc
	}

	Void verifyBsonValueMap(Map doc, Bool fudge := false) {
		verifyEq(doc["double"], 	69f)
		verifyEq(doc["string"], 	"string")
		verifyEq(doc["document"]->get("wot"), "ever")
		verifyEq(doc["array"]->get(0), 	"wot")
		verifyEq(doc["array"]->get(1), 	"ever")
		verifyEq(doc["binary-md5"]->subtype,				Binary.BIN_MD5)
		verifyEq(doc["binary-md5"]->data->in->readAllStr,	"dragon-md5")
		verifyEq(doc["binary-old"]->subtype,				Binary.BIN_BINARY_OLD)
		verifyEq(doc["binary-old"]->data->in->readAllStr,	"dragon-old")
		if (!fudge)
			verifyEq(doc["binary-buf"]->readAllStr,			"dragon-buf")
		verifyEq(doc["objectId"], 	objId)
		verifyEq(doc["boolean"], 	true)
		verifyEq(doc["date"], 		now)
		verifyEq(doc["null"], 		null)
		verifyEq(doc["regex"], 		"wotever".toRegex)
		verifyEq(doc["timestamp"],	Timestamp(6969, 69))
		verifyEq(doc["int64"],		666)
		verifyEq(doc["minKey"],		MinKey.val)
		verifyEq(doc["maxKey"],		MaxKey.val)
		
		dat := doc["date"] as DateTime
		if (!fudge)
		verifyEq(dat.tz.name, "New_York")
		verifyEq(now.tz.name, "London")
		
		// DateTime.equals() ignores TimeZone, but ensures the *instants* / ticks are equal.
		verifyEq(dat, now)
	}
	
	Void testQuirkyDateTimeFromJava() {
		atEpoch := DateTime.fromJava(1) - 1ms
		b4Epoch := DateTime.fromJava(1) - 1day
		buf := BsonIO().writeDoc(["at":atEpoch, "b4":b4Epoch])
		doc := BsonIO().readDoc(buf.flip.in)
		
		verifyEq(doc["at"], atEpoch)
		verifyEq(doc["b4"], b4Epoch)
	}
}
