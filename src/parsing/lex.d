module parsing.lex;

import input;
import nodes;

import std.ascii;
import std.conv;
public import parserhelpers;

import std.stdio;

void lexGChar(InputSource source, dchar ch) {
    consumeWS(source);
    if (source.front == ch) {
        source.popFront();
    }
    else throw new BadParse("");
}


void parseComments(InputSource source) {
    auto branch = source.save();
    if ((){
        if (branch.front != '/') return false;
        branch.popFront();
        if (branch.front != '*') return false;
        branch.popFront();
        while (1) {
            if (branch.empty) break;
            parseComments(branch);
            if (branch.front() == '*') {
                branch.popFront;
                if (branch.front() == '/') {
                    branch.popFront;
                    break;
                } else branch.popFront;
            }
            else 
                branch.popFront;
        }
        return true;
    }()) {
        source.load(branch);
    }
    else {}
}


void consumeWS(InputSource source) {
    while (source.front.isWhite()) {
        source.popFront();
    }
}



string lexGName(InputSource source) {
    string output;
    {
        if (source.front.isAlpha)
            output ~= source.front;
        else {
            // writeln("(",source.front,")",source.seek);
            throw new BadParse(source.tell.to!string);
        }
        source.popFront();
    }
    
    while (true) {
        dchar c = source.front;
        if (c.isAlphaNum || c == '_') {
            output ~= c;
            source.popFront();
        }
        else break;
    }
    // writeln(output);
    return output;
}


Attribute lexAttribute(InputSource source) {
    Attribute attr;
    import std.conv;
    import symtable;

    if (source.front == '[') {
        source.popFront(); source.consumeWS();
        if (source.front != ']')
            throw new BadParse(source.tell.to!string);
        else {
            source.popFront();
            attr.category = AttributeType.Array;
        }
        source.consumeWS();
    }
    else {
        attr.category = AttributeType.Bare;
    }

    attr.type = source.foundCall(lexGName(source));
    source.consumeWS();
    attr.name = lexGName(source);

    return attr;
}

unittest {
    import std.stdio;
    writeln("---- Unittest ", __FILE__, " ----");
    InputSource source = new InputSourceString(`ABC `);
    writeln("lexGName(source)");
    writeln(lexGName(source));
    writeln("lexGName(source)");

}
