module parsing.grules;

import nodes;
import input;
import parsing.lex;

import std.stdio : write, writeln, writef, writefln;
import std.sumtype;
import std.conv;
import std.format;



Token getToken(InputSource source, Attribute[] args) {
    import std.functional;
    return tryAll!(Token, 
        (a) => a.ruleFetchProperty(args),
        (a) => a.ruleFetchWildCard(),
        (a) => a.ruleFetchGroup(args),
        (a) => a.ruleFetchRule(),
        (a) => a.ruleFetchVerbatimText(),
        (a) => a.ruleFetchNumberLiteral(),
        (a) => a.ruleFetchCharCaptureGroup(),
        (a) => a.ruleFetchMultiStar(args),
        (a) => a.ruleFetchMultiQM(args),
    )(source);
}


CharWildCard ruleFetchWildCard(InputSource source) {
    source.consumeWS();
    if (source.front() != '.') throw new BadParse("");
    source.popFront;
    return CharWildCard();
}


VerbatimText ruleFetchVerbatimText(InputSource source) {
    
    source.consumeWS();
    string output;
    if (source.front != '"')
        throw new BadParse(format!"\" not found. Found %s instead."(source.front));
    else 
        source.popFront;
    while (true) {
        if (source.front() == '\\') {
            output ~= source.front(); source.popFront();
        }
        else {
            if (source.front() == '"') {
                source.popFront();
                break;
            }
        }
        output ~= source.front(); source.popFront();
    }
    if (output == "") throw new Error("");
    return VerbatimText(output);
}


CharCaptureGroup ruleFetchCharCaptureGroup(InputSource source) {
    source.consumeWS();
    char[] chars;
    if (source.front != '\'') {
        throw new BadParse(format!"\" not found. Found %s instead."(source.front));
    }
    source.popFront;
    while (true) {
        if (source.front() == '\\') {
            chars ~= source.front(); source.popFront();
            if (source.front() == '\'')
                chars ~= source.front(); source.popFront();
        }
        else {
            if (source.front() == '\'') {
                source.popFront();
                break;
            }
            chars ~= source.front(); source.popFront();
        }
    }
    // char[][] charClusters = chars.split("..");
    // foreach (i; 0..charClusters.length-1) {
    //     CharRange(charClusters[i][$-1], charClusters[i+1][0]);
    // }
    return CharCaptureGroup(chars.idup);
}



NumberLiteral ruleFetchNumberLiteral(InputSource source) {
    
    import std.ascii;
    import std.conv : parse;
    source.consumeWS();
    string output;
    if (source.front.isDigit) {
        output ~= source.front(); 
        source.popFront();
    }
    else throw new BadParse("not a numeric literal");

    while (true) {
        if (source.front.isDigit) {
            output ~= source.front(); 
            source.popFront();
        }
        else if (source.front == '_') {}
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
    return source.foundCall(lexGName(source));
}


MultiCapture ruleFetchMultiStar(InputSource source, Attribute[] args) {
    
    consumeWS(source);
    if (source.front != '*') throw new BadParse("");
    source.popFront;
    MultiCapture mc = new MultiCapture();

    try {mc.low  = ruleFetchNumberLiteral(source).num;}
    catch(BadParse) {mc.low  = 0;}

    try {mc.high = ruleFetchNumberLiteral(source).num;}
    catch(BadParse) {mc.high = 0;}
    consumeWS(source);
    mc.token = getToken(source, args);

    return mc;
}


MultiCapture ruleFetchMultiQM(InputSource source, Attribute[] args) {
    
    consumeWS(source);
    if (source.front != '?') throw new BadParse("");
    source.popFront;
    MultiCapture mc = new MultiCapture();
    mc.high = 1;
    consumeWS(source);
    mc.token = getToken(source, args);
    return mc;
}


string ruleFetchSymbol(InputSource source, string[] symbols) {
    
    source.consumeWS();
  
    CONT: foreach (symbol; symbols) {
        auto branch = source.save();
        foreach (symbolChar; symbol) {
            if (branch.front() != symbolChar) {
                source.popFront;
                continue CONT;
            }
            else source.popFront;
        }
        source.load(branch);
        return symbol;
    }
    throw new BadParse("");
}


Group ruleFetchGroup(InputSource source, Attribute[] args) {
    import symtable;
    
    consumeWS(source);

    RuleRef spaceRule = source.foundCall("WS");

    if (source.front == '~') {
        source.popFront(); consumeWS(source);
        if (source.front == '(') {
            // writeln("fpfgdf");
            source.popFront();
            spaceRule = source.foundCall("");
        }
        else {
            spaceRule = source.ruleFetchRule();
            if (source.front() != '(') throw new BadParse("");
            else source.popFront;
        }
    }
    else if (source.front() != '(') throw new BadParse("");
    else source.popFront;

    Token[][] alternates;
    Token[] group;
    while (true) {
        consumeWS(source);
            // if (source.ruleFetchParentheses() == Parentheses.closed)
            //     break;
            // else throw new BadParse("");
        if (source.front == ')') {
            alternates ~= group;
            source.popFront;
            break;
        }
        else
        if (source.front == '|') {
            alternates ~= group;
            source.popFront;
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
