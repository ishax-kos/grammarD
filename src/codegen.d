module codegen;

import input;
import nodes;

import std.format;
import std.array;
import std.algorithm;


uint cg_i = 0;
string indent() {
    import std.array;
    return "    ".replicate(cg_i);
}


string codeGen(Declaration decl) {
    try {
        return codeGenSum(decl);
    }
    catch (IsNotSummable) {
        return codeGenType(decl);
    }
}


string codeGenType(Declaration decl) {
    string output;
    output ~= indent ~ format!"struct %s {\n"(decl.name);
    { cg_i++; scope(exit) cg_i--;
        if (decl.members.length == 0) {
            output ~= indent ~ format!"string capture = \"%s\";\n"("");
        }
        else {
            decl.members.each!((Attribute attr) {
                string tn = attr.type.name;
                output ~= indent ~ format!"*%s %s = new %s();\n"(
                    tn, 
                    attr.name,
                    tn);
            });
        }
    }
    output ~= indent ~ "}\n";
    return output;
}


bool isNotSummable(Declaration decl) {
    return decl.members.length == 0 
    && decl.ruleBody.alts.all!(a => 
        a.length == 1 
        && a[0].match!(
            (RuleRef _) => true,
            _ => false
        )
    );
}


class IsNotSummable: Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}


string codeGenSum(Declaration decl) {
    string output;
    RuleRef[] types = decl.ruleBody.alts.map!((a) {
        if (a.length != 1) throw new IsNotSummable("");
        return a[0].match!(
            (RuleRef rr) => rr,
            (_) => throw new IsNotSummable("")
        );
    }).array;
    output ~= indent ~ format!"alias %s = SumType!(\n"(decl.name);
    { cg_i++; scope(exit) cg_i--;
        types.each!(t =>
            output ~= indent ~ t.name ~ ",\n"
        );
    }
    output ~= indent ~ ");\n";
    return output;
}


unittest {
    import std.stdio;
    writeln("---- Unittest ", __FILE__, " ----");

    import parse.gstatements;
    import symtable;
    InputSource source;

    table.clear;
    // source = new InputSourceString("Bungar {} ");
    // source.parseG!Declaration;

    source = new InputSourceString("Test {Bungar foo} = (foo *0 bar | baz)");
    writeln(source.parseG!Declaration.codeGen);
}