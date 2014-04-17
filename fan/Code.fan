
** (BSON Type) - 
** Wraps a JavaScript function and its arguments.
** 
** 'Code' is not 'const' because the 'scope' document *could* contain `Binary` data. 
class Code {
	
	** JavaScript code.
	Str code
	
	** A mapping from identifiers to values, representing the scope in which the code should be 
	** evaluated. Essentially a map of method parameters and their arguments.
	Str:Obj? scope
  
	** Creates a BSON Code instance.
	new make(Str code, Str:Obj? scope := [:]) {
		this.code = code
		this.scope = scope
	}
}



