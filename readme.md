## Overview 

`Bson` is an implementation of the [BSON specification](http://bsonspec.org/spec.html) complete with BSON serialisation and deserialisation.

`Bson` was created to support the development of the Alien-Factory [MongoDB driver](http://www.fantomfactory.org/pods/afMongo).

## Install 

Install `Bson` with the Fantom Repository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    C:\> fanr install -r http://repo.status302.com/fanr/ afBson

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afBson 1.0+"]

## Documentation 

Full API & fandocs are available on the [Status302 repository](http://repo.status302.com/doc/afBson/#overview).

## Quick Start 

1). Create a text file called `Example.fan`:

```
using afBson

class Example {

  Void main() {
    buf := Buf()

    documentIn := [
      "_id"  : ObjectId(),
      "name" : "Dave",
      "age"  : 42
    ]

    // serialise BSON to a stream
    BsonWriter(buf.out).writeDocument(documentIn)

    // deserialise BSOM from a stream
    documentOut := BsonReader(buf.flip.in).readDocument

    echo(documentOut)
  }
}
```

2). Run `Example.fan` as a Fantom script from the command line:

```
C:\> fan Example.fan

[_id:53503531a8000b8b44000001, name:Dave, age:42]
```

## Usage 

The main [BsonReader](http://repo.status302.com/doc/afBson/BsonReader.html) and [BsonWriter](http://repo.status302.com/doc/afBson/BsonWriter.html) classes (de)serialise BSON objects to and from Fantom using the following mapping:

```
BSON                Fantom
---------------------------------
ARRAY        ->    sys::List
BINARY       -> afBson::Binary
BOOLEAN      ->    sys::Bool
CODE         -> afBson::Code
CODE_W_SCOPE -> afBson::Code
DATE         ->    sys::DateTime
DOCUMENT     ->    sys::Map
DOUBLE       ->    sys::Float
INTEGER_64   ->    sys::Int
MAX_KEY      -> afBson::MaxKey
MIN_KEY      -> afBson::MinKey
NULL         ->         null
OBJECT_ID    -> afBson::ObjectId
REGEX        ->    sys::Regex
STRING       ->    sys::Str
TIMESTAMP    -> afBson::Timestamp
```

Note that the deprecated BSON constructs `UNDEFINED`, `DB_POINTER` and `SYMBOL` are ignored and have no Fantom representation.

`Bson` takes care of all the tricky `Endian`ness. All BSON objects (except for `Buf` and [Regex](http://fantom.org/sidewalk/topic/2266)) may also be serialised to and from strings using Fantom's standard serialisation techniques.

> **CAUTION:** `INTEGER_32` values will be read as [Int](http://fantom.org/doc/sys/Int.html) values. If you then write its containing document, the storage type will be converted to `INTEGER_64`.

This is only of concern if other, non Fantom, drivers have written `INTEGER_32` values to the database.

> **CAUTION:** Fantom does not support regex flags. When reading a BSON regex, flags are convered into embedded characted flags. e.g. `/myregex/im` is converted into `/(?im)myregex/`. See [Java's Pattern class](http://docs.oracle.com/javase/7/docs/api/java/util/regex/Pattern.html#special) for a list of supported flags (dimsuxU).

Again, this is only of concern if other, non Fantom, drivers have written `REGEX` values (with flags) to the database.

The Alien-Factoy BSON library was inspired by [fantomongo](https://bitbucket.org/liamstask/fantomongo) by Liam Staskawicz.

