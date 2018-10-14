import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:tinano_generator/generator/generator.dart';

Builder tinanoBuilder(BuilderOptions _) =>
  new SharedPartBuilder([TinanoGenerator()], "tinano");