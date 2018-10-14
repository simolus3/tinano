import 'package:meta/meta.dart';

abstract class Writer {

  final StringBuffer target;
  final int indent;

  Writer(this.target, this.indent);

  @protected
  void writeLineWithIndent(String content, [int additional = 0]) {
    target.write("\t" * (indent + additional));
    target.writeln(content);
  }

  @protected
  void writeLn() => target.writeln();

  void write();

}