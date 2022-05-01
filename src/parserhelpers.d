module parserhelpers;

import input;
import nodes;
// import parsing.lex;


/+
    Remember not to use whitespace skipping at the head 
    and tail of functions. Only if strictly necessary, 
    and only in-between captures!
+/

// T* parse(T)(InputSource source) {
//     return new T();
// }

void parseMultiCapture
(uint min, uint max, void function(InputSource) lam)
(InputSource source) {
    ulong n = 0;
    
    while (true) {
        static if (max != 0) {
            if (n >= max) {break;}
        }
        try {
            lam(source);
            n += 1;
        }
        catch(BadParse bp) {break;}
    }
    static if (min != 0) {
        if (n < min) {
            throw new BadParse("Not enough iterations.");
        }
    }
}

pragma(inline, true)
void parseCharCaptureGroup(CharCaptureGroup ccg)(InputSource source) {
    foreach(ch; ccg.options) {
        if (source.current == ch) {
            source.popChar;
            break;
        }
    }
}


void parseVerbatim(string str)(InputSource source) {
    foreach (ch; str) {
        if (source.current != ch) {throw new BadParse("");}
        else {source.popChar;}
    }
}


pragma(inline)
T tryAll(T, C...)(InputSource source) {
    import std.format;
    import std.stdio;

    // wsCallback(source);
    T output;
    InputSource branch;
    Exception[] earr;

    static foreach (expr; C) {
        branch = source.save();
        try {
            output = cast(T) expr(branch);
            goto Done;
        }
        catch (BadParse e) earr~=e;
    }
    throw new Error(earr.format!"%(%s\n\n%)\n\nFinal Error Stack");

    Done:
    source = branch;
    return output;
}




class BadParse : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }

    import std.format;
    this(string msg, InputSource source, string file = __FILE__, size_t line = __LINE__) {
        super(format!"%s, at %s,%s."(msg, source.line, source.col), file, line);
    }
}
