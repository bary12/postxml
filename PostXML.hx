#if macro
import Xml;
import sys.io.File;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.ExprTools;
using PostXML.Utils;

class Utils {
    static public function getClassPath(cls: ClassType) : String {
        var native = cls.meta.extract(':native');
        if (native.length > 0) {
            var expr = native[0].params[0].expr;
            switch (expr) {
                case EConst(CString(s)):
                    return s;
                default: throw 'Expected one string param in @:native meta in class ${cls.module}';
            }
        }
        return cls.pack.concat([cls.name]).join('.');
    }
    static public function getFinalName(field: ClassField) : String {
        var native = field.meta.extract(':native');
        if (native.length > 0) {
            var expr = native[0].params[0].expr;
            switch (expr) {
                case EConst(CString(s)):
                    return s;
                default: throw 'Expected one string param in @:native meta in field ${field.name}';
            }
        }
        return field.name;
    }
}
#end

typedef Attributes = Map<String, Null<String>>;

class PostXML {
    #if macro
    public static function use(outPath:String) {
        Context.onAfterTyping(function(modules) {
            var file = File.write(outPath, false);
            file.writeString(generateXml(modules).toString());
            file.close();
        });
    }

    private static function createXML(name:String, ?attrs:Attributes, ?children:Array<Null<Xml>>):Xml {
        var xml = Xml.createElement(name);
        if (attrs != null)
            for (key in attrs.keys())
                if (attrs[key] != null)
                    xml.set(key, attrs[key]);
        if (children != null)
            for (child in children)
                if (child != null)
                    xml.addChild(child);
        return xml;
    }

    private static function generateXml(modules:Array<ModuleType>):Xml {
        return createXML('haxe', null, modules.map(function(module) {
            switch (module) {
                case TClassDecl(cls):
                    var kls = cls.get();
                    if (!kls.meta.has(':postxml'))
                        return null;                    
                    var meta = kls.meta.get();
                    var xml = createXML('class', [
                        "path" => kls.getClassPath(),
                        "file" => ~/\./.replace(kls.module, '/') + '.hx',
                        "params" => kls.params.map(function(param) return param.name).join(':')
                    ], kls.fields.get().map(function(field):Xml {
                            return fieldXml(field, false);
                        }).concat(kls.statics.get().map(function(stat) {
                            return fieldXml(stat, true);
                        })));
                    if (!kls.isPrivate)
                        xml.set("public", "1");
                    if (kls.doc != null)
                        xml.addChild(createXML('haxe_doc', null, [Xml.createPCData(kls.doc)]));
                    if (meta.length > 0)
                        xml.addChild(metaXml(meta));
                    if (kls.superClass != null)
                        xml.addChild(createXML('extends', ["path" => kls.superClass.t.get().getClassPath()]));
                    return xml;
                default:
                    return null;
            }
        }));
    }

    public static function fieldXml(field:ClassField, isStatic:Bool): Null<Xml> {
        var name = field.getFinalName();
        if (~/^operator\s*[^A-Za-z]/.match(name)) { // C++/C# operator overloading. their names can't be in an XML tag name
            return null;
        }
        var xml = createXML(name, [
            "public" => (field.isPublic ? "1" : null),
            "set" => (field.kind.match(FMethod(_)) ? 'method' : null),
            "static" => (isStatic ? "1" : null)
        ], [
            typeXml(field.type)
        ]);
        if (field.doc != null)
            xml.addChild(createXML('haxe_doc', null, [Xml.createPCData(field.doc)]));
        if (field.meta != null)
            xml.addChild(metaXml(field.meta.get()));
        return xml;
    }

    public static function metaXml(meta: Metadata): Xml {
        return createXML('meta', null, meta.map(function(metaEntry):Xml {
            return createXML('m', ["n" => metaEntry.name], metaEntry.params.map(function(param:Expr):Xml {
                return createXML("e", null, [Xml.createPCData(param.toString())]);
            }));
        }));
    }
    public static function typeXml(type:Type):Xml {
        return switch (type) {
            case TInst(fieldTypeClass, params):
                createXML('c', ["path" => fieldTypeClass.get().module], params.map(typeXml));
            case TAbstract(fieldTypeAbstract, params):
                var typ = fieldTypeAbstract.get();
                createXML('x', [
                    "path" => typ.pack.concat([typ.name]).join('.')
                ], params.map(typeXml));
            case TEnum(fieldEnum, params):
                var enm = fieldEnum.get();
                createXML('e', ["path" => enm.pack.concat([enm.name]).join('.')]);
            case TType(fieldTypeTypedef, _):
                createXML('t', [
                    "path" => fieldTypeTypedef.get().pack.concat([fieldTypeTypedef.get().name]).join('.')
                ]);
            case TFun(args, ret):
                createXML(
                    'f',
                    [
                        "a" => args
                            .map(function(arg) return arg.name)
                            .join(':')
                    ],
                    args
                        .map(function(arg) return typeXml(arg.t))
                        .concat([typeXml(ret)]));
            case TDynamic(_) | TAnonymous(_):
                createXML('x', ["path" => "Dynamic"]);
            case TMono(monoType):
                typeXml(monoType.get());
            case null:
                createXML('unknown');
            default:
                throw 'unssuported ${type.getName()}';
                null;
        }
    }
    #end
}
