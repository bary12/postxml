package example;

@:postxml
class Main {
    public static function main() {
        trace('Hello World!');
    }
}

@:postxml
class A {
    public var a: Int;
    public static function main() {
        trace('Hello World!');
    }
}

@:postxml
class B extends A {
    public var b: A;
}