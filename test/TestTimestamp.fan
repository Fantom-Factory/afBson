using concurrent

internal class TestTimestamp : BsonTest {
	
	Void testNow() {
		
		ts1 := Timestamp.now
		ts2 := Timestamp.now
		ts3 := Timestamp.now

		Actor.sleep(1sec)

		ts4 := Timestamp.now
		ts5 := Timestamp.now
		ts6 := Timestamp.now
		
		verifyEq(ts1.seconds,   ts2.seconds)
		verifyEq(ts2.seconds,   ts3.seconds)
		verifyEq(ts1.increment, ts2.increment - 1)
		verifyEq(ts2.increment, ts3.increment - 1)

		verifyEq(ts4.seconds,   ts5.seconds)
		verifyEq(ts5.seconds,   ts6.seconds)
		verifyEq(ts4.increment, 0)
		verifyEq(ts4.increment, ts5.increment - 1)
		verifyEq(ts5.increment, ts6.increment - 1)
	}
}
