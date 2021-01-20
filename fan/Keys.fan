
** (BSON Type) - 
** 'MinKey' is *less than* any other value of any type. 
** This can be useful for always returning certain documents first (or last). 
@Serializable { simple = true }
final const class MinKey {

	** Singleton value.
	static const MinKey defVal := MinKey()

	** Returns the singleton 'defVal' instance.
	static MinKey val() { defVal }
	
	** None shall make!
	private new make() { }
	
	** For simple serialisation.
	@NoDoc
	static MinKey fromStr(Str str) { val }
	
	** Returns a Mongo Shell compliant, JavaScript representation of 'MinKey'. Example:
	** 
	**   syntax: fantom
	**   minKey.toJs  // --> MinKey
	** 
	** See [MongoDB Extended JSON]`https://docs.mongodb.com/manual/reference/mongodb-extended-json/#minkey`.
	Str toJs() {
		"MinKey"
	}

	@NoDoc
	override Str toStr() {
		"MinKey"
	}
	
	@NoDoc
	override Int hash() {
		toStr.hash
	}
	
	@NoDoc
	override Bool equals(Obj? obj) {
		return obj is MinKey
	}
}

** (BSON Type) - 
** 'MaxKey' is *greater than* any other value of any type. 
** This can be useful for always returning certain documents last (or first). 
@Serializable { simple = true }
final const class MaxKey {

	** Singleton value.
	static const MaxKey defVal := MaxKey()

	** Returns the singleton 'defVal' instance.
	static MaxKey val() { defVal }
	
	** None shall make!
	private new make() { }

	** For simple serialisation.
	@NoDoc
	static MaxKey fromStr(Str str) { val }

	** Returns a Mongo Shell compliant, JavaScript representation of 'MaxKey'. Example:
	** 
	**   syntax: fantom
	**   maxKey.toJs  // --> MaxKey
	** 
	** See [MongoDB Extended JSON]`https://docs.mongodb.com/manual/reference/mongodb-extended-json/#maxkey`.
	Str toJs() {
		"MaxKey"
	}

	@NoDoc
	override Str toStr() {
		"MaxKey"
	}
	
	@NoDoc
	override Int hash() {
		toStr.hash
	}
	
	@NoDoc
	override Bool equals(Obj? obj) {
		return obj is MaxKey
	}
}
