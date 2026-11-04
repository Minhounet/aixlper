# Debugging a JVM with jdb (JPDA/JDWP)

Read this when the investigation needs a debugger on a JVM: starting it with
JDWP, attaching locally or over SSH, and driving `jdb` one command at a time.
Rules (when a debugger is allowed, what to read, the note) stay in `SKILL.md`.

## One debugger per JVM

A JVM's JDWP port accepts **one** debugger at a time. When the IDE starts
the program with **Debug**, the IDE holds that connection and `jdb` can't
attach. To let `jdb` in, start the program with **Run** (not Debug) and add
the JDWP agent to its VM options yourself. The program then runs normally
and waits for a debugger on the port. The IDE can still attach later through
a "Remote JVM Debug" configuration, once `jdb` has detached.

## Starting the JVM with JDWP

The agent option:

```
-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=127.0.0.1:5005
```

- `suspend=n` for a **webservice**: it starts and serves; attach whenever.
- `suspend=y` for a **batch**: the JVM waits for the debugger before
  `main`, otherwise it finishes before the first breakpoint is set.
- `address=127.0.0.1:5005` listens on the local machine only. Use `*:5005`
  only inside a container, and publish it to the host's loopback only
  (`127.0.0.1:5005:5005`), never to the network.

Where the option goes:

| How it runs | Where |
|---|---|
| IntelliJ run configuration (Application, Spring Boot, JUnit) | Run configuration > Modify options > Add VM options; start it with **Run** |
| Plain jar / class | `java -agentlib:jdwp=... -jar app.jar` |
| Spring Boot with Maven | `mvn spring-boot:run -Dspring-boot.run.jvmArguments="-agentlib:jdwp=..."` |
| Spring Boot with Gradle | `gradle bootRun --debug-jvm` (port 5005, `suspend=y`) |
| Tests, Maven | `mvn test -Dtest=FooTest -Dmaven.surefire.debug` (port 5005, `suspend=y`) |
| Tests, Gradle | `gradle test --tests FooTest --debug-jvm` (port 5005, `suspend=y`) |
| Tomcat | `catalina.sh jpda start` (`JPDA_ADDRESS`, `JPDA_SUSPEND`) |
| Nuxeo in a container | already published, see `tonosaman-deploy`'s `references/nuxeo.md` |

Local variables need classes compiled with debug info. Maven and Gradle do
it by default; `Local variable information not available` means the build
turned it off (`-g:none`, `maven.compiler.debug=false`).

## Remote dev server: over an SSH tunnel

Start the remote JVM with `address=127.0.0.1:5005` (local to the server),
then tunnel it:

```bash
ssh -N -L 5005:127.0.0.1:5005 user@devserver &   # local 5005 -> server's 5005
```

and attach to `localhost:5005` as if it were local. Never open the JDWP
port in a firewall: it has no authentication. Not on production
(`SKILL.md`, section 2).

## Driving jdb: `scripts/jdb_session.py`

`jdb` is interactive: it expects each command after its prompt. Piping a
list of commands into it races: a `print` lands before the breakpoint is
hit and reads nothing. The script keeps one `jdb` attached in the
background and sends one command at a time, waiting for the answer. Python 3
standard library only; needs `jdb` on `PATH` (it ships with the JDK).

```bash
S=~/.claude/skills/tantei-debug/scripts/jdb_session.py   # wherever the skill is installed
$S start --attach localhost:5005 --sourcepath src/main/java
$S send "stop thread at com.example.OrderService:200"
# trigger the request (curl ...) or, for a batch, let it run:
$S send cont --until-event        # batch started with suspend=y
$S wait                           # webservice: after triggering the request
$S send "print order.getTotal()"
$S send next --until-event
$S send "clear com.example.OrderService:200"
$S send cont
$S stop                           # detach; the JVM keeps running
```

- Each reply prints only the new output, capped at 60 lines
  (`--max-lines`).
- A breakpoint hit that arrives between two commands is not lost: it comes
  back with the next reply.
- One session per JVM: pass `--state <file>` to tell them apart (default:
  `tantei-jdb.json` in the temp folder).
- When the batch ends, the session closes itself (`jdb ended ...`).
- It listens on a random `127.0.0.1` port and requires a token kept in the
  state file (mode 600), so other users on the machine can't send commands.

## Commands that matter

| Need | Command |
|---|---|
| Breakpoint on a line / at a method's entry | `stop at com.example.Foo:42` / `stop in com.example.Foo.bar` |
| Webservice: suspend only the thread that hits it | `stop thread at ...` (the script then selects that thread, since jdb doesn't) |
| Remove one / list them | `clear com.example.Foo:42` / `clear` |
| Resume / next line / into a call / out of the method | `cont` / `next` / `step` / `step up` (with `--until-event`) |
| Arguments and locals | `locals` |
| One value; a method call works | `print order.total`, `print list.size()`, `print list.get(3)` |
| Where the thread is | `where` |
| Stop when an exception is thrown | `catch java.lang.NullPointerException` |
| Stop when a field changes | `watch com.example.Foo.total` |
| Change a value to test a hypothesis (record it in the note) | `set order.total = 8` |

Names: a nested class is `Outer$Inner`, a lambda body is
`Outer.lambda$method$0`. A breakpoint on a class not loaded yet is
"deferred" and set when it loads. A line with no code can't take one.

## Pitfalls

- **No conditional breakpoints.** Stop, check the value, `cont`. For a
  loop, prefer a breakpoint after it, or `watch` on the field that changes.
- **Every request reaching the line stops**, even with `stop thread at`:
  other requests to the same code hang until you `clear` and `cont`. Other
  endpoints keep working. With plain `stop at`, the whole JVM stops.
- **`print` shows `toString()`**, quoted: an `Integer` 5 prints as `"5"`.
- **`dump` on an object graph and `threads` on a busy server** print a lot.
  Read the one value that decides instead.
- **Breakpoints don't survive a restart** of the JVM or of `jdb`: set them
  again from the note's `Next` line.
