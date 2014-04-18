
** (BSON Type) - 
** Wraps a JavaScript function and its arguments.
** 
** 'Code' is not 'const' because the 'scope' document *could* contain `Binary` data. 
@Serializable
class Code {
	
	** JavaScript code.
	Str code
	
	** A mapping from identifiers to values, representing the scope in which the code should be 
	** evaluated. Essentially a map of method parameters and their arguments.
	Str:Obj? scope
  
	** Creates a BSON Code instance.
	new makeCode(Str code, Str:Obj? scope := [:]) {
		this.code = code
		this.scope = scope
	}

	** For Fantom serialisation
	@NoDoc
	new make(|This|f) { f(this)	}
}
