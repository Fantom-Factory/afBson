using inet
using concurrent

** (BSON Type) - 
** A globally unique identifier for MongoDB objects.
**
** Consists of 12 bytes, divided as follows:
** 
** pre>
** | 0  1  2  3 | 4  5  6 | 7  8 | 9 10 11
** | timestamp  | machine | pid  | inc
** <pre
** 
** @See
**  - `http://docs.mongodb.org/manual/reference/object-id/`
**  - `http://api.mongodb.org/java/2.12/org/bson/types/ObjectId.html`
@Serializable { simple = true }
const class ObjectId {
	private static const AtomicInt	counterRef 	:= AtomicInt(0)
	private static const Int 		thisMachine	:= IpAddr.local.bytes.toBase64.hash
	// one cannot get the ProcessId in Java - http://fantom.org/sidewalk/topic/856
	// Even the Java impl of ObjectId generates a random Int 
	private static const Int 		thisPid		:= Int.random
	
	** The creation timestamp with a 1 second accuracy.
	const DateTime	timestamp
	
	** A 4-byte machine identifier, usually the IP address.
	const Int		machine
	
	** A 2-byte process id that this instance was created under.
	const Int 		pid
	
	** A 3-byte 'inc' value.
	const Int 		inc
	
	@NoDoc
	override const Int hash 
  
	** Creates a new 'ObjectId'.
	new make() : this.makeAll(DateTime.now, thisMachine, thisPid, counterRef.incrementAndGet) { }
	
	** Useful for testing.
	@NoDoc
	new makeAll(DateTime timestamp, Int machine, Int pid, Int inc) {
		this.timestamp	= timestamp.floor(1sec)
		this.machine	= machine.and(0xFFFFFF)
		this.pid 		= pid.and(0xFFFF)
		this.inc 		= inc.and(0xFFFFFF)
		this.hash		= [this.timestamp.toJava, this.machine, this.pid, this.inc].reduce(42) |Int result, val -> Int| {
			return (37 * result) + val
		}
	}

	** Create an 'ObjectId' from a hex string.
	static new fromStr(Str hex, Bool checked := true) {
		if (hex.size != 24 || !hex.all { it.isAlphaNum })
			return null ?: (checked ? throw ParseErr("Could not parse ObjectId: ${hex}") : null)

		try {
			timeFromStr	:= hex[ 0..< 8].toInt(16)
			machine		:= hex[ 8..<14].toInt(16)
			pid			:= hex[14..<18].toInt(16)
			inc			:= hex[18..<24].toInt(16)
			timeInSecs	:= Buf(4).writeI4(timeFromStr).flip.readS4	// re-read as a signed number
			timestamp	:= Utils.fromUnixEpoch(timeInSecs * 1000)
			return ObjectId(timestamp, machine, pid, inc)

		} catch (Err e) {
			return null ?: (checked ? throw ParseErr("Could not parse ObjectId: ${hex}", e) : null)
		}
	}

	** Reads an 'ObjectId' from the given stream.
	** 
	** Note the stream is **not** closed.
	static new fromStream(InStream in) {
		origEndian 	:= in.endian
		in.endian 	= Endian.big
		timestamp	:= Utils.fromUnixEpoch(in.readS4 * 1000)
		machine		:= in.readBufFully(null, 3).toHex.toInt(16)
		pid			:= in.readU2
		inc			:= in.readBufFully(null, 3).toHex.toInt(16)
		in.endian 	= origEndian
		return ObjectId(timestamp, machine, pid, inc)
	}

	** Converts this instance into a 24 character hexadecimal string representation.
	Str toHex() {
		toBuf.toHex
	}

	** Encodes this 'ObjectId' into an 12 byte buffer.
	** The returned buffer is positioned at the start and is ready to read.
	Buf toBuf() {
		buf := Buf(12)
		writeToBuf(buf, timestamp.toJava / 1000, 4)
		writeToBuf(buf, machine, 3)
		writeToBuf(buf, pid, 2)
		writeToBuf(buf, inc, 3)
		return buf.flip
	}

	private static Void writeToBuf(Buf buf, Int val, Int noOfBytes) {
		noOfBytes.times |i| {
			buf.write(val.shiftr(8 * (noOfBytes - i - 1)).and(0xFF))
		}
	}
	
	** Returns a Mongo Shell compliant, JavaScript representation of the 'ObjectId'. Example:
	** 
	**   syntax: fantom
	**   objectId.toJs  // --> ObjectId("57fe499fa81320d933000001")
	** 
	** See [MongoDB Extended JSON]`https://docs.mongodb.com/manual/reference/mongodb-extended-json/#oid`.
	Str toJs() {
		"""ObjectId("${toHex}")"""
	}

	** Returns this 'ObjectId' as a 24 character hexadecimal string.
	override Str toStr() {
		toHex
	}
  
	@NoDoc
	override Bool equals(Obj? obj) {
		objId := obj as ObjectId
		if (objId 		== null)			return false
		if (inc 		!= objId.inc)		return false
		if (pid 		!= objId.pid)		return false
		if (machine 	!= objId.machine)	return false
		if (timestamp	!= objId.timestamp)	return false
		return true
	}
}

