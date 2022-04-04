module table;

import std.sumtype;

template symbol(Rule) {

    Rule[string] table;


    Rule[string] foundCall(string name) {
        table.require(name, null);
        return table;
    }

    Rule[string] foundDef(Rule rule) {
        table.update(rule.name, 
            rule,
            (a) {
                if (storedRule == null) {
                    return table;
                }
                else throw Error("Symbol Already Defined");
            }
        );
        return table;
    }

}