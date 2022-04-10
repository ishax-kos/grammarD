module symtable;

import std.sumtype;
import nodes;


Declaration[string] table;


Declaration foundCall(string name) {
    return table.require(name, null);
}

Declaration foundDef(Declaration rule) {
    table.update(
        rule.name, 
        () => rule,
        (Declaration a) {
            if (a is null)
                return rule;
            else
                throw new Error("Symbol Already Defined");
        }
    );
    return rule;
}
