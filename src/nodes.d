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
    RuleRef,
    NumberLiteral,
    VerbatimText,
    CharCaptureGroup,
    CharWildCard,
    MultiCapture,
    Group
    );

struct RuleRef {
    import symtable;
    InputSource source;
    string index;
    Declaration rule() {
        auto v = source.table[index];
        assert(v !is null);
        return v;
    }
    string name() {
        if (source is null) {
            return index;
        }
        else {
            auto v = source.table[index];
            if (v is null) return index;
            else return v.name;
        }
    }
    string toString() {
        return "RuleRef(" ~ name ~ ")";
    }
}
struct VerbatimText {string str;}
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

public import charhandling: Fchar;
struct CharCaptureGroup {
    import charhandling;
    CharCapRange range;
    this(string str) {
        range.raw = str;
    }
}

unittest
{
    import std.stdio;
    import std.range;
    import std.algorithm: all, map;
    import charhandling;
    import std.conv;
    
    auto r = CharCaptureGroup("A..Za..z0..9_").range;
    string[] sa = ["AZ", "az", "09", "_"];
    while (!r.empty) {
        assert(sa.front == r.front.match!(
            (Fchar char1) => [char1.code].to!string,
            (Fchar[2] char2) => [char2[0].code, char2[1].code].to!string
        ));
        sa.popFront;
        r.popFront;
    }
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
        if (alts.length == 1) 
            return format!"Group(%(%s, %))"(alts[0]);
        else {
            // writeln(0);
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

abstract class Declaration {
    string name;
}

class DeclarationStruct : Declaration {
    Argument[] arguments;
    Attribute[] members;
    Group ruleBody;

    override string toString() {
        return name;
    }
}

class DeclarationSum : Declaration {
    RuleRef[] types;
}

class EmptyRule : Declaration {}

// alias Declaration = SumType!(EmptyRule, DeclarationStruct, DeclarationSum);


// struct MemberRule {
//     RuleRef type;
//     string name;
// }

struct Attribute {
    RuleRef type;
    string name;
    AttributeType category;
    
}

enum AttributeType {
    Bare,
    Array,
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
