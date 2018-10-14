import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:tinano_generator/generator/generation_context.dart';
import 'package:tinano_generator/parser/database_parser.dart';
import 'package:tinano_generator/writer/database_writer.dart';

class TinanoGenerator extends Generator {
  static const String TYPE_DATABASE = "Database";

  GenerationContext context;

  TinanoGenerator() {
    context = GenerationContext();
  }

  @override
  Future<String> generate(LibraryReader library, BuildStep step) async {
    final outputs = List<String>();

    for (final clazz in library.classElements) {
      final parser = DatabaseParser.forClass(clazz, context);

      if (parser != null) {
        parser.parse();
        final db = parser.database;

        final buffer = StringBuffer();
        final writer = DatabaseWriter(db, context, buffer);

        writer.write();
        outputs.add(buffer.toString());
      }
    }

    return outputs.isEmpty ? null : outputs.join("\n");
  }
}
