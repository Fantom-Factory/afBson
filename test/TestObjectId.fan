
internal class TestObjectId : BsonTest {

	static const Int epoch		:= 1
	static const Int b4Epoch	:= (1 - 1day.toSec).and(0xFF_FF_FF_FF)
	
	Void testMakeAll() {
		objId	:= ObjectId(epoch, 3, 4)
	
		verifyEq(objId.ts,	epoch)
		verifyEq(objId.pid,	    3)
		verifyEq(objId.inc,	    4)
	}

	Void textInc() {
		inc1	:= ObjectId().inc
		inc2	:= ObjectId().inc
		verifyEq(inc1 + 1, inc2)		
	}

	Void testToHex() {
		objId	:= ObjectId(epoch, 3, 4)
		verifyEq(objId.toHex, "000000010000000003000004")
	}

	Void testFromStr() {
		objId	:= ObjectId("000000010000000003000004")

		verifyEq(objId.ts,	epoch)
		verifyEq(objId.pid,	    3)
		verifyEq(objId.inc,	    4)
	
		verifyNull(ObjectId("Oops!", false))
	}

	Void testFromStrWithDodgyDate() {
		str := ObjectId(b4Epoch, 3, 4).toStr
		objId	:= ObjectId(str)
		
		verifyEq(objId.ts,	b4Epoch)
		verifyEq(objId.pid,	      3)
		verifyEq(objId.inc,	      4)
	}

	Void testFromInStream() {
		in := Buf()
			.writeI4(0x00000001)
			.writeI4(0x00000000)
			.writeI4(0x03000004).flip.in
		in.endian = Endian.big
		objId := ObjectId(in)
	
		verifyEq(objId.ts,	epoch)
		verifyEq(objId.pid,	    3)
		verifyEq(objId.inc,	    4)
	}

	Void testFromInStreamWithDodgyEndian() {
		in := Buf()
			.writeI4(0x00000001)
			.writeI4(0x00000000)
			.writeI4(0x03000004).flip.in
		in.endian = Endian.little
		objId := ObjectId(in)
		
		verifyEq(objId.ts,	epoch)
		verifyEq(objId.pid,	    3)
		verifyEq(objId.inc,	    4)
	}

	Void testFromInStreamWithDodgyDate() {
		in := Buf()
			.writeI4(b4Epoch)
			.writeI4(0x00000000)
			.writeI4(0x03000004).flip.in
		objId := ObjectId(in)
		
		verifyEq(objId.ts,	b4Epoch)
		verifyEq(objId.pid,	      3)
		verifyEq(objId.inc,	      4)
	}
	
	Void testEquals() {
		objId1	:= ObjectId("000000010000000003000004")

		objId2	:= ObjectId("000000010000000003000004")
		verifyEq(objId1, objId2)
		
		objId2	= ObjectId("000000090000000003000004")
		verifyNotEq(objId1, objId2)

		objId2	= ObjectId("000000010000090003000004")
		verifyNotEq(objId1, objId2)

		objId2	= ObjectId("000000010000000009000004")
		verifyNotEq(objId1, objId2)

		objId2	= ObjectId("000000010000000003000009")
		verifyNotEq(objId1, objId2)

		verifyNotEq(ObjectId(), ObjectId())

		verifyFalse(ObjectId().equals(null))		
	}
	    
	Void testRoundTrip() {
		oid1	:= ObjectId()

		// round trip via Str
		oidStr	:= oid1.toHex
		oid2	:= ObjectId(oidStr)
		verifyEq(oid1, oid2)

		// round trip via Buf
		oidBuf	:= oid1.toBuf
		oid3	:= ObjectId(oidBuf.in)
		verifyEq(oid1, oid3)
	}

	Void testHash() {
		objId1	:= ObjectId(epoch, 3, 4)
		objId2	:= ObjectId(epoch, 3, 4)
		objId3	:= ObjectId(epoch, 3, 5)
		
		verifyEq	(objId1.hash, objId2.hash)
		verifyNotEq (objId1.hash, objId3.hash)
	}
}
