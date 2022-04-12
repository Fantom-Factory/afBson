//using afBson

internal class Example {
	
	Void main() {
		documentIn := [
			"_id"	: ObjectId(),
			"name"	: "Dave",
			"age"	: "42"
		]

		// serialise BSON to a Buf
		buf := BsonIO().writeDocument(documentIn)
		
		// deserialise BSOM from a stream
		documentOut := BsonIO().readDocument(buf.flip.in)
		
		echo(documentOut)
	}
}
