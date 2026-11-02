#!/usr/bin/env bash
# Builds the kenji-reviewer fixture: a Maven kata project whose git history is
# one ticket, two ACs, done with igiari-tdd and objection-conception. AC1's
# run is the same in both variants; the reviewer is asked about AC2's run.
#
# usage: make-fixture.sh <clean|defects> <dir>
#   clean    AC2 done by the rules: the reviewer should answer PASS.
#   defects  AC2 with the four defects listed in expected.md (D1-D4).
# Prints the commit range of AC2's run: <base>..<head>.

set -euo pipefail
variant=$1 dir=$2
case $variant in clean|defects) ;; *) echo "variant: clean or defects" >&2; exit 2;; esac
rm -rf "$dir"; mkdir -p "$dir"; cd "$dir"
git init -q; git config user.email kata@example.com; git config user.name kata
commit() { git add -A; git commit -qm "$1"; }

src=src/main/java/com/example/StringCalculator.java
tst=src/test/java/com/example/StringCalculatorTest.java
mkdir -p src/main/java/com/example src/test/java/com/example docs/ticket/KATA-1

cat > pom.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>kata</artifactId>
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
printf 'target/\n' > .gitignore

cat > docs/ticket/KATA-1/conception.md <<'EOF'
---
ticket: KATA-1
status: in-progress
---
# KATA-1: string calculator

## Structural plan (approved)
- One class, `StringCalculator`, with `int add(String numbers)`. No
  collaborators, no interfaces: pure computation.

## Decisions
- D1: numbers are separated by commas only; other separators are out of
  scope for this ticket.
EOF

acceptance() {  # $1 = AC2 evidence line, $2 = AC2 status, $3 = AC1 status
  local ac1_evidence="returnsZeroForEmptyString [AC1], mvn verify passed"
  [ "${3:-verified}" = verified ] || ac1_evidence="-"
  cat > docs/ticket/KATA-1/acceptance.md <<EOF
# KATA-1: acceptance criteria

## AC1: empty input
- Source: "An empty string returns 0."
- Interpretation: add("") returns 0.
- Covered by: D1
- Evidence: $ac1_evidence
- Status: ${3:-verified}

## AC2: comma-separated numbers
- Source: "One or more numbers separated by commas return their sum."
- Interpretation: add("1") returns 1, add("1,2") returns 3.
- Covered by: D1
- Evidence: $1
- Status: $2

## Discrepancies
None.
EOF
}

test_class() {  # the test methods given, one per argument
  { printf 'package com.example;\n\nimport static org.junit.jupiter.api.Assertions.assertEquals;\n\n'
    printf 'import org.junit.jupiter.api.DisplayName;\nimport org.junit.jupiter.api.Test;\n\n'
    printf 'class StringCalculatorTest {\n\n    private final StringCalculator calculator = new StringCalculator();\n'
    for m in "$@"; do printf '%s\n' "$m"; done
    printf '}\n'; } > "$tst"
}
T1='
    @Test
    @DisplayName("[AC1] empty string returns 0")
    void returnsZeroForEmptyString() {
        assertEquals(0, calculator.add(""));
    }'
T2='
    @Test
    @DisplayName("[AC2] a single number returns itself")
    void returnsTheNumberForASingleNumber() {
        assertEquals(1, calculator.add("1"));
    }'
T3='
    @Test
    @DisplayName("[AC2] two numbers return their sum")
    void returnsTheSumOfTwoNumbers() {
        assertEquals(3, calculator.add("1,2"));
    }'
prod() { printf 'package com.example;\n\n%s\n' "$1" > "$src"; }

acceptance "-" "designed" "designed"
prod 'public class StringCalculator {

    public int add(String numbers) {
        throw new UnsupportedOperationException();
    }
}'
commit "init: KATA-1 design and empty StringCalculator"

# AC1's run, identical in both variants.
test_class "$T1"; commit "red 1: returnsZeroForEmptyString [AC1]"
prod 'public class StringCalculator {

    public int add(String numbers) {
        return 0;
    }
}'
commit "green 1: return 0"
acceptance "-" "designed"; commit "KATA-1: AC1 verified"
base=$(git rev-parse HEAD)

if [ "$variant" = clean ]; then
  test_class "$T1" "$T2"; commit "red 2: returnsTheNumberForASingleNumber [AC2]"
  prod 'public class StringCalculator {

    public int add(String numbers) {
        return numbers.isEmpty() ? 0 : Integer.parseInt(numbers);
    }
}'
  commit "green 2: parse a single number"
  test_class "$T1" "$T2" "$T3"; commit "red 3: returnsTheSumOfTwoNumbers [AC2]"
  # igiari-tdd's own "Super" rung for this exact moment: two operands, no
  # loop. A split-and-sum pipeline here is its "Over-built" rung (invalid).
  prod 'public class StringCalculator {

    private static final String DELIMITER = ",";

    public int add(String numbers) {
        if (numbers.isEmpty()) {
            return 0;
        }
        String[] operands = numbers.split(DELIMITER);
        if (operands.length == 1) {
            return Integer.parseInt(operands[0]);
        }
        return Integer.parseInt(operands[0]) + Integer.parseInt(operands[1]);
    }
}'
  commit "green 3: sum two comma-separated numbers"
  acceptance "returnsTheNumberForASingleNumber [AC2], returnsTheSumOfTwoNumbers [AC2], mvn verify passed" "verified"
  commit "KATA-1: AC2 verified"
else
  test_class "$T1" "$T2"; commit "red 2: returnsTheNumberForASingleNumber [AC2]"
  # D1: green 2 builds the whole split-and-sum rule for a test that only asks for "1".
  prod 'import io.vavr.collection.List;

public class StringCalculator {

    private static final String SEPARATOR = ",";

    public int add(String numbers) {
        return numbers.isEmpty()
                ? 0
                : List.of(numbers.split(SEPARATOR)).map(Integer::parseInt).sum().intValue();
    }
}'
  commit "green 2: parse numbers"
  # D2: red 3 passes the moment it is written (green 2 already did the work).
  test_class "$T1" "$T2" "$T3"; commit "red 3: returnsTheSumOfTwoNumbers [AC2]"
  prod 'import io.vavr.collection.List;

public class StringCalculator {

    private static final String SEPARATOR = ",";

    public int add(String input) {
        return input.isEmpty()
                ? 0
                : List.of(input.split(SEPARATOR)).map(Integer::parseInt).sum().intValue();
    }
}'
  commit "green 3: rename parameter"
  # D3: refactor 3 adds behaviour no AC and no test asked for.
  prod 'import io.vavr.collection.List;

public class StringCalculator {

    private static final String SEPARATOR = ",";

    public int add(String input) {
        if (input.contains("-")) {
            throw new IllegalArgumentException("negatives not allowed: " + input);
        }
        return input.isEmpty()
                ? 0
                : List.of(input.split(SEPARATOR)).map(Integer::parseInt).sum().intValue();
    }
}'
  commit "refactor 3: guard input"
  # D4: AC2 verified on a test that was never red.
  acceptance "returnsTheSumOfTwoNumbers [AC2], mvn verify passed" "verified"
  commit "KATA-1: AC2 verified"
fi
echo "$base..$(git rev-parse HEAD)"
