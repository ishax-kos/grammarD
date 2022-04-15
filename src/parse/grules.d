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
        () => Token(branch.ruleFetchWildCard()),
        () => Token(branch.ruleFetchGroup(args)),
        () => Token(branch.ruleFetchRule()),
        () => Token(branch.ruleFetchStringLiteral()),
        () => Token(branch.ruleFetchNumberLiteral()),
        () => Token(branch.ruleFetchCharCaptureGroup()),
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
    throw new Error(earr.format!"%(%s\n\n%)\n\nFinal Error Stack");

    Done:
    source.seek = branch.seek;
    return token;
}


CharWildCard ruleFetchWildCard(InputSource source) {
    source.consumeWS();
    if (source.popChar() != '.') throw new BadParse("");
    return CharWildCard();
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


CharCaptureGroup ruleFetchCharCaptureGroup(InputSource source) {
    
    source.consumeWS();
    string chars;
    if (source.popChar != '\'')
        throw new BadParse("\' not found. Found "~source.current~" instead.");
    while (true) {
        if (source.current() == '\\') {
            source.popChar();
            if (source.current() == '\'')
                chars ~= source.popChar();
        }
        else {
            if (source.current() == '\'') {
                source.popChar();
                break;
            }
            chars ~= source.popChar();
        }
    }
    return CharCaptureGroup(chars);
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


RuleRef ruleFetchRule(InputSource source) {
    import symtable;
    return foundCall(lexGName(source));
}


MultiCapture ruleFetchMultiStar(InputSource source, Attribute[] args) {
    
    consumeWS(source);
    if (source.popChar != '*') throw new BadParse("");
    MultiCapture mc = new MultiCapture();

    try {mc.low  = ruleFetchNumberLiteral(source).num;}
    catch(BadParse) {mc.low  = 0;}

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
    import symtable;
    
    consumeWS(source);

    RuleRef spaceRule = foundCall("WS");

    if (source.current == '~') {
        source.popChar(); consumeWS(source);
        if (source.current == '(') {
            // writeln("fpfgdf");
            source.popChar();
            spaceRule = foundCall("");
        }
        else {
            spaceRule = source.ruleFetchRule();
            if (source.popChar() != '(') throw new BadParse("");
        }
    }
    else if (source.popChar() != '(') throw new BadParse("");

    Token[][] alternates;
    Token[] group;
    while (true) {
        consumeWS(source);
            // if (source.ruleFetchParentheses() == Parentheses.closed)
            //     break;
            // else throw new BadParse("");
        if (source.current == ')') {
            alternates ~= group;
            source.popChar;
            break;
        }
        else
        if (source.current == '|') {
            alternates ~= group;
            source.popChar;
            group = [];
        }
        else {group ~= getToken(source, args);}
        
    }
    Group g = new Group();
    g.alts = alternates;
    g.spaceRule = spaceRule;
    return g;
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
    auto source = new InputSourceString(`(a | b | c)`);

    Attribute[] args;
    writeln(1);
    writeln(
        ruleFetchGroup(source, args)
    );
}