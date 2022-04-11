//using afBson

internal class Example {
	
	Void main() {
		documentIn := [
			"_id"	: ObjectId(),
			"name"	: "Dave",
			"age"	: "42"
		]

		// serialise BSON to a stream
		buf := BsonWriter().writeDocument(documentIn)
		
		// deserialise BSOM from a stream
		documentOut := BsonReader(buf.flip.in).readDocument
		
		echo(documentOut)
	}
}
