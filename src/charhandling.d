module charhandling;
import std.sumtype;

struct Fchar {
    import std.format;
    import std.uni;
    dchar code;
    alias code this;
    string toString() {
        if (code.isControl)
            return cast(string) format!`\x%02X`(code);
        else {
            string s; s ~= code;
            return s;
        }
    }
}

alias CharCap = SumType!(Fchar, Fchar[2]);

struct CharCapRange {
    import std.range;
    import std.sumtype;
    import std.utf;
    string raw = [];
    byte _cache;
    enum rangeChar = "..";
    enum rangeSize = rangeChar.length+2;


    CharCap front() {
        if (_cache == 1) return CharCap(Fchar(raw.front));
        // if (_cache == 2) return createPair(raw[0], raw[rangeSize-1]);
        string raw = raw;
        // assert(raw.front != rangeChar);
        /// these two lines could handle escapes
        dchar ch1 = raw.frontEscape;
        raw.popFrontEscape;
        if (rangeSize-2 < raw.length) {
            if (raw[0..rangeChar.length] == rangeChar) {
                raw.popFrontN(rangeChar.length);
                dchar ch2 = raw.frontEscape;
                _cache = 2;
                return createPair(ch1, ch2);
            }
        }
        
        _cache = 1;
        return CharCap(cast(Fchar) ch1);
    }

    void popFront() {
        if (_cache == 0) {
            front;
        }
        if (_cache == 1) raw.popFrontEscape;
        if (_cache == 2) foreach(_;0..rangeSize) raw.popFrontEscape;
        _cache = 0;
    }

    bool empty() {
        return raw.length == 0;
    }

    typeof(this) save() {return this;}
}


CharCap createPair(dchar a, dchar b) {
    import std.algorithm;
    if (a == b) 
        return CharCap(cast(Fchar) a);
    else
        return CharCap([
            cast(Fchar) min(a,b), 
            cast(Fchar) max(a,b)]);
}


dchar frontEscape(string str) {
    import std.range;
    import std.conv;
    if (str.front == '\\') {
        str.popFront;
        switch (str.front) {
            case '\'', '\"', '\?','\\':	//Literal [thing]
                return str.front;
            case '0':	//Binary zero (NUL, U+0000).
                return cast(dchar)'\0';
            case 'a':	//BEL (alarm) character (U+0007).
                return cast(dchar)'\a';
            case 'b':	//Backspace (U+0008).
                return cast(dchar)'\b';
            case 'f':	//Form feed (FF) (U+000C).
                return cast(dchar)'\f';
            case 'n':	//End-of-line (U+000A).
                return cast(dchar)'\n';
            case 'r':	//Carriage return (U+000D).
                return cast(dchar)'\r';
            case 't':	//Horizontal tab (U+0009).
                return cast(dchar)'\t';
            case 'v':	//Vertical tab (U+000B).
                return cast(dchar)'\v';
            case 'x': //xnn...x
                str.popFront;
                dchar[] accum;
                while(str.front != 'x') {
                    accum ~= str.front;
                    str.popFront;    
                }
                return accum.parse!uint(16);
            default: assert(0, "Unrecognized escape sequence.");
        }
    }
    else return str.front;
}


void popFrontEscape(ref string str) {
    import std.range;
    if (str.front == '\\') {
        str.popFront;
        switch (str.front) {
            case '\'', '\"', '\?','\\','0',
            'a','b','f','n','r','t','v':
                str.popFront; return;
            case 'x':
                str.popFront;
                while(str.front != 'x') {str.popFront;}
                str.popFront; return;
            default: assert(0, "Unrecognized escape sequence.");
        }
    }
    else str.popFront;
}

string toString(CharCap cap) {
    return cap.match!(
        (Fchar c) => c.toString,
        (Fchar[2] cc) => cc[0].toString ~ cc[1].toString
    );
}
