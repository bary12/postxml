#if postxml_example
package src;
#end

#if macro
import Xml;
import sys.io.File;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.ExprTools;
using PostXML.Utils;

class Utils {
	static public function getFinalName(cls: ClassType) : String {
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
	static public function getFinalFieldName(field: ClassField) : String {
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

typedef Attributes = Map<String, Null<String>>

class PostXML {
	#if macro
	public static function use(outPath:String) {
		Context.onAfterTyping(function(modules) {
			File.write(outPath, false).writeString(generateXml(modules).toString());
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
						"path" => kls.getFinalName(),
						"file" => "",
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
						xml.addChild(createXML('meta', null, meta.map(function(metaEntry):Xml {
							return createXML('m', ["n" => metaEntry.name], metaEntry.params.map(function(param:Expr):Xml {
								return createXML("e", null, [Xml.createPCData(param.toString())]);
							}));
						})));
					return xml;
				default:
					return null;
			}
		}));
	}

	public static function fieldXml(field:ClassField, isStatic:Bool):Xml {
		var xml = createXML(field.getFinalFieldName(), [
            "public" => "1",
            "set" => (field.kind.match(FMethod(_)) ? 'method' : null),
            "static" => (isStatic ? "1" : null)
        ], [
			typeXml(field.type),
			field.doc != null ? createXML('haxe_doc', null, [Xml.createPCData(field.doc)]) : null
		]);
		return xml;
	}

	public static function typeXml(type:Type):Xml {
		return switch (type) {
			case TInst(fieldTypeClass, _):
				createXML('c', ["path" => fieldTypeClass.get().module]);
			case TAbstract(fieldTypeAbstract, _):
				createXML('x', ["path" => fieldTypeAbstract.get().name]);
			case TType(fieldTypeTypedef, _):
				createXML('t', [
					"path" => fieldTypeTypedef.get().pack.concat([fieldTypeTypedef.get().name]).join('.')
				]);
			case TFun(args, ret):
				createXML('f', ["a" => args.map(function(arg) return arg.name).join(':')], args.map(function(arg) return typeXml(arg.t)).concat([typeXml
					(ret)]));
			default:
				throw 'unssuported ${type.getName()}';
				null;
		}
	}
	#end
}
