using concurrent::AtomicInt

** (BSON Type) - 
** Timestamps are used internally by MongoDB's replication. 
** You can see them in their natural habitat by querying 'local.main.$oplog'.
@Serializable
final const class Timestamp {
	private static const AtomicInt	counterRef 	:= AtomicInt(0)
	
	** The number of seconds since the UNIX epoch.
	const Int seconds

	** The increment value.
	const Int increment
	
	** Creates a BSON Timestamp instance.
	new makeTimestamp(Int seconds, Int increment) {
		this.seconds   = seconds
		this.increment = increment
	}
	
	** Returns a unique 'Timestamp' representing now.
	static Timestamp now() {
		now	:= DateTime.now(1sec).toJava / 1000
		inc := counterRef.getAndIncrement
		
		// inc is supposed to reset for every unique now second
		// but feck it - we don't create Timestamp values, only MongoDB does!
		return Timestamp(now, inc)
	}
	
	** For Fantom serialisation
	@NoDoc
	new make(|This|f) { f(this)	}
	
	** Returns a Mongo Shell compliant, JavaScript representation of the 'Timestamp'. Example:
	** 
	**   syntax: fantom
	**   timestamp.toJs  // --> Timestamp(1476290079, 4)
	** 
	** See [MongoDB Extended JSON]`https://docs.mongodb.com/manual/reference/mongodb-extended-json/#timestamp`.
	Str toJs() {
		"Timestamp(${seconds}, ${increment})"
	}

	@NoDoc
	override Str toStr() {
		"${seconds} + ${increment}"
	}
	
	@NoDoc
	override Int hash() {
		toStr.hash
	}
	
	@NoDoc
	override Bool equals(Obj? obj) {
		that				:= obj as Timestamp
		if (that 			== null)			return false
		if (this.seconds	!= that.seconds)	return false
		if (this.increment	!= that.increment)	return false
		return true
	}
	
	@NoDoc
	override Int compare(Obj obj) {
		that				:= (Timestamp) obj
		if (this == that)	return 0
		if (this.seconds	< that.seconds)		return -1
		if (this.seconds	> that.seconds)		return  1
		if (this.increment	< that.increment)	return -1
		if (this.increment	> that.increment)	return  1
												return  0
	}
}
