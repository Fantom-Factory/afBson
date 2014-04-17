
** (BSON Type) - 
** Timestamps are used internally by MongoDB's replication. 
** You can see them in their natural habitat by querying 'local.main.$oplog'.
const class Timestamp {
	
	** The seconds value.
	const Duration seconds
	** The increment value.
	const Int increment
	
	** Creates a BSON Timestamp instance.
	new make(Duration seconds, Int increment) {
		this.seconds = seconds
		this.increment = increment
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
		if (ts == null)						return false
		if (seconds		!= ts.seconds)		return false
		if (increment	!= ts.increment)	return false
		return true
	}
}
