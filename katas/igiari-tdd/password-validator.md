Implement a `PasswordValidator` class in package `com.example` with a method
`validate(String password)`. A rejected password is a normal outcome, not an
error: the result carries every rule the password breaks, and validation
never throws. Pick the return type that fits.

Planned tests — PasswordValidator.validate:
1. shouldAccept_whenPasswordMeetsEveryRule — validate("abcdef12") is valid
2. shouldReject_whenShorterThanEight — validate("abc12") is invalid with "too short"
3. shouldReject_whenNoDigit — validate("abcdefgh") is invalid with "missing digit"
4. shouldReportBoth_whenShortAndNoDigit — validate("abc") is invalid with "too short" and "missing digit"
