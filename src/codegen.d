module codegen;

import input;
import nodes;

import std.format;
import std.array;
import std.algorithm: map, each, fold, all;
import std.functional: curry;
import std.sumtype;


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


string linesToString(Line[] lines) {
    static uint indentCount;
    return lines.map!(
        (Line line) {
            return line.internal.match!(
                (string str) => " ".replicate(4*indentCount) ~ str,
                (Line[] lines2) {
                    indentCount++; scope(exit) indentCount--;
                    return lines2.linesToString();
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
            codeGenGroup(decl.ruleBody),
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
    // Token[] alt = group.alts[index];
    /// Individual token captures
    return alt.map!((t) =>
        [Line("codeGenSomeToken(t)")]
    )().array.join(
        Line("codeGenRuleRef(spaceRule)")
    );
    // return output;
}


Line[] codeGenGroup(Group group) {
    if (group.alts.length == 1) {
        return codeGenAlternate(group.alts[0], group.spaceRule);
    }
    else
    if (group.alts.length > 1) {
        return group.alts.map!( (alt) => [
            Line("try {"),
            lineBlock(
                codeGenAlternate(alt, group.spaceRule)
            ),
            Line("}")
        ]).join;
    }
    else {
        throw new CodeGenFailure("A group cannot have zero alternates.");
    }
}


// Line[] codeGenAttribute(Attribute attr) {  
//     lines ~= Line(
//         format!"rule.%s = %s.parse(source);"(
//             attr.name, 
//             attr.type.name
//         );
// }

// Line[] codeGenRuleRef(RuleRef rule) {
//     lines ~= Line(rule.name~".parse(source);";
// }

// Line[] codeGenMultiCapture(MultiCapture mc) {
//     Line[] lines;
//     lines ~= Line(format!
//         "source.parseMultiCapture(%s, %s, (source) {"
//         (mc.low, mc.high);
//     { output.indentCount++; scope(exit) output.indentCount--;
//         output.codeGenSomeToken(mc.token);
//     }
//    lines ~= Line("}");
//     // output;
// }

// Line[] codeGenVerbatim(VerbatimText vbt) {
//     lines ~= Line(
//         "source.parseVerbatim!\""~vbt.str~"\"();";
// }

// Line[] codeGenSomeToken(Token token) {
//     token.match!(
//         (Attribute    a)=>output.codeGenAttribute(a),
//         (RuleRef      a)=>output.codeGenRuleRef(a),
//         (MultiCapture a)=>output.codeGenMultiCapture(a),
//         (VerbatimText a)=>output.codeGenVerbatim(a),
//         (_) {return assert(false, "'"
//             ~ typeof(_).stringof
//             ~ "' is not implemented in the final codegen.");
//         }
//     );
// }


unittest {
    import std.stdio;
    writeln("---- Unittest ", __FILE__, " 1 ----");

    import parsing.gstatements;
    import symtable;
    InputSource source;

    // source = new InputSourceString("Bungar {} ");
    // source.parseG!Declaration;
    // Output output = new Output();
    
    source = new InputSourceString(`
        LineBreak = ~(
            "\r\n" | "\r" | "\n"
        )
    `);
    // source = new InputSourceString("Test : {Bungar, Dungar}");
    
    
    auto tree = source.parseG!DeclarationStruct;
    
    writeln(tree);
    
    Line[] lines = codeGenType(tree);
    
    writeln(lines);
    writeln(lines.linesToString);
}
// unittest {
//     import std.stdio;
//     writeln("---- Unittest ", __FILE__, " 2 ----");

//     import parsing.gstatements;
//     import symtable;
//     InputSource source;

//     // Output output = new Output();
//     // source = new InputSourceString("Bungar {} ");
//     // source.parseG!Declaration;

//     // pragma (msg,
//     enum mod = (){
//         InputSource src = new InputSourceString(`
//             Foo {} = (
//                 *0"+-="
//             )

//             LoremIpsum {Foo feh} = (
//                 " Lorem Ipsum " feh
//             )

//         `);
//         Output output = new Output();

//        lines ~= Line("import parserhelpers;");

//         [
//             src.parseG!Declaration,
//             src.parseG!Declaration
//         ].map!(e => output.codeGenType(e));
//         string res = output.toString;
//         // writeln(res);
//         return res;
//     }();
//     pragma(msg, mod);
//     mixin(mod);
//     source = new InputSourceString(" Lorem Ipsum +-=");
    
//     writeln(LoremIpsum.parse(source));
// }


/+ Note to self: When rules without arguments are themselves
 an argument, you need to capture the seek before and after
 in order to know the actual content.
 
 
 also maybe make rule parsing a static method
 
 
 what if the indent count was relative. Like an indent sobel filter. 


    Make Group spacing parameter take a Token and not a RuleRef
+/