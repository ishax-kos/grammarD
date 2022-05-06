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

void parseMultiCapture(uint min, uint max, alias lambda)
(InputSource source) {
    ulong n = 0;
    
    while (true) {
        static if (max != 0) {
            if (n >= max) {break;}
        }
        try {
            lambda(source);
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


void parseVerbatim(string str)(InputSource source) {
    foreach (ch; str) {
        if (source.front != ch) {throw new BadParse("");}
        else {source.popFront;}
    }
}


pragma(inline)
T tryAll(T, C...)(InputSource source) {
    import std.format;
    import std.stdio;

    // wsCallback(source);
    // T output;
    InputSource branch;
    Exception[] earr;

    scope(exit) source.load(branch);
    static foreach (expr; C) {
        branch = source.save();
        try {
            return cast(T) expr(branch);
        }
        catch (BadParse e) earr~=e;
    }
    throw new Error(earr.format!"%(%s\n\n%)\n\nFinal Error Stack");

    // return output;
}


string parseSince(InputSource current, InputSource start) {
    assert(current.sharesWith(start));
    import std.range: take;
    import std.algorithm: each;
    ulong len = current.tell - start.tell;
    string ret;
    ret.reserve = len*2;
    foreach (dch; start.take(len)) {
        ret ~= dch;
    }
    return ret;
}


class BadParse : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }

    import std.format;
    this(string msg, InputSource source, string file = __FILE__, size_t line = __LINE__) {
        // super(format!"%s at %s,%s."(msg, source.line, source.col), file, line);
        super(format!"%s at %s."(msg, source.tell), file, line);
    }
}
