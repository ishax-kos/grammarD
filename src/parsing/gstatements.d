module parsing.gstatements;


import nodes;
import input;
import symtable;
import parsing.lex;

import std.stdio;
import std.conv;


T parseG(T:DeclarationStruct)(InputSource source) {
    import parsing.grules;
    DeclarationStruct rule = new DeclarationStruct;
    
    rule.name = lexGName(source);

    
    consumeWS(source);

    if (source.front == '{') {
        rule.members = lexGTypeArgs(source);
    }
    
    consumeWS(source);

    if (source.front != '=') {
        throw new BadParse("No equal sign", source);
    }
    source.popFront();
    
    consumeWS(source);

    rule.ruleBody = source.ruleFetchGroup(rule.members);
    return rule;
}

//+
T parseG(T:DeclarationSum)(InputSource source) {
    import parsing.grules;
    DeclarationSum rule = new DeclarationSum;
    rule.name = lexGName(source);


    consumeWS(source);
    if (source.front != ':') {
        throw new BadParse("No colon", source);
    } else {
        source.popFront;
        consumeWS(source);
    }
    // if (source.front == '{') {
    //     source.popFront;
    //     consumeWS(source);
    //     if (source.front == '}') {
    //         source.popFront;
    //     }
        // else 
    while (source.front == '|') {
        source.popFront;
        consumeWS(source);
        rule.types ~= source.ruleFetchRule();
        consumeWS(source);
    }
    return rule;
}// +/



Attribute[] lexGTypeArgs(InputSource source) {
    import std.format;
    Attribute[] output;
    {
        source.consumeWS();
        dchar c = source.front;
        source.popFront();
        if (c == '{') {}
        else throw new BadParse(format!"%s, %s"(c, source.tell));
    }
    source.consumeWS();
    
    if (source.front == '}') {
        source.popFront();
    } 
    else while (true) {
        Attribute attr = lexAttribute(source);
        output ~= attr;

        source.consumeWS();
        dchar c = source.front;
        source.popFront;
        if (c == ',') {
            source.consumeWS();
        }
        else if (c == '}') {
            break;
        }
        else throw new BadParse("");
    }
    // writeln(source.seek);
    return output;
}



Declaration[] parseGrammar(InputSource source) {
    source.foundDef(new EmptyRule());
    Declaration[] grammar;
    source.consumeWS();
    while (!source.empty()) {
        if (source.front == '/') {
            source.parseComments();
        }
        else {
            grammar ~= source.foundDef(source.tryAll!(Declaration,
                (a) => a.parseG!DeclarationSum,
                (a) => a.parseG!DeclarationStruct
            ));
        }
        source.consumeWS();
    }
    
    Declaration[] defaults = [
        defaultLineBreak(),
        defaultWS(),
        defaultIdentifier(),
        defaultStringLiteral()
    ];
    foreach (item; defaults) {
        import symtable;
        if (item.name in source.table) {
            try {
                grammar = source.foundDef(item) ~ grammar;
            }
            catch (SymbolAlreadyDefined) {}
        }
        
    }
    
    foreach (key, entry; source.table) {
        assert (entry !is null, "\""~key~"\" is not declared!");
    }
    return grammar;
}


Declaration defaultWS() {
    auto r = new DeclarationStruct();
    r.name = "WS";
    r.ruleBody = new Group(
        [[Token(new MultiCapture(
            Token(CharCaptureGroup(" \\n\\r")),
            1,0
        ))]], 
        RuleRef()
    );
    return r;
}

Declaration defaultLineBreak() {
    auto r = new DeclarationStruct();
    // auto m = new MultiCapture();
    r.name = "LineBreak";
    r.ruleBody = new Group(
        [
            [Token(VerbatimText("\\r\\n"))], 
            [Token(VerbatimText("\\r"))], 
            [Token(VerbatimText("\\n"))]
        ],
        RuleRef()
    );
    return r;
}

Declaration defaultIdentifier() {
    auto r = new DeclarationStruct();
    r.name = "Identifier";
    r.ruleBody = new Group(
        [[
            Token(CharCaptureGroup("a..zA..Z_")),
            Token(new MultiCapture(
                Token(CharCaptureGroup("a..zA..Z0..9_")),
                0, 0
            ))
        ]],
        RuleRef()
    );
    return r;
}


Declaration defaultStringLiteral() {
    auto r = new DeclarationStruct();
    r.name = "StringLiteral";
    r.ruleBody = new Group(
        [[
            Token(VerbatimText("\\\"")),
            Token(new MultiCapture(
                Token(new Group(
                    [
                        [Token(VerbatimText("\\\""))], 
                        [Token(CharWildCard())]
                    ],
                    RuleRef()
                )),
                0, 0
            )),
            Token(VerbatimText("\\\""))
        ]],
        RuleRef()
    );
    return r;
}

// /+
unittest {

// pragma(msg,{

    import std.stdio;
    writeln("---- Unittest ", __FILE__, " ----");
    string sourceText = import("test/gram/dion.dart");
    InputSource source = new InputSourceString(`
        Variable = (Identifier)
    `);
    writeln(source.table);
    // source.consumeWS();
    // writeln(parseG!DeclarationStruct(source));
    writeln(parseGrammar(source));
    // return "source.table";


// }());

    
}
// +/