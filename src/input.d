module input;

import nodes;
import rule_parsing;

import std.ascii;

import std.sumtype;



interface InputSource {
    char popChar();
    bool end();
    @property
    ulong seek();
    @property
    void seek(ulong);
    char current();
    ulong size();
    InputSource branch();
}

void seekRel(InputSource source, long offset) {
    long pos = (source.seek + offset);
    assert(pos >= 0 && pos < source.size);
    source.seek = pos;
}

class InputSourceString : InputSource {

    this(string text) {
        str = text;
    }

    InputSource branch() {
        auto iss = new InputSourceString(str);
        iss.seek = this.seek;
        return iss;
    }

    static fromFile(string path) {
        import std.stdio: File;
        File f = File(path, "rb");
        char[] buffer = new char[f.size];
        f.rawRead(buffer);
        return new InputSourceString(cast(string) buffer);
    }

    ulong seek() {return _seek;}
    void seek(ulong set) {
        assert(set <= str.length);
        _seek = set;
    }

    char popChar() {
        if (end()) return 0;
        else return str[_seek++];
    }

    bool end() {
        return _seek >= size;
    }

    char current() {
        if (end()) return 0;
        else return str[_seek];
    }

    ulong size() {return str.length;}


    private: 
    ulong _seek = 0;
    string str = "";
}


//+
class InputSourceFile : InputSource {
    import std.mmfile;

    this(string path) {
        file = new MmFile(path);
    }

    this(MmFile file, ulong seek) 
        {this.file = file; this.seek = seek;}

    InputSource branch() {
        return new InputSourceFile(file, seek);
    }


    ulong seek() {return _seek;}
    void seek(ulong set) {
        assert(set <= file.length);
        _seek = set;
    }

    char popChar() {
        if (end()) return 0;
        else return file[_seek++];
    }

    bool end() {
        return _seek >= size;
    }

    char current() {
        if (end()) return 0;
        else return file[_seek];
    }

    ulong size() {return file.length;}


    private: 
    ulong _seek = 0;
    MmFile file;
}
//+/

void consumeWS(InputSource source) {
    while (source.current.isWhite())
        source.popChar();
}


string lexGName(InputSource source) {
    string output;
    source.consumeWS();
    {
        if (source.current.isAlpha)
            output ~= source.current;
        else throw new BadParse("");
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


RuleRef lexGType(InputSource source) {
    string name;
    while (true) {
        source.consumeWS();
        if (source.current != '[') break;
        source.popChar();
        source.consumeWS();
        if (source.popChar() != ']')
            throw new BadParse("");
        name ~= "[]";
    }

    name ~= lexGName(source);

    return name;
}


// bool testLexGArgs(InputSource source) {
//     source.consumeWS();
//     bool ret = source.popChar() == '(';
//     source.seekRel(-1);
//     return ret;
// }


Property[] lexGArgs(InputSource source) {
    Property[] output;
    {
        source.consumeWS();
        char c = source.popChar();
        if (c == '{') {}
        else throw new BadParse([c]);
    }
    
    while (true) {
        output ~= Property(
            lexGType(source),
            lexGName(source));

        source.consumeWS();
        char c = source.current;
        if (c == ',') {source.popChar();}
        else if (c == '}') {
            source.popChar();
            break;
        }
        else throw new BadParse("");
        
    }
    return output;
}


void lexGChar(InputSource source, char ch) {
    consumeWS(source);
    if (source.current == ch) {
        source.popChar();
    }
    else throw new BadParse("");
}


// RuleBody lexGBody(InputSource source) {
// }



class BadParse : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}


T parseG(T:Rule)(InputSource source) {
    
    Rule rule;
    InputSource branch;
    try {
        branch = source.branch();
        branch.lexGChar(':');
        rule = new TypeRule();
    }
    catch (BadParse bp) try {
        branch.lexGChar('+');
        rule = new Rule();
    }
    
    assert(rule);

    rule.name = lexGName(source);
    rule.args = lexGArgs(source);
    
    consumeWS(source);
    if (source.current != '=')
        throw new BadParse("");
    source.popChar();
    // rule.ruleBody;
    while (true) {
        Token token = getToken(source, rule.args);
        if (token.match!(
            (Semicolon _) => true,
            (_) {rule.ruleBody ~= token; return false;}
        )) break;
    }
    return rule;
}


unittest
{
    InputSource source = InputSourceString.fromFile(`gram/dion.gram`);

    
    // source.consumeWS();
    // source.consumeWS();
    // source.consumeWS();
    // source.consumeWS();
    // writeln(source.popChar());

    // writeln(source.lexGArgs());
    // source.seek = 4;
}