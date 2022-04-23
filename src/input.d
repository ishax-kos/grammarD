module input;

import nodes;

import std.ascii;
import std.sumtype;

abstract
class InputSource {
    Declaration[string] table;
    // abstract {
    char popChar();
    bool end();
    @property ulong seek();
    @property void seek(ulong);
    char current();
    ulong size();
    InputSource branch();
    // }
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
    
    override InputSource branch() {
        auto iss = new InputSourceString(str);
        iss.seek = this.seek;
        return iss;
    }

    static fromFile(string path) {
        import std.stdio : File;

        File f = File(path, "rb");
        char[] buffer = new char[f.size];
        f.rawRead(buffer);
        return new InputSourceString(cast(string) buffer);
    }

    override ulong seek() {
        return _seek;
    }

    override void seek(ulong set) {
        assert(set <= str.length);
        _seek = set;
    }

    override char popChar() {
        if (end())
            return 0;
        else
            return str[_seek++];
    }

    override bool end() {
        return _seek >= size;
    }

    override char current() {
        if (end())
            return 0;
        else
            return str[_seek];
    }

    override ulong size() {
        return str.length;
    }

    // ref Declaration[string] table() {return _table;}

    private {
        ulong _seek = 0;
        string str = "";
        // Declaration[string] _table;
    }
}

//+
class InputSourceFile : InputSource {
    import std.mmfile;

    this(string path) {
        file = new MmFile(path);
    }

    this(MmFile file, ulong seek) {
        this.file = file;
        this.seek = seek;
    }

    override InputSource branch() {
        return new InputSourceFile(file, seek);
    }

    override ulong seek() {
        return _seek;
    }

    override void seek(ulong set) {
        assert(set <= file.length);
        _seek = set;
    }

    override char popChar() {
        if (end())
            return 0;
        else
            return file[_seek++];
    }

    override bool end() {
        return _seek >= size;
    }

    override char current() {
        if (end())
            return 0;
        else
            return file[_seek];
    }

    override ulong size() {
        return file.length;
    }

    // ref Declaration[string] table() {return _table;}

    private {
        ulong _seek = 0;
        MmFile file;
        // Declaration[string] _table;
    }
}
//+/
