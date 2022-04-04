module nodes;

import input;

public import std.sumtype;
// alias RuleBody = string;
alias RuleRef = string;

class TokenRef {
    Token _token;
    alias _token this;
    override string toString() {return _token.toString;}
}

alias Token = SumType!(
    Property, 
    Rule, 
    StringLiteral,
    NumberLiteral,
    BinaryOp,
    LeftOp,
    RightOp,
    MultiCapture,
    Group,
    Semicolon
    );

struct StringLiteral {string str;}
struct NumberLiteral {int num;}
struct BinaryOp {string str;}
struct LeftOp {string str;}
struct RightOp {string str;}
enum Parentheses {open, closed}

class Group {
    Token[][] alts = [[]];
    this () {}
    this (Token[][] alts) {this.alts = alts;}
    override string toString() {
        import std.format;
        import std.stdio;
        static _ = 0; writef!"%d_"(_++); scope(exit) _--;
        if (alts.length == 1) 
            return format!"Group(%s)"(alts[0]);
        else
            return format!"Alternate(%s)"(alts);
    }
}


class MultiCapture {
    Token token;
    // mixin SetGet!(Token, "token");
    // Token token() {return *__token;}
    // void token(Token val) {*__token = val;}
    uint low = 0; 
    uint high = 0;
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


class Rule {
    string name;
    Property[] args;
    override string toString() {
        return name;
    }
}

class BareRule : Rule {

}

class TypeRule : BareRule {
    string name;
    Token[] ruleBody;
    Property[] members;
}


class RuleTypeClass : Rule {
    Rule[] subtypes;
    /// Resolves to a sumtype
    /// +Expression(Identifier, StringLiteral);
}


struct Property {
    Rule type;
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