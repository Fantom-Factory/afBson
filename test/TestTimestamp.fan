
internal class TestTimestamp : Test {
	
	Void testCompare() {
		ancient := Timestamp(5, 5)
		present := Timestamp(8, 8)
		verify(present > ancient)
		verify(ancient < present)
		
		ancient = Timestamp(5, 5)
		present = Timestamp(5, 8)
		verify(present > ancient)
		verify(ancient < present)
		
		ancient = Timestamp(5, 5)
		present = Timestamp(5, 5)
		verify(present == ancient)
		verify(ancient == present)
		
		ancient = Timestamp(5, 5)
		present = Timestamp(5, 3)
		verify(present < ancient)
		verify(ancient > present)
		
		ancient = Timestamp(5, 5)
		present = Timestamp(3, 3)
		verify(present < ancient)
		verify(ancient > present)
	}
}
