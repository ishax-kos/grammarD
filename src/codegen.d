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
Line[] lineList(T)(T lines) {
    static if (is(ElementType!T == Line)) {
        return lines.array;
    }
    static if (is(ElementType!T == string)) {
        return lines.map!(a=>Line(a)).array;
    }
}

Line lineBlock(T)(T lines) {
    Line line;
    line.internal = Line.LineSum(lineList(lines));
    return line;
}

Line[] lineList(T...)(T items) {
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
    return lines;
}

Line lineBlock(T...)(T items) {
    Line line;
    line.internal = Line.LineSum(lineList(items));
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
    bool isBasic = (decl.members.length == 0);
    return [
        Line(format!"struct %s {"(decl.name)),
        lineBlock(
            () {
                if (isBasic) {
                    return [
                        Line(q{string capture = "";}),
                        // Line(q{alias capture this;})    
                    ];
                }
                else {
                    return decl.members.map!((Attribute attr) {
                        string fstr = attr.category == AttributeType.Array
                            ? "%s[] %s;"
                            : "%s %s;"
                        ;
                        string typeName = attr.type.name;
                        return Line(format(fstr,
                            typeName, 
                            attr.name)
                        );
                    }).array;
                }
            }()
        ),
        Line("}")
    ]
    ~ codeGenFactory(decl);
}


Line[] codeGenFactory(DeclarationStruct decl) {
    bool isBaseLevel = decl.members == [];
    return lineList(
        format!"%s _parse%s(InputSource source) {"
            (decl.name, decl.name),
        lineBlock(
            q{void delegate(InputSource) parseSpaceRule = (s){};},
            Line(format!"alias This = %s;"(decl.name)),
            codeGenLeftRecursion(),
            Line("This rule = This();"),
            "",
            (isBaseLevel 
                ? Line("InputSource start = source.save;")
                ~ codeGenGroup(decl.ruleBody)
                ~ Line("rule.capture = source.parseSince(start);")
                : codeGenGroup(decl.ruleBody)),
            "",
            Line("return rule;")
        ),
        Line("}")
    );
}

Line[] codeGenLeftRecursion() {
    return lineList(
        q{static size_t guard = -1;},
        q{if (guard == source.tell) throw new BadParse("Left recursion");},
        q{guard = source.tell; scope(exit) guard = -1;},
    );
}


Line[] codeGenSumFactory(DeclarationSum decl) {
    return lineList(
        Line(format!"%s _parse%s(InputSource source) {"
            (decl.name, decl.name)),
        lineBlock(
            // "import std.traits: PointerTarget;",
            // codeGenLeftRecursion(),
            "auto val = %s();".format(decl.name),
            "val.sum = new typeof(*val.sum)();",
            "*val.sum = source.tryAll!("~ decl.name ~".SumT,",
            lineBlock(
                decl.types.map!(ruleRef =>
                    "source => _parse" ~ ruleRef.name ~ "(source),"
                )
            ),
            ");",
            "return val;"
        ),
        "}"
    );
}

class CodeGenFailure: Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}


Line[] codeGenTypeSum(DeclarationSum decl) {
    return lineList(
        format!"struct %s {"(decl.name),
        lineBlock( 
            "alias SumT = SumType!(",
            lineBlock(
                decl.types[0..$].map!(
                    (t) => t.name ~ ", " 
                )
            ),
            Line(");"),
            "SumT* sum;"
        ),
        "string toString() {import std.conv; return (*sum).to!string;}",
        "}",
        "",
        codeGenSumFactory(decl)
    );
}

Line[] codeGenAlternate(Token[] alt) {
    Line[] ret;
    if (!alt.empty) while (true) {
        ret ~= codeGenSomeToken(alt.front);
        alt.popFront;
        if (alt.empty) break;
        ret ~= [Line("parseSpaceRule(source);")];
    }
    return ret;
}


Line[] codeGenGroup(Group group) {
    if (group.alts.length == 1) {
        return lineList(
            "parseSpaceRule = (InputSource source) {",
                lineBlock(codeGenSomeToken(group.spaceRule)),
            "};",
            codeGenAlternate(group.alts[0])
        );
    }
    else
    if (group.alts.length > 1) {
        return lineList(
            "parseSpaceRule = (InputSource source) {",
                lineBlock(codeGenSomeToken(group.spaceRule)),
            "};",
            Line("source.tryAll!(void,"),
            lineBlock(
                group.alts.map!( (alt) => [
                    Line("(source) {"),
                    lineBlock(
                        codeGenAlternate(alt)
                    ),
                    Line("},"),
                ]).join
            ),
            ");",
        );
    }
    else {
        throw new CodeGenFailure("A group cannot have zero alternates.");
    }
}


