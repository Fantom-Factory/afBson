using concurrent::AtomicInt

** (BSON Type) - 
** A globally unique identifier for MongoDB objects.
**
** The ObjectID BSON type is a 12-byte value consisting of three different portions (fields):
**  - a 4-byte value representing the seconds since the Unix epoch in the highest order bytes
**  - a 5-byte random number unique to a machine and process
**  - a 3-byte counter, starting with a random value
** 
** pre>
**   4 byte timestamp    5 byte process unique   3 byte counter
** |<----------------->|<---------------------->|<------------>|
** [----|----|----|----|----|----|----|----|----|----|----|----]
** 0                   4                   8                   12
** <pre
** 
** @See
**  - `https://github.com/mongodb/specifications/blob/master/source/objectid.rst`
** 
@Serializable { simple = true }
final const class ObjectId {
	private static const AtomicInt	counterRef 	:= AtomicInt(Int.random)
	// one cannot get the ProcessId in Java - http://fantom.org/sidewalk/topic/856
	// Even the Java impl of ObjectId generates a random Int 
	private static const Int 		thisPid		:= Int.random.and(0xFF_FF_FF_FF_FF)
	private static const Int		epochOffset	:= DateTime.fromJava(1).ticks / 1sec.ticks
	
	** The creation timestamp with a 1 second accuracy.
	const Int	ts
	
	** A 5-byte process id that this instance was created under.
	const Int 	pid
	
	** A 3-byte counter value.
	const Int 	inc
	
	@NoDoc
	override const Int hash 
  
	** Creates a new 'ObjectId'.
	new make() {
		this.ts		= (DateTime.nowTicks / 1sec.ticks) - epochOffset
		this.pid	= thisPid
		this.inc	= counterRef.incrementAndGet.and(0xFF_FF_FF)
		this.hash	= ts.shiftl(32) + pid.and(0xFF).shiftl(24) + inc
	}
	
	** Useful for testing.
	@NoDoc
	new makeAll(Int ts, Int pid, Int inc) {
		this.ts		= ts .and(0xFF_FF_FF_FF)
		this.pid 	= pid.and(0xFF_FF_FF_FF_FF)
		this.inc 	= inc.and(0xFF_FF_FF)
		this.hash	= ts .shiftl(32) + pid.and(0xFF).shiftl(24) + inc
	}

	** Create an 'ObjectId' from a hex string.
	static new fromStr(Str hex, Bool checked := true) {
		if (hex.size != 24)
			return null ?: (checked ? throw ParseErr("Could not parse ObjectId: ${hex}") : null)

		try {
			ts	:= hex[ 0..< 8].toInt(16)
			pid	:= hex[ 8..<18].toInt(16)
			inc	:= hex[18..<24].toInt(16)
			return ObjectId(ts, pid, inc)

		} catch (Err e)
			return null ?: (checked ? throw ParseErr("Could not parse ObjectId: ${hex}", e) : null)
	}

	** Reads an 'ObjectId' from the given stream.
	** 
	** Note the stream is **not** closed.
	static new fromStream(InStream in) {
		origEndian 	:= in.endian
		in.endian 	 = Endian.big
		ts			:= in.readU4
		pid			:= in.readU4.shiftl(8) + in.read
		inc			:= in.readU2.shiftl(8) + in.read
		in.endian 	= origEndian
		return ObjectId(ts, pid, inc)
	}

	** Converts the 'ts' field into a Fantom 'DateTime' instance.
	DateTime timestamp(TimeZone tz := TimeZone.cur) {
		DateTime.fromJava(ts * 1000, tz, true)
	}
	
	** Converts this instance into a 24 character hexadecimal string representation.
	Str toHex() {
		toBuf.toHex
	}

	** Encodes this 'ObjectId' into an 12 byte buffer.
	** The returned buffer is positioned at the start and is ready to read.
	Buf toBuf() {
		buf := Buf(12)
		writeToStream(buf.out)
		return buf.flip
	}
	
	** Writes this 'ObjectId' to the given 'OutStream'.
	OutStream writeToStream(OutStream out) {
		origEndian 	:= out.endian
		out.endian	= Endian.big
		out.writeI4(ts)
		out.writeI4(pid.shiftr(8)).write(pid)
		out.writeI2(inc.shiftr(8)).write(inc)
		out.endian	= origEndian
		return out
	}

	** Returns a Mongo Shell compliant, JavaScript representation of the 'ObjectId'. Example:
	** 
	**   syntax: fantom
	**   objectId.toJs  // --> ObjectId("57fe499fa81320d933000001")
	** 
	** See [MongoDB Extended JSON]`https://docs.mongodb.com/manual/reference/mongodb-extended-json/#oid`.
	Str toJs() {
		"ObjectId(${toHex.toCode})"
	}

	** Returns this 'ObjectId' as a 24 character hexadecimal string.
	override Str toStr() {
		toHex
	}
  
	@NoDoc
	override Bool equals(Obj? obj) {
		that := obj as ObjectId
		if (that	 == null)		return false
		if (that.inc != this.inc)	return false
		if (that.pid != this.pid)	return false
		if (that.ts  != this.ts )	return false
		return true
	}
}
