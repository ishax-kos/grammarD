module nodes;

import input;

public import std.sumtype;
// alias RuleBody = string;

// class TokenRef {
//     Token _token;
//     alias _token this;
//     override string toString() {return _token.toString;}
// }

alias Token = SumType!(
    Attribute,
    CharCaptureGroup,
    StringLiteral,
    NumberLiteral,
    CharWildCard,
    MultiCapture,
    Group,
    RuleRef
    );

struct RuleRef {
    import symtable;
    string index;
    Declaration rule() {
        auto v = table[index];
        assert(v !is null);
        return v;
    }
    string name() {
        auto v = table[index];
        if (v is null) return index;
        else return v.name;
    }
}
struct StringLiteral {string str;}
struct ___CharCaptureGroup {
    string _options;
    string options() {
        import std.conv;
        import std.array;
        import std.algorithm: fold;
        import std.range: iota;
        return _options.split("..").fold!(
            (string a, string b) {
                dchar start = a[$-1];
                dchar stop = b[0];
                assert(stop > start);
                return a ~ iota!dchar(start+1, stop).to!string ~ b;
            }
        );
    }
}


struct CharCaptureGroup {
    private
    char[] _options;

    this(string options) {
        _options = options.dup;
    }

    bool empty() {return _options == "";}
    dchar front() {return _options[0];}
    void popFront() {
        if (_options.length >= 4) {
            if (_options[1..3] == "..") {
                if (_options[0] >= _options[3]) {
                    _options = _options[4..$]; return;
                }
                else {
                    _options[0]+=1; return;
                }
            }
        }
        _options = _options[1..$];
        return;
    }
}


unittest
{
    import std.stdio;
    foreach (c; CharCaptureGroup("A..Za..z0..9_")) {
        write(c);
    }
    writeln();
}


struct NumberLiteral {int num;}
struct CharWildCard {}
enum Parentheses {open, closed}

class Group {
    Token[][] alts = [[]];
    RuleRef spaceRule;
    this () {}
    this (Token[][] alts, RuleRef spRule) {this.alts = alts; spaceRule = spRule;}
    override string toString() {
        import std.format;
        import std.conv;
        import std.algorithm;
        import std.array;
        import std.stdio;
        // static _s = 0; writef!"%d_"(_s++); scope(exit) _s--;
        if (alts.length == 1) 
            return format!"Group(%(%s, %))"(alts[0]);
        else {
            writeln(0);
            // return "Alternate(" ~ alts.map!(a => a.to!string).join(", ") ~ ")";
            return format!"Alternate(%(%s, %))"(alts);
        }
            
    }
}


class MultiCapture {
    Token token;
    // mixin SetGet!(Token, "token");
    // Token token() {return *__token;}
    // void token(Token val) {*__token = val;}
    uint low = 0; 
    uint high = 0;
    this() {}
    this(Token token, uint low, uint high) {
        this.token = token;
        this.low = low;
        this.high = high;
    }

    override string toString() {
        import std.stdio;
        // static _ = 0; writef!"%d "(_++); scope(exit) _--;

        import std.format;
        if (high == 0)
            return format!"MultiCapture(%s-inf of %s)"(low, token);
        else
            return format!"MultiCapture(%s-%s of %s)"(low, high, token);
    }
}

// struct Parentheses {bool open; bool close() {return !open;}}
struct Semicolon {}


class Declaration {
    string name;
    Argument[] arguments;
    Attribute[] members;
    Group ruleBody;

    override string toString() {
        return name;
    }
}

class EmptyRule : Declaration {
    // void codeGen();
}

// class TypeDeclaration : Declaration {
//     Attribute[] members;
// }

/+
    class RuleTypeCluster {
        Declaration[] subtypes;
        /// Resolves to a sumtype
        /// +Expression(Identifier, StringLiteral);
    }
+/

struct MemberRule {
    RuleRef type;
    string name;
}

struct Attribute {
    RuleRef type;
    string name;
}

struct Argument {
    string name;
}

mixin template SetGet(T, string name) {
    mixin("T* __", name, " = new ", T, "();");

    mixin("
    T ",name,"() {
        if (__",name," == null) __",name," = new T();
        return * __",name,";
    }

    void ",name,"(T val) {
        if (__",name," == null) __",name," = new T();
        *__",name," = val;
    }");
}


class BadParse : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
