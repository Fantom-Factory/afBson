//using afBson

internal class Example {
	
	Void main() {
		documentIn := [
			"_id"	: ObjectId(),
			"name"	: "Dave",
			"age"	: "42"
		]

		// serialise BSON to a Buf
		buf := BsonIO().writeDoc(documentIn)
		
		// deserialise BSOM from a stream
		documentOut := BsonIO().readDoc(buf.flip.in)
		
		echo(documentOut)
	}
}
