#!/usr/bin/env python3
"""Time-to-first-prompt harness for a zsh config.

Starts `zsh -i` in a pseudo-terminal and stops the clock when the prompt
appears. With `probe`, it then waits 0.6 s and checks that the deferred pieces
(autosuggestions, syntax highlighting, compinit) have loaded.

usage: python3 bench/ptybench.py HOME_DIR RUNS [probe] [--glyph G] [--timeout S]

  HOME_DIR   directory containing the .zshrc to test (used as HOME and ZDOTDIR)
  RUNS       timed runs (one untimed warm-up run happens first)
  probe      also verify the deferred plugins loaded after idle
  --glyph G  text that marks "prompt is up" (default: the minimal theme's ❯).
             Use --glyph '' for any other prompt: the clock then stops when
             output has been quiet for 300 ms (adds noise; compare like with like).
  --timeout  seconds to wait for a prompt before giving up (default 10)

It never hangs: on a timeout it kills the shell, prints the last output it saw
(e.g. a question your config asked at startup), and exits non-zero.
"""
import argparse, os, pty, re, select, signal, statistics, sys, time

# Some prompts/plugins ask the terminal questions and wait for the answer.
QUERIES = {b"\x1b[6n": b"\x1b[1;1R", b"\x1b[c": b"\x1b[?1;2c"}
ANSI = re.compile(rb"\x1b\[[0-9;?]*[A-Za-z]|\x1b\][^\x07]*\x07")


def tail(buf, n=400):
    s = ANSI.sub(b"", buf).decode(errors="replace").strip()
    return s[-n:] if s else "(no output at all)"


def reap(pid, fd):
    try:
        os.write(fd, b"exit\n")
    except OSError:
        pass
    end = time.time() + 2
    while time.time() < end:
        try:
            done, _ = os.waitpid(pid, os.WNOHANG)
        except ChildProcessError:
            done = pid
        if done:
            break
        time.sleep(0.05)
    else:
        try:
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)
        except (ProcessLookupError, ChildProcessError):
            pass
    try:
        os.close(fd)
    except OSError:
        pass


def run(home, glyph, probe, timeout):
    env = dict(os.environ, HOME=home, ZDOTDIR=home, TERM="xterm-256color", PROMPT_KUBE="0")
    pid, fd = pty.fork()
    if pid == 0:
        os.execvpe("zsh", ["zsh", "-i"], env)
    t0 = time.perf_counter()
    buf, last_data, t_prompt = b"", None, None
    while time.perf_counter() - t0 < timeout:
        r, _, _ = select.select([fd], [], [], 0.05)
        if r:
            try:
                d = os.read(fd, 65536)
            except OSError:
                break
            if not d:
                break
            buf += d
            last_data = time.perf_counter()
            for q, a in QUERIES.items():
                if q in d:
                    os.write(fd, a)
        if glyph and glyph.encode() in buf:
            t_prompt = (time.perf_counter() - t0) * 1000
            break
        if not glyph and last_data and time.perf_counter() - last_data > 0.3:
            t_prompt = (last_data - t0) * 1000
            break
    result = None
    if t_prompt is not None and probe:
        time.sleep(0.6)
        os.write(fd, b"print -r -- PROBE:${+functions[_zsh_autosuggest_start]}:${+functions[_zsh_highlight]}:${+_comps}:${#_comps}\n")
        end, b2 = time.time() + 3, b""
        while time.time() < end:
            r, _, _ = select.select([fd], [], [], 0.2)
            if r:
                try:
                    b2 += os.read(fd, 65536)
                except OSError:
                    break
            m = re.search(rb"PROBE:(\d):(\d):(\d):(\d+)\r?\n", b2)
            if m:
                result = m.group(0).decode().strip()
                break
    reap(pid, fd)
    return t_prompt, result, buf


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("home")
    ap.add_argument("runs", type=int)
    ap.add_argument("probe", nargs="?")
    ap.add_argument("--glyph", default="❯")
    ap.add_argument("--timeout", type=float, default=10)
    a = ap.parse_args()
    home = os.path.expanduser(a.home)

    if not os.path.isfile(os.path.join(home, ".zshrc")):
        sys.exit(f"no .zshrc in {home} - run ./install.sh first, or pass a directory that has one")

    t, _, buf = run(home, a.glyph, False, a.timeout)  # warm-up (builds caches)
    if t is None:
        what = f"the prompt marker {a.glyph!r}" if a.glyph else "a quiet prompt"
        sys.exit(
            f"gave up after {a.timeout:.0f}s waiting for {what}.\n"
            f"last output from zsh:\n  {tail(buf)}\n"
            "If that shows a question (e.g. compinit insecure directories), answer it by fixing the cause.\n"
            "If your prompt is just different, re-run with --glyph '' ."
        )
    ts = []
    for _ in range(a.runs):
        t, _, buf = run(home, a.glyph, False, a.timeout)
        if t is None:
            sys.exit(f"a timed run gave up after {a.timeout:.0f}s; last output:\n  {tail(buf)}")
        ts.append(t)
    ts.sort()
    print(f"time-to-first-prompt median {statistics.median(ts):.0f} ms  min {ts[0]:.0f}  max {ts[-1]:.0f} (n={a.runs})")
    if a.probe:
        _, out, _ = run(home, a.glyph, True, a.timeout)
        print("after idle:", out or "probe got no answer")


if __name__ == "__main__":
    main()
