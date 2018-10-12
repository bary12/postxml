package example;

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
    public var baxe: Array<Int>;
}

@:postxml
class B extends A {
    public var b: A;
}