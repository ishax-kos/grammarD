module testrun;
import parserhelpers;
import input;
import std.sumtype;


struct StringLiteral {
    string capture = "";
}
StringLiteral _parseStringLiteral(InputSource source) {
    alias This = StringLiteral;
    static size_t guard = -1;
    if (guard == source.tell) throw new BadParse("Left recursion");
    guard = source.tell; scope(exit) guard = -1;
    This rule = This();
    
    InputSource start = source.save;
    parseVerbatim!"\""(source);
    source.parseMultiCapture!(0, 0, delegate void(source) {
        source.tryAll!(void,
            (source) {
                parseVerbatim!"\""(source);
            },
            (source) {
                source.popFront;
            },
        );
    })();
    parseVerbatim!"\""(source);
    rule.capture = source.parseSince(start);
    
    return rule;
}

struct WS {
    string capture = "";
}
WS _parseWS(InputSource source) {
    alias This = WS;
    static size_t guard = -1;
    if (guard == source.tell) throw new BadParse("Left recursion");
    guard = source.tell; scope(exit) guard = -1;
    This rule = This();
    
    InputSource start = source.save;
    source.parseMultiCapture!(1, 0, delegate void(source) {
        if (0
            || source.front == ' '
            || source.front == '\x0A'
            || source.front == '\x0D'
        ) {source.popFront;}
        else throw new BadParse("");
    })();
    rule.capture = source.parseSince(start);
    
    return rule;
}

struct Identifier {
    string capture = "";
}
Identifier _parseIdentifier(InputSource source) {
    alias This = Identifier;
    static size_t guard = -1;
    if (guard == source.tell) throw new BadParse("Left recursion");
    guard = source.tell; scope(exit) guard = -1;
    This rule = This();
    
    InputSource start = source.save;
    if (0
        || (source.front >= 'a' && source.front <= 'z')
        || (source.front >= 'A' && source.front <= 'Z')
    ) {source.popFront;}
    else throw new BadParse("");
    source.parseMultiCapture!(0, 0, delegate void(source) {
        if (0
            || (source.front >= 'a' && source.front <= 'z')
            || (source.front >= 'A' && source.front <= 'Z')
            || (source.front >= '0' && source.front <= '9')
            || source.front == '_'
        ) {source.popFront;}
        else throw new BadParse("");
    })();
    rule.capture = source.parseSince(start);
    
    return rule;
}

struct Variable {
    Identifier ident;
}
Variable _parseVariable(InputSource source) {
    alias This = Variable;
    static size_t guard = -1;
    if (guard == source.tell) throw new BadParse("Left recursion");
    guard = source.tell; scope(exit) guard = -1;
    This rule = This();
    
    rule.ident = _parseIdentifier(source);
    
    return rule;
}

struct OpPrec10 {
    string capture = "";
}
OpPrec10 _parseOpPrec10(InputSource source) {
    alias This = OpPrec10;
    static size_t guard = -1;
    if (guard == source.tell) throw new BadParse("Left recursion");
    guard = source.tell; scope(exit) guard = -1;
    This rule = This();
    
    InputSource start = source.save;
    _parseExpression(source);
    _parseWS(source);
    source.tryAll!(void,
        (source) {
            parseVerbatim!"+"(source);
        },
        (source) {
            parseVerbatim!"-"(source);
        },
    );
    _parseWS(source);
    _parseExpression(source);
    rule.capture = source.parseSince(start);
    
    return rule;
}

alias Expression = SumType!(
    OpPrec10, 
    Variable, 
    StringLiteral
);
Expression _parseExpression(InputSource source) {
    static size_t guard = -1;
    if (guard == source.tell) throw new BadParse("Left recursion");
    guard = source.tell; scope(exit) guard = -1;
    return source.tryAll!(Expression,
        source => _parseOpPrec10(source),
        source => _parseVariable(source),
        source => _parseStringLiteral(source),
    );
}

struct Call {
    Expression caller;
    Expression[] args;
}
Call _parseCall(InputSource source) {
    alias This = Call;
    static size_t guard = -1;
    if (guard == source.tell) throw new BadParse("Left recursion");
    guard = source.tell; scope(exit) guard = -1;
    This rule = This();
    
    rule.caller = _parseExpression(source);
    _parseWS(source);
    parseVerbatim!"("(source);
    _parseWS(source);
    source.parseMultiCapture!(0, 1, delegate void(source) {
        rule.args ~= _parseExpression(source);
        _parseWS(source);
        source.parseMultiCapture!(0, 0, delegate void(source) {
            parseVerbatim!","(source);
            _parseWS(source);
            rule.args ~= _parseExpression(source);
        })();
    })();
    _parseWS(source);
    parseVerbatim!")"(source);
    
    return rule;
}
void main() {
    import std.stdio;
    writeln("-");
    InputSource source = new InputSourceString("foo + bar  ");
    writeln(_parseOpPrec10(source));
    writeln("-");
}
