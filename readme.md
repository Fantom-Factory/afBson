# Bson v2.0.4
---

[![Written in: Fantom](http://img.shields.io/badge/written%20in-Fantom-lightgray.svg)](https://fantom-lang.org/)
[![pod: v2.0.4](http://img.shields.io/badge/pod-v2.0.4-yellow.svg)](http://eggbox.fantomfactory.org/pods/afBson)
[![Licence: ISC](http://img.shields.io/badge/licence-ISC-blue.svg)](https://choosealicense.com/licenses/isc/)

## <a name="overview"></a>Overview

Bson is an implementation of the [BSON specification](http://bsonspec.org/spec.html) complete with BSON serialisation and deserialisation.

Note that BSON is an extention of JSON, and JSON can only represent a subset of the types supported by BSON.

Bson was created to support the development of the Fantom Factory [MongoDB driver](http://eggbox.fantomfactory.org/pods/afMongo).

## <a name="Install"></a>Install

Install `Bson` with the Fantom Pod Manager ( [FPM](http://eggbox.fantomfactory.org/pods/afFpm) ):

    C:\> fpm install afBson

Or install `Bson` with [fanr](https://fantom.org/doc/docFanr/Tool.html#install):

    C:\> fanr install -r http://eggbox.fantomfactory.org/fanr/ afBson

To use in a [Fantom](https://fantom-lang.org/) project, add a dependency to `build.fan`:

    depends = ["sys 1.0", ..., "afBson 2.0"]

## <a name="documentation"></a>Documentation

Full API & fandocs are available on the [Eggbox](http://eggbox.fantomfactory.org/pods/afBson/) - the Fantom Pod Repository.

## <a name="quickStart"></a>Quick Start

1). Create a text file called `Example.fan`:

    using afBson
    
    class Example {
    
      Void main() {
        docIn := [
          "_id"  : ObjectId(),
          "name" : "Dave",
          "age"  : 42
        ]
    
        // serialise BSON to a Buf
        buf := BsonIO().writeDoc(documentIn)
    
        // deserialise BSON from a stream
        docOut := BsonIO().readDoc(buf.flip.in)
    
        echo(docOut)
      }
    }
    

2). Run `Example.fan` as a Fantom script from the command line:

    C:\> fan Example.fan
    
    [_id:53503531a8000b8b44000001, name:Dave, age:42]
    

## <a name="usage"></a>Usage

The [BsonIO](http://eggbox.fantomfactory.org/pods/afBson/api/BsonIO) class (de)serialises BSON documents to and from Fantom using the following mapping:

    BSON       <->    Fantom
    -------------------------------
    ARRAY      <->    sys::List      
    BINARY     <-> afBson::Binary    
    BOOLEAN    <->    sys::Bool      
    CODE       -->    sys::Str      (read only)  
    DATE       <->    sys::DateTime  
    DOCUMENT   <->    sys::Map       
    DOUBLE     <->    sys::Float     
    INTEGER_32 -->    sys::Int      (read only)
    INTEGER_64 <->    sys::Int
    MAX_KEY    <-> afBson::MaxKey    
    MIN_KEY    <-> afBson::MinKey    
    NULL       <->         null      
    OBJECT_ID  <-> afBson::ObjectId  
    REGEX      <->    sys::Regex     
    STRING     <->    sys::Str       
    TIMESTAMP  <-> afBson::Timestamp 
    

`Bson` takes care of all the tricky `Endian`ness. All BSON objects may be serialised to and from strings using Fantom's standard serialisation techniques.

### <a name="implNotes"></a>Implementation Notes

Deprecated BSON constructs (`CODE_W_SCOPE`, `DB_POINTER`, `SYMBOL`, and `UNDEFINED`) are ignored and have no Fantom representation.

* `INTEGER_32` values are read as Fantom (64-bit) `Ints`
* `CODE` objects are read as Fantom `Strs`
* `REGEX` flags are read and converted into embedded character flags (e.g., `/myregex/im` is converted to `/(?im)myregex/`)


If these objects are subsequently written back (to MongoDB), be aware that their backing storage type will change to represent their new Fantom type. This is only noteworthy if other, non Fantom, drivers are reading / writing values to / from the database.

See [Java's Pattern Class](http://docs.oracle.com/javase/7/docs/api/java/util/regex/Pattern.html#special) for a list of supported regex flags (`dimsuxU`).

## <a name="specialMention"></a>Special Mentions

The Fantom Factoy BSON library was inspired by `fantomongo` by Liam Staskawicz.

