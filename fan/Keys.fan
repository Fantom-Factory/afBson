
** (BSON Type) - 
** 'MinKey' is *less than* any other value of any type. 
** This can be useful for always returning certain documents first (or last). 
@Serializable
const class MinKey { 

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
@Serializable
const class MaxKey {
	
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
