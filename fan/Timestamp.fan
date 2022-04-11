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
		now	:= Duration.nowTicks / 1sec.ticks
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
		ts := obj as Timestamp
		if (ts 			== null)			return false
		if (seconds		!= ts.seconds)		return false
		if (increment	!= ts.increment)	return false
		return true
	}
}
