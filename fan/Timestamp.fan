using concurrent

** (BSON Type) - 
** Timestamps are used internally by MongoDB's replication. 
** You can see them in their natural habitat by querying 'local.main.$oplog'.
@Serializable
const class Timestamp {
	
	private static const AtomicInt	counterRef 	:= AtomicInt(0)
	private static const AtomicInt	lastNowRef 	:= AtomicInt(DateTime.now(1sec).toJava / 1000)
	private static const Synchronized	sync	:= Synchronized(ActorPool() { it.name=Timestamp#.qname; it.maxThreads=1; })
	
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
		sync.synchronized |->Timestamp| {
			now := DateTime.now(1sec).toJava / 1000
			inc := counterRef.incrementAndGet
			if (lastNowRef.val != now) {
				lastNowRef.val = now
				counterRef.val = inc = 0
			}
			return Timestamp(now, inc)
		}
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
		"""Timestamp(${seconds}, ${increment})"""
	}

	static Void main(Str[] args) {
		Timestamp.now.toJs { echo(it) }
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
