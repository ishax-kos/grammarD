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
    if (source.current == '{') {
        rule.members = lexGTypeArgs(source);
    }
    
    consumeWS(source);
    if (source.current != '=') {
        throw new BadParse("No equal sign.");
    }
    source.popChar();
    
    rule.ruleBody = source.ruleFetchGroup(rule.members);
    
    
    source.foundDef(rule);
    
    return rule;
}

//+
T parseG(T:DeclarationSum)(InputSource source) {
    import parsing.grules;
    DeclarationSum rule = new DeclarationSum;
    rule.name = lexGName(source);


    consumeWS(source);
    if (source.current != ':') {
        throw new BadParse("No colon.");
    }
    source.popChar;
    consumeWS(source);
    if (source.current == '{') {
        source.popChar;
        consumeWS(source);
        if (source.current == '}') {
            source.popChar;
        }
        else while (true) {
            rule.types ~= source.ruleFetchRule();
            consumeWS(source);
            if (source.current == ',') {
                source.popChar;
            }
            else {
                if (source.current == '}') {
                    source.popChar;
                    break;
                }
                else {
                    throw new BadParse("Unclosed type list.");
                }
            }
        }
    }
    else {
        throw new BadParse("No open bracket.");
    }
    return rule;
}// +/



Attribute[] lexGTypeArgs(InputSource source) {
    import std.format;
    Attribute[] output;
    {
        source.consumeWS();
        char c = source.popChar();
        if (c == '{') {}
        else throw new BadParse(format!"%s, %s"(c, source.seek));
    }
    source.consumeWS();
    
    if (source.current == '}') {
        source.popChar();
    } 
    else while (true) {
        output ~= Attribute(
            source.foundCall(lexGType(source)),
            lexGName(source));

        source.consumeWS();
        char c = source.popChar;
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
    while (!source.end()) {
        if (source.current == '/') {
            source.parseComments();
        }
        else {
            source.tryAll!(Declaration,
                (a) => a.parseG!DeclarationSum,
                (a) => a.parseG!DeclarationStruct
            );
            // try {
            //     grammar ~= source.branch.parseG!DeclarationSum();
            // }
            // catch(BadParse) {
            //     grammar ~= source.branch.parseG!DeclarationStruct();
            // }
        }
        source.consumeWS();
    }
    
    foreach (item; [
        defaultLineBreak(),
        defaultWS(),
        defaultIdentifier(),
        defaultStringLiteral()
    ]) {
        import symtable;
        try {source.foundDef(item);}
        catch (SymbolAlreadyDefined) {}
    }
    
    foreach (key, entry; source.table) {
        if (entry is null) throw new Error("\""~key~"\" is not declared!");
    }
    
    return grammar;
}


DeclarationStruct defaultWS() {
    auto r = new DeclarationStruct();
    r.name = "WS";
    r.ruleBody = new Group(
        [[Token(new MultiCapture(
            Token(CharCaptureGroup(" \n\r")),
            1,0
        ))]], 
        RuleRef()
    );
    return r;
}

DeclarationStruct defaultLineBreak() {
    auto r = new DeclarationStruct();
    // auto m = new MultiCapture();
    r.name = "LineBreak";
    r.ruleBody = new Group(
        [
            [Token(VerbatimText("\r\n"))], 
            [Token(VerbatimText("\r"))], 
            [Token(VerbatimText("\n"))]
        ],
        RuleRef()
    );
    return r;
}

DeclarationStruct defaultIdentifier() {
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


DeclarationStruct defaultStringLiteral() {
    auto r = new DeclarationStruct();
    r.name = "StringLiteral";
    r.ruleBody = new Group(
        [[
            Token(VerbatimText("\"")),
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
            Token(VerbatimText("\""))
        ]],
        RuleRef()
    );
    return r;
}


unittest {
// pragma(msg,{

    import std.stdio;
    pragma(msg,"---- Unittest ", __FILE__, " ----");
    string sourceText = import("test/gram/dion.dart");
    InputSource source = new InputSourceFile("test/gram/dion.dart");
    parseGrammar(source);

    // return "source.table";


// }());

    
}