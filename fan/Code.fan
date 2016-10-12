
** (BSON Type) - 
** Wraps a JavaScript function and default variable values.
** 
** 'scope' values are automatically evaluated in the context of the code when it is executed.
** Example:
** 
**   Syntax: fantom
**   Code("function (x) { return x + y; }", ["y":2])
** 
** Code objects let you re-use functions and change their parameters without re-interpolating a 
** Str function.
** 
** Note that Code objects have no JavaScript representation.
@Serializable
const class Code {
	
	** JavaScript code.
	const Str code
	
	** Default variable values to use in the function code.
	const Str:Obj? scope
  
	** Creates a BSON Code instance.
	new makeCode(Str code, Str:Obj? scope := Str:Obj?[:]) {
		this.code = code
		this.scope = scope
	}

	@NoDoc
	override Str toStr() {
		if (scope.isEmpty)
			return code
		return code + " " + Buf().writeObj(scope).flip.readAllStr["[sys::Str:sys::Str]".size..-1]
	}
	
	** For Fantom serialisation
	@NoDoc
	new make(|This|f) { f(this)	}
}
