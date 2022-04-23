module parserhelpers;

import input;
import nodes;
import parsing.lex;


T* parse(T)(InputSource source) {
    return new T();
}

void parseMultiCapture
(uint min, uint max, void function(InputSource) lam)
(InputSource source) {
    ulong n = 0;
    // auto seekInit = source.seek;
    // try {
    //     lam(source);
    //     if (seekInit == source.seek) {
    //         throw new Error("Infinite loop.");
    //     }
    //     n += 1;
    // }
    // catch(BadParse bp) {break;}
    
    while (true) {
        static if (max != 0) {
            if (n >= max) {break;}
        }
        try {
            lam();
            n += 1;
        }
        catch(BadParse bp) {break;}
    }
    static if (end != 0) {
        if (n < min) {
            throw new BadParse("Not enough iterations.");
        }
    }
}


void parseVerbatim(string str)(InputSource source) {
    foreach (ch; str) {
        if (source.current != ch) {throw new BadParse("");}
        else {source.popChar;}
    }
}