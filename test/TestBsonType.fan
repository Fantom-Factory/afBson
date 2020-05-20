
internal class TestBsonType : BsonTest {
	
	Void testFromValued() {
		verifyEq(BsonType.fromValue( 0), BsonType.EOO)
		verifyEq(BsonType.fromValue(10), BsonType.NULL)
		
		verifyErrMsg(ArgErr#, "Unknown BSON type id '23'") {
			b := BsonType.fromValue(23)
		}
		
		verifyNull(BsonType.fromValue(23, false))
	}

	Void testFromType() {
		verifyEq(BsonType.fromObj("69"), BsonType.STRING)
		verifyEq(BsonType.fromObj( 69 ), BsonType.INTEGER_64)
		verifyEq(BsonType.fromObj(null), BsonType.NULL)

		verifyEq(BsonType.fromObj(Code("")), BsonType.CODE)
		verifyEq(BsonType.fromObj(Code("", ["wot":"ever"])), BsonType.CODE_W_SCOPE)

		verifyErrMsg(ArgErr#, "Unknown BSON type '${this.typeof}'") {
			b := BsonType.fromObj(this)
		}

		verifyEq(BsonType.fromObj([1, 2]), BsonType.ARRAY)

		// all empty map types should be allowed 
		verifyEq(BsonType.fromObj(Str:Obj?[:]), BsonType.DOCUMENT)
		verifyEq(BsonType.fromObj(BsonTest:Obj?[:]), BsonType.DOCUMENT)
		
		// valid map types
		verifyEq(BsonType.fromObj(Str:Obj?["wot":6666]), BsonType.DOCUMENT)
		verifyEq(BsonType.fromObj(Str:Int?["wot":6666]), BsonType.DOCUMENT)
		
		// a controversial decision - we check individual key types, not the map key type
		verifyEq(BsonType.fromObj(Obj:Obj["wot":6666]), BsonType.DOCUMENT)
		verifyEq(BsonType.fromObj([:].addAll(["wot":6666])), BsonType.DOCUMENT)
		
		// this is allowed 'cos we're not yet serialising the map values
		verifyEq(BsonType.fromObj(Str:Obj?["wot":this]), BsonType.DOCUMENT)
	}
	
	Void testIsBsonLiteral() {
		verify(BsonType.isBsonLiteral(Int#))
		verify(BsonType.isBsonLiteral(Str#))
		verify(BsonType.isBsonLiteral(Code#))
		verify(BsonType.isBsonLiteral(Binary#))
		verify(BsonType.isBsonLiteral(Buf#))
		verify(BsonType.isBsonLiteral(null))
		verify(BsonType.isBsonLiteral(T_MyBin#))

		verifyFalse(BsonType.isBsonLiteral(List#))
		verifyFalse(BsonType.isBsonLiteral(Map#))
		verifyFalse(BsonType.isBsonLiteral(Str:Obj?#))
		verifyFalse(BsonType.isBsonLiteral(Str[]#))
	}
}

internal const class T_MyBin : Binary {
	new make(Buf data) : super(data, 0) { } 
}
