module codegen;

import input;
import nodes;

import std.format;
import std.array;
import std.algorithm: map, each, fold, all;
import std.functional: curry;
import std.sumtype;

import std.stdio;

struct Line {
    private alias LineSum = SumType!(string, Line[]);
    LineSum internal;

    this(string newstring) {
        internal = LineSum(newstring);
    }

    this(Line line) {
        this = line;
    }

    string toString() {
        return "Line(" ~ internal.toString ~ ")";
    }
}


string linesToString(Line[] lines, uint indentCount = 0) {
    // uint indentCount;
    return lines.map!(
        (Line line) {
            return line.internal.match!(
                (string str) => " ".replicate(4*indentCount) ~ str,
                (Line[] lines2) {
                    indentCount++; scope(exit) indentCount--;
                    return lines2.linesToString(indentCount);
                }
            );
        }
    ).join("\n");
}

import std.range;
Line lineBlock(T)(T lines) {
    Line line;
    static if (is(ElementType!T == Line)) {
        line.internal = Line.LineSum(lines);
    }
    static if (is(ElementType!T == string)) {
        line.internal = Line.LineSum(lines.map!(a=>Line(a)).array);
    }
    return line;
}

Line lineBlock(T...)(T items) {
    Line line;
    Line[] lines;
    foreach (item; items) {
        alias T = typeof(item);
        
        static if (__traits(compiles, lines ~ item)) {
            lines ~= item;
        }
        else {
            lines ~= Line(item);
        }
    }
    line.internal = Line.LineSum(lines);
    return line;
}


unittest {
    import std.stdio;
    writeln("---- Unittest ", __FILE__, " struct Line ----");
    writeln(lineBlock(Line("bar"), "foo"));
}


Line[] codeGenType(Declaration decl) {
    if (auto d = cast(DeclarationStruct) decl) {
        return codeGenTypeStruct(d);
    }
    else 
    if (auto d = cast(DeclarationSum) decl) {
        return codeGenTypeSum(d);
    }
    // else if (cast(EmptyRule) decl) {
    //     return codeGenTypeSum(decl);
    // }
    else {
        throw new CodeGenFailure(
             "Declaration type "
            ~typeid(decl).toString
            ~" not implemented.");
    }
}


Line[] codeGenTypeStruct(DeclarationStruct decl) {
    import std.stdio;
    // Line[] lines;
    return [
        Line(format!"struct %s {"(decl.name)),
        lineBlock(
            () {
                if (decl.members.length == 0) {
                    return [Line("string capture = \"\";")];
                }
                else {
                    return decl.members.map!((Attribute attr) {
                        string typeName = attr.type.name;
                        return Line(format!"%s %s;"(
                            typeName, 
                            attr.name)
                        );
                    }).array;
                }
            }() 
            ~
            codeGenFactory(decl)
        ),
        Line("}")
    ];
}


Line[] codeGenFactory(DeclarationStruct decl) {
    return [
        Line(format!"static %s parse(InputSource source) {"(decl.name)),
        
        lineBlock(
            Line(format!"%s rule = %s();"(decl.name, decl.name)),
            "",
            codeGenGroup(decl.ruleBody),
            "",
            Line("return rule;")
        ),
        Line("}")
    ];
}


// bool isNotSummable(Declaration decl) {
//     return decl.members.length == 0 
//     && decl.ruleBody.alts.all!(a => 
//         a.length == 1 
//         && a[0].match!(
//             (RuleRef _) => true,
//             _ => false
//         )
//     ); 
// }


class CodeGenFailure: Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}


Line[] codeGenTypeSum(DeclarationSum decl) {
    return [
        Line(format!"alias %s = SumType!("(decl.name)),
        lineBlock( 
            decl.types[0..$-1].map!(
                (t) => t.name ~ ", "
            ).array
            ~ decl.types[$-1].name /// last element has no comma
        ),
        Line(");")
    ];
}

