module symtable;

import nodes;
import input;

import std.sumtype;


// Declaration[string] table;


class SymbolAlreadyDefined : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}


RuleRef foundCall(InputSource source, string name) {
    if (name !in source.table) {
        source.table[name] = null;
    }
    return RuleRef(source, name);
}

Declaration foundDef(InputSource source, Declaration rule) {
    if (rule.name !in source.table) {
        source.table[rule.name] = rule;
    }
    else {
        if (source.table[rule.name] is null) {
            source.table[rule.name] = rule;
        }
        else throw new SymbolAlreadyDefined(
            "\""~source.table[rule.name].name
            ~"\" Symbol Already Defined"
        );
    }
    return rule;
}



unittest {
    // import std.stdio;
    import std.conv;
    // writeln("---- Unittest ", __FILE__, " ----");

    import parsing.gstatements;
    import symtable;
    import parsing.lex;
    import std.algorithm: equal;
    InputSource source;
    
    string sourceText = 
    `
Variable {Bungo foo} = (Identifier)
    `;
    
    source = new InputSourceString(sourceText);

    
    // source.table["foo"] = null;
    // assert("foo" in source.table);
    source.consumeWS;
    source.parseG!DeclarationStruct;
    auto s2 = source.save;
    
    import std.algorithm;
    Declaration[string] aa = ["WS":null, "Identifier":null, "Bungo":null];
    assert(s2.table == aa);
    // source.table.each!((v,k)=>writeln(v));
}