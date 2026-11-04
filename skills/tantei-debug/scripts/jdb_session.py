#!/usr/bin/env python3
"""Keep one jdb session alive across separate shell calls.

jdb is interactive: it prints a prompt and expects the next command only
after it. Piping a fixed list of commands into it races (a command lands
before the breakpoint is hit). This script holds jdb in the background and
sends one command at a time, waiting for its prompt.

  jdb_session.py start --attach localhost:5005 [--sourcepath src/main/java]
  jdb_session.py send "stop thread at com.example.Foo:42"
  (trigger the request / let the batch run)
  jdb_session.py wait                          # until breakpoint/step/exit
  jdb_session.py send next --until-event       # step, wait for "Step completed"
  jdb_session.py send "print order.total"
  jdb_session.py stop                          # detach; the target JVM keeps running

The background process listens on a random 127.0.0.1 port; the port and a
random token are kept in a state file readable only by you (--state,
default <tmp>/tantei-jdb.json). Use one --state per debugged JVM.

Only the output of each command is printed, capped by --max-lines.
Python 3 standard library only.
"""
import argparse
import json
import os
import re
import secrets
import socket
import subprocess
import sys
import tempfile
import threading
import time

DEFAULT_STATE = os.path.join(tempfile.gettempdir(), "tantei-jdb.json")
# "> " when no thread is current, "main[1] " / "http-nio-8080-exec-3[1] " when one is.
PROMPT = re.compile(r"(?:^|\n)(?:> |[^\s\[\]]+\[\d+\] )$")
EVENT = re.compile(r"Breakpoint hit:|Step completed:|Method (?:entered|exited):|"
                   r"Exception occurred:|Field \(.*\) is|The application exited|"
                   r"application (?:exited|disconnected)")


