module codegen;
/+
import input;
import nodes;


void createNodeType(Property[] args, String name) {
    import std.algorithm: map;
    import std.array;
    
    "class "~name~" {\n"~
        args.map!(a => 
            a.type.toString ~ " " ~ a.name ~ "\n"
        ).array;
    "}\n";
}
// +/