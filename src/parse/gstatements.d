module parse.gstatements;


import nodes;
import input;
import symtable;

import std.ascii;

import std.stdio;
import std.conv;


T parseG(T:Declaration)(InputSource source) {
    import parse.grules;
    Declaration rule = new Declaration;
    rule.name = lexGName(source);
    rule.members = lexGTypeArgs(source);
    
    consumeWS(source);
    if (source.current != '=')
        throw new BadParse("");
    source.popChar();
    rule.ruleBody = source.ruleFetchGroup(rule.members);
    // rule.ruleBody;
    // while (true) {
    //     Token token = getToken(source, rule.args);
    //     if (token.match!(
    //         (Semicolon _) => true,
    //         (_) {rule.ruleBody ~= token; return false;}
    //     )) break;
    // }
    foundDef(rule);
    
    return rule;
}


// T parseG(T:TypeDeclaration)(InputSource source) {
//     lexGChar(source, ':');


// }



string lexGName(InputSource source) {
    string output;
    source.consumeWS();
    {
        if (source.current.isAlpha)
            output ~= source.current;
        else {
            // writeln("(",source.current,")",source.seek);
            throw new BadParse(source.seek.to!string);
        }
        source.popChar();
    }
    
    while (true) {
        char c = source.current;
        if (c.isAlphaNum || c == '_') {
            output ~= c;
            source.popChar();
        }
        else break;
    }
    return output;
}


string lexGType(InputSource source) {
    string name;
    import std.conv;

    source.consumeWS();
    if (source.current == '[') {
        source.popChar(); source.consumeWS();
        if (source.current != ']')
            throw new BadParse(source.seek.to!string);
        else
            source.popChar(); source.consumeWS();
    }
    // while (true) {
    //     source.consumeWS();
    //     if (source.current != '[') break;
    //     source.popChar();
    //     source.consumeWS();
    //     if (source.popChar() != ']')
    //         throw new BadParse("");
    //     name ~= "[]";
    // }

    name ~= lexGName(source);
    

    return name;
}


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
            foundCall(lexGType(source)),
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


void lexGChar(InputSource source, char ch) {
    consumeWS(source);
    if (source.current == ch) {
        source.popChar();
    }
    else throw new BadParse("");
}


bool parseComments(InputSource source) {
    consumeWS(source);
    if (source.current == '/') {
        source.popChar();
        if (source.current == '*') {
            source.popChar();
            while (1) {
                if (source.end) break;
                parseComments(source);
                if (source.popChar() == '*') {
                    if (source.popChar() == '/') {
                        break;
                    }
                }
            }
            return true;
        }
        else source.seek(source.seek-1);
    }
    return false;
}


Declaration[] parseGrammar(InputSource source) {
    table.clear;
    foundDef(new EmptyRule());
    Declaration[] grammar;
    source.consumeWS();
    while (!source.end()) {
        if (source.current == '/')
            source.parseComments();
        else
            grammar ~= source.parseG!Declaration();
        source.consumeWS();
    }

    foreach (item; [
        defaultLineBreak(),
        defaultWS(),
        defaultIdentifier(),
        defaultStringLiteral()
    ]) {
        import symtable;
        try foundDef(item);
        catch (SymbolAlreadyDefined) {}
    }
    
    foreach (key, entry; table) {
        if (entry is null) throw new Error("\""~key~"\" is not declared!");
    }

    return grammar;
}


Declaration defaultWS() {
    auto r = new Declaration();
    r.name = "WS";
    r.ruleBody = new Group(
        [[Token(new MultiCapture(
            Token(CharCaptureGroup(" \n\r")),
            1,0
        ))]], 
        RuleRef("")
    );
    return r;
}

Declaration defaultLineBreak() {
    auto r = new Declaration();
    // auto m = new MultiCapture();
    r.name = "LineBreak";
    r.ruleBody = new Group(
        [
            [Token(StringLiteral("\r\n"))], 
            [Token(StringLiteral("\r"))], 
            [Token(StringLiteral("\n"))]
        ],
        RuleRef("")
    );
    return r;
}

Declaration defaultIdentifier() {
    auto r = new Declaration();
    r.name = "Identifier";
    r.ruleBody = new Group(
        [[
            Token(CharCaptureGroup("a..zA..Z_")),
            Token(new MultiCapture(
                Token(CharCaptureGroup("a..zA..Z0..9_")),
                0, 0
            ))
        ]],
        RuleRef("")
    );
    return r;
}


Declaration defaultStringLiteral() {
    auto r = new Declaration();
    r.name = "StringLiteral";
    r.ruleBody = new Group(
        [[
            Token(StringLiteral("\"")),
            Token(new MultiCapture(
                Token(new Group(
                    [
                        [Token(StringLiteral("\\\""))], 
                        [Token(CharWildCard())]
                    ],
                    RuleRef("")
                )),
                0, 0
            )),
            Token(StringLiteral("\""))
        ]],
        RuleRef("")
    );
    return r;
}


unittest
{
    import std.stdio;
    writeln("---- Unittest ", __FILE__, " ----");


    parseGrammar(new InputSourceFile("gram/dion.gram"));

    writeln(table);
}