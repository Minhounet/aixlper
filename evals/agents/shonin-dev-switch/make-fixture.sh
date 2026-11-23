#!/usr/bin/env bash
# Builds a fix-mode run of saiban-orchestrator paused after green 1, where
# green 1 built ahead: it already handles the single-number case that test 2
# asks for. The plan has three tests, so the upfront rule keeps the dev off;
# only the reactive rule can turn it on, when red 2 passes on arrival.
# usage: make-fixture.sh <dir>
set -euo pipefail
dir=$1
mkdir -p "$dir/src/main/java/com/example" "$dir/src/test/java/com/example" "$dir/docs/decisions"
cd "$dir"
git init -q
git config user.email kata@example.com
git config user.name kata
commit() { git add -A; git commit -qm "$1"; }

cat > pom.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>calc</artifactId>
  <version>1.0-SNAPSHOT</version>
  <properties>
    <maven.compiler.release>21</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>
  <dependencies>
    <dependency><groupId>io.vavr</groupId><artifactId>vavr</artifactId><version>0.10.4</version></dependency>
    <dependency><groupId>org.junit.jupiter</groupId><artifactId>junit-jupiter</artifactId><version>5.11.3</version><scope>test</scope></dependency>
  </dependencies>
  <build><plugins>
    <plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-surefire-plugin</artifactId><version>3.5.2</version></plugin>
  </plugins></build>
</project>
EOF
printf 'target/\ndocs/decisions/\n' > .gitignore
commit "init"

cat > src/test/java/com/example/StringCalculatorTest.java <<'EOF'
package com.example;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class StringCalculatorTest {

    private final StringCalculator calculator = new StringCalculator();

    @Test
    void shouldReturnZero_whenEmptyString() {
        assertEquals(0, calculator.add(""));
    }
}
EOF
cat > src/main/java/com/example/StringCalculator.java <<'EOF'
package com.example;

public class StringCalculator {

    public int add(String numbers) {
        throw new UnsupportedOperationException();
    }
}
EOF
commit "red 1: empty string returns zero"

cat > src/main/java/com/example/StringCalculator.java <<'EOF'
package com.example;

public class StringCalculator {

    public int add(String numbers) {
        return numbers.isEmpty() ? 0 : Integer.parseInt(numbers);
    }
}
EOF
commit "green 1: empty string returns zero"

cat > docs/decisions/string-calculator.md <<'EOF'
## Resume
- Status: open
- Mode: fix
- Done: red 1, green 1 (committed)
- Next: red 2, then the rest of the approved plan below
- Files: src/main/java/com/example/StringCalculator.java, src/test/java/com/example/StringCalculatorTest.java

## Request
Add `int add(String numbers)` to `StringCalculator`: empty string gives 0, a
single number gives itself, two comma-separated numbers give their sum.

## Plan - igiari-tdd test plan (approved)
- Decided: StringCalculatorTest, three tests:
  1. shouldReturnZero_whenEmptyString - add("") == 0
  2. shouldReturnNumber_whenSingleNumber - add("5") == 5
  3. shouldReturnSum_whenTwoCommaSeparatedNumbers - add("1,2") == 3
- Why: one behaviour per test, in the order the request lists them.
- Rejected: nothing.
- Asked user: yes (approved as-is)

## Review - none
- Decided: no kenji-reviewer run.
- Why: the user said "no review".
- Rejected: nothing.
- Asked user: no

## TDD - red 1, green 1
- Decided: red 1 failed on UnsupportedOperationException; green 1 committed.
- Why: igiari-tdd cycle.
- Rejected: nothing.
- Asked user: no
EOF