Line[] codeGenAttribute(Attribute attr) { 
    string fster = (){final switch (attr.category) {
        case AttributeType.Bare:
            return "rule.%s = _parse%s(source);";
        case AttributeType.Array:
            return "rule.%s ~= _parse%s(source);";
    }}();

    return [
        Line(
            format(fster,
                attr.name, 
                attr.type.name
            )
        )
    ];
}

Line[] codeGenRuleRef(RuleRef rule) {
    if (rule.name == "") return [];
    else {
        return [Line(
            format!"_parse%s(source);"
                (rule.name))
        ];
    }
}


Line[] codeGenMultiCapture(MultiCapture mc) {
    return [
        Line(format!"source.parseMultiCapture!(%s, %s, parseSpaceRule, delegate void(source) {"
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
        Line(format!"parseVerbatim!\"%s\"(source);"
            (vbt.str))
    ];
}


Line[] codeGenCharCaptureGroup(CharCaptureGroup chCG) {
    return [
        Line("if (0"),
        lineBlock(
            chCG.range.map!(a=>a.match!(
                (Fchar    ch1) => Line(
                    format!"|| source.front == '%s'"(
                        ch1)),
                (Fchar[2] ch2) => Line(
                    format!"|| (source.front >= '%s' && source.front <= '%s')"(
                        ch2[0], ch2[1]))
            )).array
        ),
        Line(") {source.popFront;}"),
        Line(q{else throw new BadParse("");})
    ];
}


auto interleave(R, T)(R range, T delimiter)  {
    T[] ret;
    while (true) {
        ret ~= range.front;
        if (!range.empty) break;
        ret ~= delimiter;
        range.popFront;
    }
    return ret;
}


Line[] codeGenWildCard() {
    return [Line("source.popFront;")];
}


Line[] codeGenSomeToken(Token token) {
    return token.match!(
        (Attribute    a) => codeGenAttribute(a),
        (RuleRef      a) => codeGenRuleRef(a),
        (VerbatimText a) => codeGenVerbatim(a),
        (CharCaptureGroup a) => codeGenCharCaptureGroup(a),
        (CharWildCard _) => codeGenWildCard(),
        (MultiCapture a) => codeGenMultiCapture(a),
        (Group        a) => codeGenGroup(a),
        (_) {return assert(false, "'" 
            ~ typeof(_).stringof
            ~ "' is not implemented in the final codegen.");
        }
    );
}


version(unittest) {
    auto testCodeGen(){
        import parsing.gstatements;
        import symtable;
        InputSource source;
        
        string sourceText = 
        // q{
        //     A = (
        //         "stuff"
        //     )
        //     B : 
        //      | A
        //      | Identifier

        //     C = (
        //         B | "..."
        //     )
        // };
        import("test/gram/dion.dart");
        source = new InputSourceString(sourceText);
        assert(source !is null);
        Line[] lines = source.parseGrammar.map!(dec => 
            codeGenType(dec)
        ).join(lineList("",""));
        return lines.linesToString;
    }
    
    // import parserhelpers;
    // import input;
    // import std.sumtype;
    // mixin(testCodeGen());
}



unittest {
    import std.stdio;
    import std.conv;
    writeln("---- Unittest ", __FILE__, " 1 ----");
    
    File testrun = File("test/testrun.d", "wb");

    testrun.writeln(lineList(
        "module testrun;",
        "import std.sumtype;",
        "import parserhelpers;",
        "import input;",
        "",
    ).linesToString);
    testrun.writeln(testCodeGen());
    testrun.writeln(lineList(
        "void main(string[] args) {",
        lineBlock(
            "import std.stdio;",
            `InputSource source = new InputSourceString(" foo()");`,
            "_parseWS(source);",
            "writeln(_parseExpression(source));",
            "readln();",
            `source = new InputSourceString(" bar()()");`,
            "_parseWS(source);",
            "writeln(_parseExpression(source));",
        ),
    "}", 
    ).linesToString);

    testrun.close;
 
    import std.process: execute;

    writeln(execute([`dmd`, `-gf`, `-I="./src"`, `-i`, `test/testrun.d`])[1]);
}


/++ To do: 
    Make Group spacing parameter take a Token and not a RuleRef
+/