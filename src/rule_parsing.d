module rule_parsing;

import nodes;
import input;
// import std.uni;
import std.stdio : write, writeln, writef, writefln;
import std.sumtype;
import std.conv;
import std.format;


Token getToken(InputSource source, Property[] args) {
    Token token;
    // writeln(source.seek);
    source.consumeWS();
    typeof(source) branch = source;
    // auto seek = source.seekl
    Exception[] earr;
    try {
        branch = source.branch();
        token = Token(branch.ruleFetchSemicolon());
    }
    catch (BadParse e) try { earr~=e;
        branch = source.branch();
        token = Token(branch.ruleFetchProperty(args));
    }
    catch (BadParse e) try { earr~=e;
        branch = source.branch();
        token = Token(branch.ruleFetchGroup(args));
    }
    catch (BadParse e) try { earr~=e;
        branch = source.branch();
        token = Token(branch.ruleFetchRule([]));
    }
    catch (BadParse e) try { earr~=e;
        branch = source.branch();
        token = Token(branch.ruleFetchStringLiteral());
    }
    catch (BadParse e) try { earr~=e;
        branch = source.branch();
        token = Token(branch.ruleFetchNumberLiteral());
    }
    catch (BadParse e) try { earr~=e;
        branch = source.branch();
        token = Token(branch.ruleFetchMultiStar(args));
    }
    catch (BadParse e) try { earr~=e;
        branch = source.branch();
        token = Token(branch.ruleFetchMultiQM(args));
    }
    // catch (BadParse e) try { earr~=e;
    //     branch = source.branch();
    //     token = Token(RightOp(branch.ruleFetchSymbol([
            
    //     ])));
    // }
    catch (BadParse e) { earr~=e; throw new Error(earr.format!"%(\n%s\n%)");}
    // write(source.seek, " ");
    source.seek = branch.seek;
    // write(source.seek, " ");
    // writeln(token);
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


Property ruleFetchProperty(InputSource source, Property[] args) {
    
    string name = source.lexGName();
    foreach (arg; args) {
        if (arg.name == name) {
            return arg;
        }
    }
    throw new BadParse("");
}


Rule ruleFetchRule(InputSource source, Rule[] rules) {
    
    ///search all rules for rule
    Rule rule = new Rule();
    rule.name = lexGName(source);
    return rule;
}


Semicolon ruleFetchSemicolon(InputSource source) {
    
    lexGChar(source, ';');
    return Semicolon();
}


Parentheses ruleFetchParentheses(InputSource source) {
    
    source.consumeWS();
    char paren = source.popChar();
    if (paren == '(') return Parentheses.open; 
    // while (source.current != ')') {
    //     getToken(source, args);
    // }

    if (paren == ')') return Parentheses.closed;
    else throw new BadParse("Not a parenthesis.");
}


MultiCapture ruleFetchMultiStar(InputSource source, Property[] args) {
    
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


MultiCapture ruleFetchMultiQM(InputSource source, Property[] args) {
    
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


Group ruleFetchGroup(InputSource source, Property[] args) {
    
    consumeWS(source);
    if (source.current != '(') throw new BadParse("");
    source.popChar();
    Group g = new Group();
    uint alt = 0;
    while (true) {
        consumeWS(source);
            // if (source.ruleFetchParentheses() == Parentheses.closed)
            //     break;
            // else throw new BadParse("");
        if (source.current == ')') break;
        if (source.current == '|') {g.alts.length += 1; alt += 1;}
        g.alts[alt] ~= getToken(source, args);
        writeln(g.alts[alt]);
    }
    source.popChar;
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
    auto source = new InputSourceString(`(a *0b (c) )`);
    Property[] args;
    writeln(ruleFetchGroup(source, args));

    /+
        Rule node = source.parseGRule();
        writeln(node.name);
        writeln(node.args);
        writeln(node.ruleBody);
        // writeln(node.ruleBody[2].match!(
        //     (MultiCapture m) => (m.token).match!(
        //         (Group g) => g.alts[0][3].match!(
        //             (MultiCapture m) => (m.token).match!(
        //                 (Group g) => g.alts[0][3].match!(
        //                     (_) => typeof(_).stringof
        //                 ),
        //                 (_) => ""
        //             ),
        //             (_) => ""
        //         ),
        //         (_) => ""
        //     ),
        //     (_) => ""
    // )); +/
}