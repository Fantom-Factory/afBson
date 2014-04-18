# Bson

A BSON specification implementation for [Fantom](http://fantom.org/).



## Install

Install `Bson` with the Fantom Respository Manager ( [fanr](http://fantom.org/doc/docFanr/Tool.html#install) ):

    $ fanr install -r http://repo.status302.com/fanr/ afBson

To use in a [Fantom](http://fantom.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afBson 1.0"]



## Documentation

Full API & fandocs are available on the [status302 repository](http://repo.status302.com/doc/afBson/#overview).



## Quick Start

1). Create a text file called `Example.fan`:

    using afBson

    class Example {

      Void main() {
        buf := Buf()

        documentIn := [
          "_id"  : ObjectId(),
          "name"  : "Dave",
          "age"  : "42"
        ]

        // serialise BSON to a stream
        BsonWriter(buf.out).writeDocument(documentIn)

        // deserialise BSOM from a stream
        documentOut := BsonReader(buf.flip.in).readDocument

        echo(documentOut)
      }
    }

2). Run `Example.fan` as a Fantom script from the command line:

    C:\> fan Example.fan

    [_id:53503531a8000b8b44000001, name:Dave, age:42]



## Usage

`Bson` is an implementation of the [BSON specification](http://bsonspec.org/spec.html) complete with serialisation and deserialisation.

`Bson` was created to support the Alien-Factory MongoDB Driver library.

The main `BsonReader` and `BsonWriter` classes (de)serialise BSON objects to and from Fantom using the following mapping:

    BSON            Fantom
    ---------------------------------
    DOUBLE       ->    sys::Float
    STRING       ->    sys::Str
    DOCUMENT     ->    sys::Map
    ARRAY        ->    sys::List
    BINARY       -> afBson::Binary
    OBJECT_ID    -> afBson::ObjectId
    BOOLEAN      ->    sys::Bool
    DATE         ->    sys::DateTime
    NULL         ->         null
    REGEX        ->    sys::Regex
    CODE         -> afBson::Code
    CODE_W_SCOPE -> afBson::Code
    TIMESTAMP    -> afBson::Timestamp
    INTEGER_64   ->    sys::Int
    MIN_KEY      -> afBson::MinKey
    MAX_KEY      -> afBson::MaxKey

Note that the deprecated constructs `UNDEFINED`, `DB_POINTER` and `SYMBOL` are ignored and have no Fantom representation.

> **CAUTION:** `INTEGER_32` values will be read as `Int` values.
If you then write its containing document, the storage type will be converted to `INTEGER_64`.

This is only of concern if other, non Fantom drivers, are writing to the database.

The Alien-Factoy BSON library was inspired by [fantomongo](https://bitbucket.org/liamstask/fantomongo) by Liam Staskawicz.

