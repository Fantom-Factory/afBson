
** (BSON Type) - 
** 'MinKey' is *less than* any other value of any type. 
** This can be useful for always returning certain documents first (or last). 
const class MinKey { 

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
const class MaxKey {
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
