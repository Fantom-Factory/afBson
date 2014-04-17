
internal class TestObjectId : BsonTest {

	static const DateTime epoc	:= DateTime.fromJava(1000) 
	
	Void testMakeAll() {
		objId	:= ObjectId(epoc, 2, 3, 4)
		
		verifyEq(objId.timestamp,	epoc)
		verifyEq(objId.machine,		   2)
		verifyEq(objId.pid,			   3)
		verifyEq(objId.inc,			   4)
	}

	Void textInc() {
		inc1	:= ObjectId().inc
		inc2	:= ObjectId().inc
		verifyEq(inc1 + 1, inc2)		
	}

	Void testToHex() {
		objId	:= ObjectId(epoc, 2, 3, 4)
		verifyEq(objId.toHex, "000000010000020003000004")
	}

	Void testFromStr() {
		objId	:= ObjectId("000000010000020003000004")

		verifyEq(objId.timestamp,	epoc)
		verifyEq(objId.machine,		   2)
		verifyEq(objId.pid,			   3)
		verifyEq(objId.inc,			   4)
		
		verifyNull(ObjectId("Oops!", false))
	}

	Void testFromInStream() {
		in := Buf()
			.writeI4(0x00000001)
			.writeI4(0x00000200)
			.writeI4(0x03000004).flip.in
		in.endian = Endian.big
		objId := ObjectId(in)
		
		verifyEq(objId.timestamp,	epoc)
		verifyEq(objId.machine,		   2)
		verifyEq(objId.pid,			   3)
		verifyEq(objId.inc,			   4)
	}

	Void testFromInStreamWithDodgyEndian() {
		in := Buf()
			.writeI4(0x00000001)
			.writeI4(0x00000200)
			.writeI4(0x03000004).flip.in
		in.endian = Endian.little
		objId := ObjectId(in)
		
		verifyEq(objId.timestamp,	epoc)
		verifyEq(objId.machine,		   2)
		verifyEq(objId.pid,			   3)
		verifyEq(objId.inc,			   4)
	}
	
	Void testEquals() {
		objId1	:= ObjectId("000000010000020003000004")

		objId2	:= ObjectId("000000010000020003000004")
		verifyEq(objId1, objId2)
		
		objId2	= ObjectId("000000090000020003000004")
		verifyNotEq(objId1, objId2)

		objId2	= ObjectId("000000010000090003000004")
		verifyNotEq(objId1, objId2)

		objId2	= ObjectId("000000010000020009000004")
		verifyNotEq(objId1, objId2)

		objId2	= ObjectId("000000010000020003000009")
		verifyNotEq(objId1, objId2)

		verifyNotEq(ObjectId(), ObjectId())

		verifyFalse(ObjectId().equals(null))		
	}
	    
	Void testRoundTrip() {
		// round trip via Str
		objId1	:= ObjectId()
		verifyEq(objId1, ObjectId(objId1.toHex))

		// round trip via Buf
		buf := objId1.toBuf
		objId2 := ObjectId(buf.in)
		verifyEq(objId1, objId2)
	}

	Void testHash() {
		objId1	:= ObjectId(epoc, 2, 3, 4)
		objId2	:= ObjectId(epoc, 2, 3, 4)
		objId3	:= ObjectId(epoc, 2, 3, 5)
		
		verifyEq	(objId1.hash, objId2.hash)
		verifyNotEq (objId1.hash, objId3.hash)
	}
}
