package example;

import haxe.ds.Vector;

@:postxml
class Main {
    public static function main() {
        trace('Hello World!');
    }
}

@:postxml
class A {
    @:dox(hide)
    public var a: Int;
    @:dox(hide)
    public static function main() {
        trace('Hello World!');
    }
    public var baxe: Vector<Int>;
}

@:postxml
class B extends A {
    public var b: A;
}