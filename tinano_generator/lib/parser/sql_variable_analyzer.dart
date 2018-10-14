class SqlWithVariables {
  /// The sql, but not as it was specified by the user but instead with all
  /// variables replaced with "?" so that we can use prepared statements.
  final String updatedSql;

  /// All variable names that occurred in the sql specified by the user.
  final Set<String> foundVariables;

  /// All variable names with their position (can include duplicates if a
  /// variable is used more than once in the query). When we create the
  /// parameters for the prepared statement, the n-th value should fit to the
  /// n-th variable, so we need to keep track of the positons.
  final List<String> variablesWithPosition;

  SqlWithVariables(
      this.updatedSql, this.foundVariables, this.variablesWithPosition);
}

class SqlVariableAnalyzer {
  String updatedSql;
  Set<String> foundVariables = new Set();
  List<String> variablesWithPosition = new List();

  SqlWithVariables get sqlWithVars =>
      SqlWithVariables(updatedSql, foundVariables, variablesWithPosition);

  static final RegExp _variableMatcher = RegExp(r":(\w*)");

  SqlVariableAnalyzer(String sql) {
    updatedSql = sql;

    final matches = _variableMatcher.allMatches(sql).where((match) {
      // Ignore matches with a \ before them
      if (match.start != 0) {
        final charBefore = sql[match.start - 1];

        if (charBefore == "\\") {
          return false;
        }
      }

      return true;
    });

    var offset = 0;
    for (final match in matches) {
      final start = match.start;
      final end = match.end;
      final name = match.group(1);

      // Replace the variables with ? so that they can be bound later
      updatedSql = updatedSql.replaceRange(start - offset, end - offset, "?");

      foundVariables.add(name);
      variablesWithPosition.add(name);

      // Replacing the variables with "?" will make the string shorter, so the
      // indices need to be updated for the following iterations.
      offset += (end - start) - "?".length;
    }
  }
}
