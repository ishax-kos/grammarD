module main;

import input;

import std.stdio;
import std.format;
import std.array;

import std.string;
import std.algorithm;

/++
    Parsing from the same seek position more than once 
    with the same parse function is an infinite loop 
    and should be prevented. +/


void main() {
    InputSource source = InputSourceFile("gram/dion.gram");
    

    Rule[] rules;
    while (!file.eof()) {
        Rule rule;
        parseGRule(source);
        // try {
        //     rule = parseGTypeDecl(source);
        // }
        // catch (BadParse bp) try {
        //     rule = parseGRule(source);

        // }catch

        if (isNode) {
            rule = new NodeRule(name, args, ruleBody);
        }
    }
}




