module parse.grules;

import nodes;
import input;
import parse.gstatements;
// import std.uni;
import std.stdio : write, writeln, writef, writefln;
import std.sumtype;
import std.conv;
import std.format;


Token getToken(InputSource source, Attribute[] args) {
    Token token;
    source.consumeWS();
    typeof(source) branch = source;
    Exception[] earr;
    // bool done;

    static foreach (expr; [
        () => Token(branch.ruleFetchProperty(args)),
        () => Token(branch.ruleFetchGroup(args)),
        () => Token(branch.ruleFetchRule()),
        () => Token(branch.ruleFetchStringLiteral()),
        () => Token(branch.ruleFetchNumberLiteral()),
        () => Token(branch.ruleFetchMultiStar(args)),
        () => Token(branch.ruleFetchMultiQM(args))
    ]) {
        try {
            branch = source.branch();
            token = expr();
            goto Done;
        }
        catch (BadParse e) earr~=e;
    }
    throw new Error(earr.format!"%(\n%s\n%)");

    Done:
    source.seek = branch.seek;
    return token;
}


StringLiteral ruleFetchStringLiteral(InputSource source) {
    
    source.consumeWS();
    string output;
    if (source.popChar != '"')
        throw new BadParse("\" not found. Found "~source.current~" instead.");
    while (true) {
        if (source.current() == '\\') {
            source.popChar();
            if (source.current() == '"')
                output ~= source.popChar();
        }
        else {
            if (source.current() == '"') {
                source.popChar();
                break;
            }
            output ~= source.popChar();
        }
    }
    return StringLiteral(output);
}


NumberLiteral ruleFetchNumberLiteral(InputSource source) {
    
    import std.ascii;
    import std.conv : parse;
    source.consumeWS();
    string output;
    if (source.current.isDigit)
        output ~= source.popChar();
    else throw new BadParse("not a numeric literal");

    while (true) {
        if (source.current.isDigit)
            output ~= source.popChar();
        else if (source.current == '_') {}
        else break;
    }
    return NumberLiteral(output.parse!uint);
}


Attribute ruleFetchProperty(InputSource source, Attribute[] args) {
    
    string name = source.lexGName();
    foreach (arg; args) {
        if (arg.name == name) {
            return arg;
        }
    }
    throw new BadParse("");
}


Declaration ruleFetchRule(InputSource source) {
    import symtable;
    return foundCall(lexGName(source));
}


MultiCapture ruleFetchMultiStar(InputSource source, Attribute[] args) {
    
    consumeWS(source);
    if (source.popChar != '*') throw new BadParse("");
    MultiCapture mc = new MultiCapture();
    mc.low = ruleFetchNumberLiteral(source).num;
    consumeWS(source);
    try {mc.high = ruleFetchNumberLiteral(source).num;}
    catch(BadParse) {mc.high = 0;}
    
    mc.token = getToken(source, args);

    return mc;
}


MultiCapture ruleFetchMultiQM(InputSource source, Attribute[] args) {
    
    consumeWS(source);
    if (source.popChar != '?') throw new BadParse("");
    MultiCapture mc = new MultiCapture();
    mc.high = 1;
    mc.token = getToken(source, args);
    return mc;
}


string ruleFetchSymbol(InputSource source, string[] symbols) {
    
    source.consumeWS();
  
    CONT: foreach (symbol; symbols) {
        auto branch = source.branch();
        foreach (symbolChar; symbol) {
            if (branch.popChar() != symbolChar) continue CONT;
        }
        source.seek = branch.seek;
        return symbol;
    }
    throw new BadParse("");
}


Group ruleFetchGroup(InputSource source, Attribute[] args) {
    
    consumeWS(source);
    if (source.current != '(') throw new BadParse("");
    source.popChar();
    Token[][] alternates;
    Token[] group;
    while (true) {
        consumeWS(source);
            // if (source.ruleFetchParentheses() == Parentheses.closed)
            //     break;
            // else throw new BadParse("");
        if (source.current == ')') {
            alternates ~= group;
            break;
        }
        if (source.current == '|') {
            alternates ~= group;
            group = [];
        }
        group ~= getToken(source, args);
    }
    source.popChar;
    return new Group(alternates);
}



unittest
{
    auto source = new InputSourceString(`_`);
    assert(source.current == source.popChar());
    assert(source.current == source.popChar());
}

unittest
{
    auto source = new InputSourceString(` 123 456`);
    assert(source.ruleFetchSymbol(["xyz", "123"]) == "123");
    assert(source.ruleFetchSymbol(["l", "456"]) == "456");
}



unittest
{
    import std.conv;
    writeln("---- Unittest ", __FILE__, " ----");
    // auto source = new InputSourceString(`"foobar"`);
    auto source = new InputSourceString(`(caller "(" ?( args * 0 ("," args) ) ")")`);
    Attribute[] args;
    writeln(
        ruleFetchGroup(source, args)
    );
}