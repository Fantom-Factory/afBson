//using afBson

internal class Example {
	
	Void main() {
		buf := Buf()

		documentIn := [
			"_id"	: ObjectId(),
			"name"	: "Dave",
			"age"	: "42"
		]

		// serialise BSON to a stream
		BsonWriter(buf.out).writeDocument(documentIn)
		
		// deserialise BSOM from a stream
		documentOut := BsonReader(buf.flip.in).readDocument
		
		echo(documentOut)
	}
}
