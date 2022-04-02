module clean;
import nodes;
import std.range;
/+
Token group(ref Token[] input) {
    Group output = new Group();

    while (!input.empty) {
        Token tok = input.front();
        input.popFront;
        if (tok == Token(Parentheses.open))
            output.tokens ~= input.group();
        else if (tok == Token(Parentheses.closed)) {
            break;
        }
        else output.tokens ~= tok;
    }
    return output.splitBranches();
}


Token splitBranches(Group group) {
    import std.array;
    import std.algorithm: canFind;
    import std.stdio;
    // writeln("000 ", group.tokens);
    // if (group.tokens.canFind(Token(BinaryOp("|"))))
    //     writeln("foo hoo!");
    Token[][] arr = group
        .tokens
        .split(Token(BinaryOp("|")));
    if (arr.length == 1) {
        return Token(new Group(arr[0]));
    }
    else if (arr.length > 1) 
        return Token(new Alternate(arr));
    else throw new Error("");
}


unittest
{
    import input;
    import std.stdio;
    writeln("---- Unittest ", __FILE__, " ----");
    
    
    auto source = new InputSourceFile(`gram/dion.gram`);
    Token[] arr = source.parseGRule().ruleBody;
    writefln!"%(%s\n%)"(arr);
    writeln("----");
    writeln(arr.group());
}
// +/