module input;

import nodes;

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
    while (source.current.isWhite()) {
        source.popChar();
    }
}


// bool testLexGArgs(InputSource source) {
//     source.consumeWS();
//     bool ret = source.popChar() == '(';
//     source.seekRel(-1);
//     return ret;
// }

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