def serve(args):
    env = dict(os.environ)
    env.pop("JAVA_TOOL_OPTIONS", None)  # its banner would pollute every reply
    cmd = ["jdb", "-attach", args.attach]
    if args.sourcepath:
        cmd += ["-sourcepath", args.sourcepath]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, env=env, bufsize=0)
    buf = bytearray()
    lock = threading.Condition()

    def pump():
        while True:
            chunk = os.read(proc.stdout.fileno(), 4096)
            if not chunk:
                break
            with lock:
                buf.extend(chunk)
                lock.notify_all()
        with lock:
            lock.notify_all()

    threading.Thread(target=pump, daemon=True).start()

    # Output not yet returned to a caller starts here. A breakpoint hit that
    # arrives between two commands is returned with the next one, not lost.
    pos = [0]

    def wait(until_event, timeout, quiet=0.4):
        deadline = time.time() + timeout
        seen, changed = len(buf), time.time()
        start = pos[0]
        with lock:
            while True:
                text = buf[start:].decode(errors="replace")
                if len(buf) != seen:
                    seen, changed = len(buf), time.time()
                # jdb sometimes answers without a fresh prompt ("Nothing
                # suspended."): outside an event wait, 2s of silence ends it.
                idle = not until_event and text.strip() and time.time() - changed > 2
                done = idle or (PROMPT.search(text) and (not until_event or EVENT.search(text)))
                if proc.poll() is not None:
                    pos[0] = len(buf)
                    return text, "jdb ended (application exited or disconnected); session closed"
                if done:
                    size = len(buf)
                    lock.wait(quiet)  # let a trailing async line arrive
                    if len(buf) == size:
                        pos[0] = size
                        return text, None
                    continue
                left = deadline - time.time()
                if left <= 0:
                    pos[0] = len(buf)
                    return text, "timeout after %ss (the JVM may still be running; send again or 'suspend')" % timeout
                lock.wait(min(left, 0.5))

    def run(command, until_event, timeout):
        proc.stdin.write((command + "\n").encode())
        proc.stdin.flush()
        return wait(until_event, timeout)

    def select_stopped_thread(text):
        # "stop thread at" suspends only the hitting thread and leaves no
        # current thread ("> " prompt): locals, print, next and cont then
        # fail. Select it, so the next command works as after "stop at".
        hit = re.findall(r'(?:Breakpoint hit|Step completed): "thread=([^"]+)"', text)
        if not hit or not text.rstrip(" ").endswith(">"):
            return ""
        name = hit[-1]
        threads, _ = run("threads", False, 10)
        threads = threads[threads.find("Group "):] if "Group " in threads else threads
        m = re.search(r"\)((?:0x)?[0-9a-f]+)\s+" + re.escape(name) + r"\s", threads)
        if not m:
            return "[driver] could not find thread %s; use 'threads' then 'thread <id>'\n" % name
        run("thread " + m.group(1), False, 10)
        return "[driver] current thread: %s (%s)\n" % (name, m.group(1))

    out, err = wait(False, 30)
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.bind(("127.0.0.1", 0))
    srv.listen(1)
    token = secrets.token_hex(16)
    if not err:
        fd = os.open(args.state, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as f:
            json.dump({"port": srv.getsockname()[1], "token": token}, f)
    # Tell the parent we are ready (or not).
    sys.stdout.write(json.dumps({"out": out, "err": err}) + "\n")
    sys.stdout.flush()
    if err:
        return
    try:
        while proc.poll() is None:
            conn, _ = srv.accept()
            try:
                req = json.loads(conn.makefile().readline())
            except ValueError:
                conn.close()
                continue
            if not secrets.compare_digest(str(req.get("token")), token):
                conn.close()  # anyone else on this machine: ignored
                continue
            if req["cmd"] == "__stop__":
                proc.stdin.write(b"exit\n")
                proc.stdin.flush()
                proc.wait(10)
                conn.sendall((json.dumps({"out": "detached", "err": None}) + "\n").encode())
                conn.close()
                break
            if req["cmd"] is None:  # "wait": no command, just the next event
                out, err = wait(True, req["timeout"])
            else:
                out, err = run(req["cmd"], req["until_event"], req["timeout"])
            if not err:
                out += select_stopped_thread(out)
            conn.sendall((json.dumps({"out": out, "err": err}) + "\n").encode())
            conn.close()
    finally:
        srv.close()
        if os.path.exists(args.state):
            os.unlink(args.state)


def cap(text, max_lines):
    lines = text.rstrip("\n").splitlines()
    if len(lines) > max_lines:
        lines = lines[:max_lines] + ["... (%d more lines cut; narrow the command)" % (len(lines) - max_lines)]
    return "\n".join(lines)


def request(state, payload, timeout):
    try:
        with open(state) as f:
            st = json.load(f)
        c = socket.create_connection(("127.0.0.1", st["port"]), timeout=timeout + 15)
    except (OSError, ValueError, KeyError):
        sys.exit("no jdb session for %s: run 'start' first" % state)
    payload["token"] = st["token"]
    c.sendall((json.dumps(payload) + "\n").encode())
    line = c.makefile().readline()
    if not line:
        sys.exit("the jdb session closed without answering")
    return json.loads(line)


def show(reply, max_lines):
    print(cap(reply["out"], max_lines))
    if reply["err"]:
        sys.exit(reply["err"])


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--state", default=DEFAULT_STATE, help="session state file (one per debugged JVM)")
    p.add_argument("--max-lines", type=int, default=60, help="cap on the lines printed per reply")
    sub = p.add_subparsers(dest="action", required=True)
    s = sub.add_parser("start", help="attach jdb to a JVM started with JDWP")
    s.add_argument("--attach", required=True, help="host:port of the JDWP agent")
    s.add_argument("--sourcepath", help="source roots, for 'list' (e.g. src/main/java)")
    v = sub.add_parser("_serve")  # internal: the background process
    v.add_argument("--attach")
    v.add_argument("--sourcepath")
    d = sub.add_parser("send", help="send one jdb command and print its output")
    d.add_argument("cmd")
    d.add_argument("--until-event", action="store_true",
                   help="after cont/step/next: wait for the breakpoint, step or exit")
    d.add_argument("--timeout", type=float, default=30)
    w = sub.add_parser("wait", help="send nothing; wait for the next breakpoint/step/exit "
                                    "(after triggering a request or letting a batch run)")
    w.add_argument("--timeout", type=float, default=60)
    sub.add_parser("stop", help="detach jdb; the debugged JVM keeps running")
    args = p.parse_args()

    if args.action == "start":
        extra = {"start_new_session": True}
        if os.name == "nt":
            extra = {"creationflags": subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP}
        child = subprocess.Popen([sys.executable, os.path.abspath(__file__), "--state", args.state,
                                  "_serve", "--attach", args.attach]
                                 + (["--sourcepath", args.sourcepath] if args.sourcepath else []),
                                 stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                 stderr=subprocess.DEVNULL, text=True, **extra)
        show(json.loads(child.stdout.readline() or '{"out": "", "err": "jdb did not start (is jdb on PATH?)"}'),
             args.max_lines)
    elif args.action == "_serve":
        serve(args)
    elif args.action == "send":
        show(request(args.state, {"cmd": args.cmd, "until_event": args.until_event,
                                  "timeout": args.timeout}, args.timeout), args.max_lines)
    elif args.action == "wait":
        show(request(args.state, {"cmd": None, "until_event": True,
                                  "timeout": args.timeout}, args.timeout), args.max_lines)
    elif args.action == "stop":
        print(request(args.state, {"cmd": "__stop__", "until_event": False, "timeout": 10}, 10)["out"])


if __name__ == "__main__":
    main()
