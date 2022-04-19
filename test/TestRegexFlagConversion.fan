
internal class TestRegexFlagConversion : BsonTest {
	
	Void testRegexFlags() {
		buf := Buf.fromHex("0f0000000b72007265676578006B7275780000")	// --> ["r":"regex".toRegex] with flags 'krux'
		doc := BsonIO().readDoc(buf.in)
		verifyEq(logMsgs.size, 2)
		verifyEq(logMsgs[0].msg, "BSON Regex flag(s) 'kr' are not supported by Fantom: /regex/krux")
		verifyEq(logMsgs[1].msg, "Converted BSON Regex flag(s) 'ux' to embedded chars: /regex/ux --> /(?ux)regex/")
		verifyEq(doc["r"], "(?ux)regex".toRegex)

		logMsgs.clear
		buf = Buf.fromHex("0f0000000b72007265676578006B720000")	// --> ["r":"regex".toRegex] with flags 'kr'
		doc = BsonIO().readDoc(buf.in)
		verifyEq(logMsgs.size, 1)
		verifyEq(logMsgs[0].msg, "BSON Regex flag(s) 'kr' are not supported by Fantom: /regex/kr")
		verifyEq(doc["r"], "regex".toRegex)

		logMsgs.clear
		buf = Buf.fromHex("0f0000000b720072656765780075780000")	// --> ["r":"regex".toRegex] with flags 'ux'
		doc = BsonIO().readDoc(buf.in)
		verifyEq(logMsgs.size, 1)
		verifyEq(logMsgs[0].msg, "Converted BSON Regex flag(s) 'ux' to embedded chars: /regex/ux --> /(?ux)regex/")
		verifyEq(doc["r"], "(?ux)regex".toRegex)
	}
}
