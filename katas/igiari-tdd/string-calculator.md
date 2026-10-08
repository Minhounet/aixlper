Implement a `StringCalculator` class in package `com.example` with a method
`int add(String numbers)`.

Planned tests — StringCalculator.add:
1. shouldReturnZero_whenEmptyString — add("") == 0
2. shouldReturnNumber_whenSingleNumber — add("5") == 5
3. shouldReturnSum_whenTwoCommaSeparatedNumbers — add("1,2") == 3
4. shouldReturnSum_whenUnknownAmountOfNumbers — add("1,2,3,4") == 10
5. shouldReturnSum_whenNewlineSeparatesNumbers — add("1\n2,3") == 6
