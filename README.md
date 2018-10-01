# PostXML

A macro that generates dox-compatible documentation XML. Unlike the compiler built-in `-xml` option, this macro generates the XML files with type information **after** build macro transformations have taken place, as well as replacing the names of fields with their `@:native`. This allows you to generate documentation with

# Usage

Add the following lines to your hxml file:

```
--macro PostXML.use('path/to/out.xml')
-D use_rtti_doc
```

and add @:postxml to every class you want included in the XML file. To add all classes, use `--macro addGlobalMetadata('my.package', ':postxml')`

`-D use_rtti_doc` is a compilation flag that tells the Haxe compiler to preverse documentation after the typing phase of the compilation. If you don't care about documentation and only need class/field information, you can omit this (In Haxe 4, this flag is on by default. See [HaxeFoundation/haxe#7493](https://github.com/HaxeFoundation/haxe/issues/7493))