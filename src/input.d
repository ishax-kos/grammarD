module input;

import nodes;

import std.ascii;
import std.sumtype;

abstract
class InputSource {
    Declaration[string] table;
    size_t line = 0;
    size_t lineStart = 0;
    size_t utfPos = 0;

    size_t col() {
        return tell - lineStart;
    }
    abstract {
        InputSource save();
        void popFront();
        dchar front();
        bool empty();
        size_t length();
        size_t tell();
        void load(InputSource);
    }
}


void inputSourceCopy(T)(T input, T output) {
    import std.range;
    output.tupleof = input.tupleof;
    foreach(i, attr; input.tupleof) {
        alias A = typeof(attr);
        static if (isForwardRange!A) {
            output.tupleof[i] = attr.save;
        }
    }
}


//+
class InputSourceString : InputSource {
    import std.range;
    // enum NO = UseReplacementDchar.no;

    this(string text) {
        str = text;
        // range = byUTF(str);
    }

    override void load(InputSource src) {
        inputSourceCopy(cast(typeof(this)) src, this);
    }

    override InputSource save() {
        auto ret = new typeof(this)("");
        inputSourceCopy(this, ret);
        return ret;
    }


    static fromFile(string path) {
        import std.stdio : File;

        File f = File(path, "rb");
        char[] buffer = new char[f.size];
        f.rawRead(buffer);
        return new InputSourceString(cast(string) buffer);
    }


    override void popFront() {
        import std.stdio;

        utfPos+=1;
        if (front == '\n') {
            line += 1;
            lineStart = utfPos;
        }
        auto l = str.length;
        str.popFront;
        pos += l - str.length;
    }

    override dchar front() {
        if (empty) return 0;
        return str.front;
    }

    override bool empty() {
        return str.empty;
    }

    override ulong length() {
        return str.length;
    }

    override size_t tell() {return pos;}

    private {
        ulong pos = 0;
        string str = "";
        // typeof("".byUTF!(dchar, NO)) range;
    }
}


/+
class InputSourceFile : InputSource {
    import std.utf;
    enum NO = UseReplacementDchar.no;

    this(string path) {
        file = FileRange!char(path);
    }

    private this () {}


    override void load(InputSource src) {
        inputSourceCopy(this, cast(typeof(this)) src);
    }

    override InputSource save() {
        auto ret = new typeof(this);
        inputSourceCopy(this, ret);
        return ret;
    }


    override void popFront() {
        import std.stdio;
        utfPos += 1;
        if (front == '\n') {
            line += 1;
            lineStart = utfPos;
        }
        file.pos += file.stride;

        //  += str[pos..$].stride;
        // range.popFront;
    }

    override dchar front() {
        return range.front;
    }

    override bool empty() {
        return range.empty;
    }

    override size_t length() {
        return file.length;
    }
    
    override size_t tell() {return file.pos;}

    private {
        private FileRange!char file;
        auto range() {return file.byUTF!(dchar, NO);}
    }
}

struct FileRange(T) {
    import std.mmfile;
    MmFile file;
    size_t pos;
    
    this(string path) {
    	file = new MmFile(path);
    }
    
    T front() {
        return
            (cast(T[]) (file[ pos .. (pos + T.sizeof)])) [0];
    }
    void popFront() {
        pos += T.sizeof;
    }
    
    bool empty() {
        return (pos+1)*T.sizeof > file.length;
    }

    size_t length() {return file.length;}

    typeof(this) save() {
        return this;
    }
}
// +/

// unittest {
//     import std.range;
//     import std.stdio;
//     // import std.mmfile;
//     writeln("---- Unittest ", __FILE__, " ----");
//     import std.utf;


//     InputSourceString s1 = new InputSourceString("linkリンク");
//     // InputSource s1 = new InputSourceFile("test/langsrc/text.txt");
//     // auto s1 = FileRange!char("test/langsrc/text.txt");
//     // string s1 = "linkリンク";
//     s1.popFront;
//     auto s2 = s1.save;
//     foreach(s; s1){
//         writeln(s);
//     }
// }