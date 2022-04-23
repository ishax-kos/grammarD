module parsing.lex;

import input;

import std.ascii;
import std.conv;


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


void consumeWS(InputSource source) {
    while (source.current.isWhite()) {
        source.popChar();
    }
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


class BadParse : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}


import std.traits;
import std.meta;
pragma(inline)
T tryAll(T, C...)(InputSource source)
// if (is(C : T delegate(InputSource))) 
{
    import std.format;
    import std.stdio;

    consumeWS(source);
    T output;
    InputSource branch = source;
    Exception[] earr;

    static foreach (expr; C) {
        try {
            branch = source.branch();
            output = cast(T) expr(branch);
            goto Done;
        }
        catch (BadParse e) earr~=e;
    }
    throw new Error(earr.format!"%(%s\n\n%)\n\nFinal Error Stack");

    Done:
    source.seek = branch.seek;
    return output;
}