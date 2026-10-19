---
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

You're starting my approved shogun brief in **live** mode; I'm away and
nobody will answer during the run. The implementer hasn't started yet.

```markdown
# Brief: top-authors
mode: live
question: can plain Java (JDK 21, no CSV library) compute the top 10 authors of our export data/docs.csv in under 1s?
success: the jar prints 10 lines `<count>\t<author>` descending, then `elapsed_ms=<n>` with n < 1000; counts match an independent check with Unix tools
skills: tonosaman-deploy
scope: this repository only
allowed: Maven; JUnit 5 as a test dependency; Docker
out of bounds: any third-party runtime dependency; modifying data/docs.csv
budget: $4
branch: poc/top-authors
```

`wc -l data/docs.csv` gives 100001. `head -12 data/docs.csv`:

```
id,title,author,created
0,Report 0,author_0000,2026-01-10
1,"Report 1, part 1",author_0012,2026-02-11
2,Report 2,author_0001,2026-03-12
3,Report 3,author_0000;author_0017,2026-04-13
4,"Report 4, part 4",author_0003,2026-05-14
5,Report 5,author_0002,2026-06-15
6,Report 6,author_0251,2026-07-16
7,Report 7,author_0001;author_0005,2026-08-17
8,"Report 8, part 1",author_0000,2026-09-18
9,Report 9,author_0040,2026-01-10
10,Report 10,author_0007,2026-02-11
```

Run it: say what you do first, what you hand the implementer, and what you'd
put in the report about it. I approved the brief and won't answer anything
until the run is over. (No repository here, nothing to run; answer in
your reply.)
