
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
** Note: 'Code' is not 'const' because the 'scope' document *could* contain `Binary` data.
** Besides, it is advantageous to change the scope / variable values.
@Serializable
class Code {
	
	** JavaScript code.
	Str code
	
	** Default variable values to use in the function code.
	Str:Obj? scope
  
	** Creates a BSON Code instance.
	new makeCode(Str code, Str:Obj? scope := Str:Obj?[:]) {
		this.code = code
		this.scope = scope
	}

	** For Fantom serialisation
	@NoDoc
	new make(|This|f) { f(this)	}
}
