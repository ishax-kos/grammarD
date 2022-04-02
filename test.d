import std.stdio;
import std.meta;

alias Foo = AliasSeq(int, string);

void func(T)(T val) {
    writeln(typeof(val).stringof);
}

void main() {
    func(1);
    func("string");
}