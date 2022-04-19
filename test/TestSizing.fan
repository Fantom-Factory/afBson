using concurrent

internal class TestSizing : BsonTest {
		
	Void testNestedSizing() {
		// don't need to test all objects, just a couple to satisfy my curiosity
		verifySize([:], 					 5)
		verifySize(["i":2], 				16)
		verifySize(["s":"wotever"], 		20)
		verifySize(["s":"wotever", "i":2],	31)

		verifySize(["d1":[:]], 						14)
		verifySize(["d1":["i":2]], 					25)
		verifySize(["d1":["s":"wotever"]], 			29)
		verifySize(["d1":["s":"wotever", "i":2]],	40)

		verifySize(["d2":["d1":[:]]], 						23)
		verifySize(["d2":["d1":["i":2]]], 					34)
		verifySize(["d2":["d1":["s":"wotever"]]], 			38)
		verifySize(["d2":["d1":["s":"wotever", "i":2]]], 	49)

		verifySize(["d3":["d2":["d1":[:]]]], 						32)
		verifySize(["d3":["d2":["d1":["i":2]]]], 					43)
		verifySize(["d3":["d2":["d1":["s":"wotever"]]]], 			47)
		verifySize(["d3":["d2":["d1":["s":"wotever", "i":2]]]], 	58)
	}
	
	private Void verifySize(Obj doc, Int size) {
		buf := BsonIO().writeDoc(doc)
		
		// verify no messages were logged during reading - for they indicate a size read failure		
		BsonIO().readDoc(buf.flip.in)
		if (!logMsgs.isEmpty)
			fail("Msg logged- ${logMsgs}")
	}
}
