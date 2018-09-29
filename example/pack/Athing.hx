package example.pack;

typedef T = {
    b: Int
}

@:xml
@:met(A)
@:met("A")
@:met(5)
@:expose
class Athing extends Something {
    public var hey: String;
    public var j: Int;
    public var a: Null<Float>;
    public var b: Something;
    public var btypdef: T;
}