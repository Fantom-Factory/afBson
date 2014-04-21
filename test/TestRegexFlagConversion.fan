
internal class TestRegexFlagConversion : BsonTest {
	
	Void testRegexFlags() {
		buf := Buf.fromHex("0f0000000b72007265676578006B7275780000")	// --> ["r":"regex".toRegex] with flags 'krux'
		doc := BsonReader(buf.in).readDocument
		verifyEq(logMsgs.size, 2)
		verifyEq(logMsgs[0].msg, LogMsgs.bsonReader_regexFlagsNotSupported("regex", "kr", "krux"))
		verifyEq(logMsgs[1].msg, LogMsgs.bsonReader_convertedRegexFlags("regex", "ux", "(?ux)regex"))
		verifyEq(doc["r"], "(?ux)regex".toRegex)

		logMsgs.clear
		buf = Buf.fromHex("0f0000000b72007265676578006B720000")	// --> ["r":"regex".toRegex] with flags 'kr'
		doc = BsonReader(buf.in).readDocument
		verifyEq(logMsgs.size, 1)
		verifyEq(logMsgs[0].msg, LogMsgs.bsonReader_regexFlagsNotSupported("regex", "kr", "kr"))
		verifyEq(doc["r"], "regex".toRegex)

		logMsgs.clear
		buf = Buf.fromHex("0f0000000b720072656765780075780000")	// --> ["r":"regex".toRegex] with flags 'ux'
		doc = BsonReader(buf.in).readDocument
		verifyEq(logMsgs.size, 1)
		verifyEq(logMsgs[0].msg, LogMsgs.bsonReader_convertedRegexFlags("regex", "ux", "(?ux)regex"))
		verifyEq(doc["r"], "(?ux)regex".toRegex)
	}
}
