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
    // source.table.update(
    //     rule.name,
    //     () => rule,
    //     (Declaration a) {
    //         if (a)
    //             return rule;
    //         else
    //             throw new SymbolAlreadyDefined(
    //                 "\""~a.name
    //                 ~"\" Symbol Already Defined");
    //     }
    // );
    return rule;
}