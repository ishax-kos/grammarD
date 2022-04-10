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
    // rule.args = lexGArgs(source);
    
    consumeWS(source);
    if (source.current != '=')
        throw new BadParse("");
    source.popChar();
    rule.ruleBody = source.ruleFetchGroup([]);
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


T parseG(T:TypeDeclaration)(InputSource source) {
    lexGChar(source, ':');


}



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

    source.consumeWS();
    if (source.current != '[') {
        source.consumeWS();
        if (source.popChar() != ']')
            throw new BadParse("");
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
    Attribute[] output;
    {
        source.consumeWS();
        char c = source.popChar();
        if (c == '{') {}
        else throw new BadParse([c]);
    }
    
    while (true) { 
        output ~= Attribute(
            foundCall(lexGType(source)),
            lexGName(source));

        source.consumeWS();
        char c = source.current;
        if (c == ',') {source.popChar();}
        else if (c == '}') {
            source.popChar();
            break;
        }
        else throw new BadParse("");
    }
    return output;
}


void lexGChar(InputSource source, char ch) {
    consumeWS(source);
    if (source.current == ch) {
        source.popChar();
    }
    else throw new BadParse("");
}


unittest
{
    import std.stdio;
    writeln("---- Unittest ", __FILE__, " ----");

    table.clear;

    auto source = new InputSourceString(
`Rule1 = (
    Rule2 ?(":" "blah")
)`);
    source.parseG!Declaration();
    writeln(table);
    source = new InputSourceString(
`Rule2 = 
    (Fuck *0"B")
`
    );


    source.parseG!Declaration();
    writeln(table);

}