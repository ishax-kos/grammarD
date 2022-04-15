module symtable;

import std.sumtype;
import nodes;


Declaration[string] table;


class SymbolAlreadyDefined : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}


RuleRef foundCall(string name) {
    table.require(name, null);
    return RuleRef(name);
}

Declaration foundDef(Declaration rule) {
    table.update(
        rule.name, 
        () => rule,
        (Declaration a) {
            if (a is null)
                return rule;
            else
                throw new SymbolAlreadyDefined("\""~a.name~"\" Symbol Already Defined");
        }
    );
    return rule;
}