Line[] codeGenAlternate(Token[] alt, RuleRef spaceRule) {
    return alt[0..$-1].map!((t) =>
        codeGenSomeToken(t) ~
        codeGenRuleRef(spaceRule)
    )().join ~ codeGenSomeToken(alt[$-1]);
}


Line[] codeGenGroup(Group group) {
    if (group.alts.length == 1) {
        return codeGenAlternate(group.alts[0], group.spaceRule);
    }
    else
    if (group.alts.length > 1) {
        return [
            Line("source.tryAll!(typeof(this),"),
            lineBlock(
                group.alts.map!( (alt) => [
                    Line("(source) {"),
                    lineBlock(
                        codeGenAlternate(alt, group.spaceRule)
                    ),
                    Line("},"),
                ]).join
            ),
            Line(");")
        ];
    }
    else {
        throw new CodeGenFailure("A group cannot have zero alternates.");
    }
}


Line[] codeGenAttribute(Attribute attr) {  
    final switch (attr.category) {
        case AttributeType.Bare: {
            return [Line(
                format!"rule.%s = %s.parse(source);"(
                    attr.name, 
                    attr.type.name
                )
            )];
        }
        case AttributeType.Array:{
            return [Line(
                format!"rule.%s ~= %s.parse(source);"(
                    attr.name, 
                    attr.type.name
                )
            )];
        }
    }
}

Line[] codeGenRuleRef(RuleRef rule) {
    return [Line(rule.name~".parse(source);")];
}


Line[] codeGenMultiCapture(MultiCapture mc) {
    return [
        Line(format!"source.parseMultiCapture!(%s, %s, (source) {"
            (mc.low, mc.high)),
        lineBlock(
            codeGenSomeToken(mc.token)
        ),
        Line("})();")
    ];
}


Line[] codeGenVerbatim(VerbatimText vbt) {
    // import std.string: unes
    // writeln(vbt);
    return [
        Line("parseVerbatim!\""~vbt.str~"\"(source);")
    ];
}


Line[] codeGenCharCaptureGroup(CharCaptureGroup chCG) {
    return [Line(format!"parseCharCaptureGroup(source, %s);"(chCG.options ))];
}


Line[] codeGenSomeToken(Token token) {
    return token.match!(
        (Attribute    a) => codeGenAttribute(a),
        (RuleRef      a) => codeGenRuleRef(a),
        
        (VerbatimText a) => codeGenVerbatim(a),
        // (CharCaptureGroup a) => codeGenCharCaptureGroup(a),

        (MultiCapture a) => codeGenMultiCapture(a),


        (Group        a) => codeGenGroup(a),
        (_) {return assert(false, "'"
            ~ typeof(_).stringof
            ~ "' is not implemented in the final codegen.");
        }
    );
}



//+
unittest {
    import std.stdio;
    import std.conv;
    writeln("---- Unittest ", __FILE__, " 1 ----");

    auto func(){
        import parsing.gstatements;
        import symtable;
        InputSource source;
        
        string sourceText = 
//         `
// LoremIpsum = (
// 	" Lorem Ipsum "
// )

// Call {Expression caller, []Expression args} = (
//     caller "(" ?( args *("," args) ) ")"
// )
//         `;
        import("test/gram/dion.dart");
        source = new InputSourceString(sourceText);
        // source = new InputSourceString("Test : {Bungar, Dungar}");
        
        // return source.parseGrammar.to!string;
        
        Line[] lines = source.parseGrammar.map!(dec => 
            codeGenType(dec)
        ).join;
        
        // writeln(lines.linesToString);
        return lines.linesToString;
    }
pragma(msg, ",-,"~__FILE__);
    // pragma(msg, "...\n" ~ func());
pragma(msg, ",,,"~__FILE__);
    // mixin(func());
    writeln(func());
}// +/





/+ Note to self: When rules without arguments are themselves
 an argument, you need to capture the seek before and after
 in order to know the actual content.
 
 
 also maybe make rule parsing a static method
 
 
 what if the indent count was relative. Like an indent sobel filter. 


    Make Group spacing parameter take a Token and not a RuleRef
+/