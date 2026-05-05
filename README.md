# Bash Strict Mode

## Introduction

In this text, I explain how I use the Bash shell. Of course, there are several other ways to use
Bash; this is my personal point of view.

If you think there is something wrong or could be improved, please create an issue in this GitHub
project. Thank you!

This text contains two parts: Bash Strict Mode and General Hints and Opinions.

## Part 1: Bash Strict Mode

Bash strict mode refers to a set of options and practices used in Bash scripting to make scripts
more robust, reliable, and easier to debug. By enabling strict mode, you can prevent common
scripting errors, detect issues early, and make your scripts fail in a controlled way when something
unexpected happens.

## Bash Strict Mode: Activating It

I use this at the top of my Bash scripts:

```bash
#!/usr/bin/env bash
# Bash Strict Mode: https://github.com/guettli/bash-strict-mode
trap 'echo -e "\n🤷 🚨 🔥 Warning: A command has failed. Exiting the script. Line was ($0:$LINENO): $(sed -n "${LINENO}p" "$0" 2>/dev/null || true) 🔥 🚨 🤷 "; exit 3' ERR
set -Eeuo pipefail
```

Let's have a closer look:

```bash
#!/usr/bin/env bash
```

This makes sure we use the Bash shell and not a different shell. Writing portable shell scripts is
more complicated, and I want to get things done, so I use Bash and its handy features.

The command `/usr/bin/env` looks up `bash` in `$PATH`. This is handy if `/bin/bash` is outdated on
your system, and you installed a new version in your home directory.

---

This line prints a warning if the shell script terminates because a command returned a non-zero exit
code:

```bash
trap 'echo "Warning: A command has failed. Exiting the script. Line was ($0:$LINENO): $(sed -n "${LINENO}p" "$0")"; exit 3' ERR
```

It shows the line that caused the shell script to exit and exits with `3`.

Why `3`? I use that according to the [Nagios Plugin Return
Codes](https://nagios-plugins.org/doc/guidelines.html), although I don't use Nagios anymore. `3`
means "Unknown."

---

```bash
set -Eeuo pipefail
```

`-E`: **ERR Trap Inheritance** Ensures that the ERR trap is inherited by shell functions, command
substitutions, and subshells.

`-e`: **Exit on Error** Causes the script to immediately exit if any command returns a non-zero exit
status unless that command is followed by `||` to explicitly handle the error.

`-u`: **Undefined Variables** Treats the use of undefined variables as an error, causing the script
to exit.

`-o pipefail`: **Pipeline Failure** Ensures that a pipeline (a series of commands connected by `|`)
fails if any command within it fails, rather than only failing if the last command fails.

## Bash Strict Mode: Errors Should Never Pass Silently

Quoting the [Zen of Python](https://peps.python.org/pep-0020/):

> Errors should never pass silently. Unless explicitly silenced.

I think the above strict mode ensures that errors don’t go unnoticed and prevents scripts from
running into unexpected issues. I prefer a command to fail and show me the failed line, rather than
the default behavior of Bash (continuing with the next line in the script).

## Bash Strict Mode: Simple Example

Imagine you have a simple script:

```bash
grep foo bar.txt >out.txt
echo "all is fine"
```

The script expects a file called `bar.txt`. But what happens if that file does not exist?

If the file does not exist, you get this output (without strict mode):

```terminal
❯ ~/tmp/t.sh
grep: bar.txt: No such file or directory
all is fine
```

The script terminates with a zero (meaning "OK") exit status, even though something went wrong.

That's something I would like to avoid.

With strict mode enabled, you will get:

```terminal
grep: bar.txt: No such file or directory
Warning: A command has failed. Exiting the script. Line was (/home/user/tmp/t.sh:5): grep foo bar.txt >out.txt
```

And the exit status of the script will be `3`, which indicates an error.

## Bash Strict Mode: Use It Blindly?

If you post about `set -e` on the Bash subreddit, you get an automated comment like this:

[Don't blindly use set -euo
pipefail.](https://www.reddit.com/r/commandline/comments/g1vsxk/comment/fniifmk/)

The link explains why you should not use `set -Eeuo pipefail` everywhere.

I disagree. Strict mode has consequences, and dealing with these consequences requires some extra
typing. But typing is not the bottleneck. I prefer to type a bit more if it results in more reliable
Bash scripts.

## Bash Strict Mode: Handle Unset Variables

This would fail in strict mode if `FOO` is not set:

```bash
if [ -z "$FOO" ]; then
    echo "Env var FOO is not set. Doing completely different things now ..."
    do_different_things
fi
```

Output:

> line N: FOO: unbound variable

You can work around that easily by setting the value to the empty string:

```bash
if [ -z "${FOO:-}" ]; then
    echo "Env var FOO is not set. Doing completely different things now ..."
    do_different_things
fi
```

## Bash Strict Mode: Handle Non-Zero Exit Codes

Non-zero exit codes often indicate an error, but not always.

The command `grep` returns `0` if a line matches, otherwise `1`.

For example, you want to filter comments into a file:

```bash
echo -e "foo\n#comment\nbar" | grep '^#' >comments.txt
```

The code above works in strict mode because there is a match. But it fails if there is no comment.

In that case, I expect `comments.txt` to be an empty file, and the script should not fail but
continue to the next line.

This code fails in strict mode:

```bash
echo -e "foo\nbar" | grep '^#' >comments.txt | some-other-command
```

Workaround:

```bash
echo -e "foo\nbar" | { grep '^#' >comments.txt || true; } | some-other-command
```

With this pattern, you can easily ignore non-zero exit statuses.

Or use `perl` or `sed` instead of `grep`, because they do not use a non-zero exit code if nothing was found.

`my-command | grep -vP 'pattern1|pattern2'` alternatives:

Perl: `my-command | perl -ne 'print unless /pattern1|pattern2/'`

Sed: `my-command | sed -E '/pattern1|pattern2/d'` (but \s \w \d \b and some other [PCRE](https://en.wikipedia.org/wiki/Perl_Compatible_Regular_Expressions) syntax is not available)


Example:

> You want to ignore a deprecation warning on stderr and the non-zero exit code of `my-command`:

```bash
some_output=$(my-command 2> >(sed '/Warning:.*is deprecated/d' >&2) || true)
```

## Bash Strict Mode: Exit Status

In most cases you just want to know: Was the command successful or not?

If you want to know the exit code (`$?`) then you can use that pattern:

```bash
if some-command; then
    code=0
else
    code=$?
fi
echo $code
```

## Bash Strict Mode: Avoid `&&`

When using the Bash Strict Mode, you want commands which fail (exit status not 0) to fail. Execution
of the script should be stopped.

Imagine there are two commands combined with `&&`. The non-zero exit status does not get noticed.

(`false` is a command which has exit status 1)

```bash
false && false
```

To avoid that pitfall, avoid `&&` and use two lines instead:

```bash
false
false
```

If you use two lines, then Bash in strict mode will fail on the first non-zero exit status (here the
first `false`):

## Bash Strict Mode: `head` Can Give You a Headache

This will fail:

```bash
random_id=$(tr -dc 'a-z0-9' </dev/urandom | head -c 7)
```

Explanation: When `head` closes its output after reading 7 bytes, `tr` is still writing, but
suddenly its output pipe is gone. This causes `tr` to receive a SIGPIPE and exit with a non-zero
status (usually 141).

This will work:

```bash
random_id=$(tr -dc 'a-z0-9' </dev/urandom | head -c 7 || true)
```

Thanks to Reddit user "aioeu" for the explanation: [cat file | head fails, when using "strict mode"
: r/bash](https://www.reddit.com/r/bash/comments/1l8tjbx/comment/mx7b8ts/)

## Bash Strict Mode: How to Handle Non-Zero Exit Status in `if`

If I want to distinguish between a successful command and non-zero:

```bash
if ./my-small-script.sh; then
    echo "Success"
else
    echo "Failure"
fi
```

## Bash Strict Mode: Conclusion

My conclusion: Use strict mode!

## Part 2: General Hints and Opinions

## To Bash or Not to Bash

Use the right tool. But which tool is the right one?

I use Bash if I need to execute several Linux command-line tools (one after the other) to achieve my
goal.

This means the script is straightforward. There are no functions, only a few "if/else" statements
(mostly for error handling) and a few loops.

For example, provisioning a vanilla virtual machine into a custom virtual machine to meet specific
requirements is such a task. Bash fits perfectly for that.

Bash is not a real programming language. For applications, it’s better to use Golang or Python (in
my opinion).

## General Bash Hints: Avoid `find ... | while read -r file` — Use `while read -r file; do ...; done < <(find ...)`

Imagine you want to collect errors like this, and fail after the loop if the string error is not
empty:

```bash
errors=""
find ... | while read -r file; do
    if ...; then
        errors="$errors ..."
    fi
done

if [ -n "$errors" ]; then
    echo "failed: $errors"
    exit 1
fi
```

This won't work because the block in the loop is executed in a new subshell. Variables set inside a
subshell are not accessible outside.

If you do it like this, it works:

```bash
while read -r file; do
    ...
done < <(find ... )
```

## General Bash Hints: Use Sub-scripts Instead of Functions

I prefer to write a second (or third) Bash script instead of writing functions.

This provides a clean interface between your primary and secondary script.

## General Bash Hints: Concurrency

If you want to execute two tasks concurrently, you can do it like this:

```bash
# Bash Strict Mode: https://github.com/guettli/bash-strict-mode
trap 'echo -e "\n🤷 🚨 🔥 Warning: A command has failed. Exiting the script. Line was ($0:$LINENO): $(sed -n "${LINENO}p" "$0" 2>/dev/null || true) 🔥 🚨 🤷 "; exit 3' ERR
set -Eeuo pipefail

{
    echo task 1
    sleep 1
} & task1_pid=$!

{
    echo task 2
    sleep 2
} & task2_pid=$!

# Wait each PID on its own line so you get each child's exit status.
wait "$task1_pid"
wait "$task2_pid"

echo end
```

Why wait each PID separately?

- You must wait to reap background children and avoid zombies.
- `wait pid1 pid2` will wait for both PIDs, but its exit status is the exit status of the last PID
  waited for. This means an earlier background job can fail yet the combined `wait` can still return
  success if the last job succeeds — not what you want if you need to detect failures reliably.

## Makefiles

Makefiles are similar to the strict mode. Let's look at an example:

```makefile
target: prerequisites
    recipe-command-1
    recipe-command-2
    recipe-command-3
```

If `recipe-command-1` fails the Makefile stops, and does not execute `recipe-command-2`.

The syntax in a Makefile looks like shell, but it is not.

As soon as the commands in a Makefile get complicated, I recommend to keep it simple:

```makefile
target: prerequisites
    script-in-bash-strict-mode.sh
```

Instead of trying to understand the syntax of Makefile (for example `$(shell ...)`), I recommend to
call a Bash script.

A Bash script has the benefit that formatting (shfmt) and ShellCheck are available in the editor.

I highly recommend to switch from Makefile to [Taskfile](https://taskfile.dev/).

## Perl Compatible Regular Expressions: `grep -P`

Unfortunately there are several different flavours of regular expressions.

Instead of learning the old regular expressions, I recommend to use the Perl Compatible Regular
Expressions.

The good news: `grep` supports PCRE with the `-P` flag. I suggest to use it.

## I Don't Use `awk`

I avoid using `awk` because I am not familiar with its syntax, and from 1996 up to now, this has
worked out fine for me.

The only time I use `awk` is when the input is split by whitespace and the length varies.

Example: I want to print the second column:

```bash
command-which-prints-columns | awk '{print $2}'
```

From time to time, I use `perl` one-liners.

Update: In the age of AI, I sometimes accept lines created by an AI agent which use `awk`.

## Shell vs Bash

I think writing portable shell scripts is unnecessary in most cases. It is like trying to write a
script that works in both, the Python and the Ruby interpreters at the same time. Don't do it. Be
explicit and write a Bash script (not a shell script).

## shfmt

There is a handy shell formatter: [shfmt](https://github.com/mvdan/sh#shfmt) and a [VS Code plugin
shell-format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format).

## ShellCheck

There is [ShellCheck](https://github.com/koalaman/shellcheck) and a [VS Code plugin for
ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck) which helps
you find errors in your script.

ShellCheck can recognize several types of incorrect quoting. It warns you about every unquoted
variable. Since it is not much work, I follow ShellCheck's recommendations.

## Provisioning a machine: Fancy Tools or boring Bash?

There are several well known tools for provisioning a machine: Ansible, SaltStack, Puppet, Chef, ...

All of them have their learning costs.

It depends on the environment, but maybe a Bash script in strict mode is easier to maintain.

Some years ago, we used SaltStack to provision and update a lot of virtual machines. We wasted so
much time because things did not work as expected, or error messages got swallowed. In hindsight, we
would have been much faster if we had taken the pragmatic approach (Bash) instead of being proud to
use the same tools as big tech companies.

## Avoid Fancy CI or GitHub Actions

GitHub Actions (or similar CI tools) have a big drawback: You can't execute them on your local
device.

I try to keep our GitHub Actions simple: the YAML config calls Bash scripts, which I can also
execute locally.

You can use containers to ensure that all developers have the same environment.

## Interactive Shell

This article is about Bash scripting.

For **interactive** I use:

- zsh (not 100% happy, but fish shell is too different)
- [Starship](https://starship.rs/) for the prompt.
- [Atuin](https://github.com/atuinsh/atuin) for the shell history.
- Direnv: [How I use Direnv](https://github.com/guettli/How-I-use-direnv/)
- Nix: [Switching to Nix](https://github.com/guettli/switching-to-nix)
- VSCode
- [vscode Direnv Extension](https://marketplace.visualstudio.com/items?itemName=mkhl.direnv)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fd find](https://github.com/sharkdp/fd)
- [CopyQ](https://hluk.github.io/CopyQ/) Clipboard Manager
- [Activity Watch](https://activitywatch.net/) Automatic time tracker
- Ubuntu LTS.

Usually don't use `ripgrep` and `fd` in Bash scripts, because these are not available on most
systems.

## `set -x` Can Reveal Credentials

Imagine you use credentials like this:

```bash
echo "$OCI_TOKEN" | oras manifest fetch --password-stdin $IMAGE_URL
```

If you use `set -x`, then every line gets printed. This will print the **content** of $OCI_TOKEN.

This can reveal your secrets in the logs.

Rule of thumb: Never use `set -x` in a script. Except temporarily for debugging, but do not commit
it to the source code repo.

Your text is clear and has a great personal tone, but a few tweaks to the phrasing and flow will
make it sound even more professional. Here is a polished version:

## Nix: Defining Dependencies with Flakes

In the Python world, we have **virtual environments**. They are incredibly handy because they allow
you to maintain multiple environments, each with its own custom dependencies and specific versions.

Almost every programming language has a similar concept, but what about **Bash scripts**? While you
can manually modify your `PATH`—and for small projects, that might work—it quickly becomes difficult
to manage.

If you want a **declarative** way to define dependencies, [Nix
Flakes](https://nixos.wiki/wiki/Flakes) is the best solution I’ve found.

Admittedly, some parts of Nix can be difficult for newcomers to grasp. However, Large Language
Models (LLMs) and your favorite search engine support you.

Personally, I think it’s time to say "goodbye" to Makefiles and scripts that manually install tools.

Should you install *everything* via Nix?

My approach is to install the **base tools** via Nix and then let language-specific package managers
handle the version pinning:

- **Go:** `go.mod` / `go.sum`
- **JS:** `package.json` / `package-lock.json`
- **Ruby:** `Gemfile` / `Gemfile.lock`
- ....

More about that: [Switching to Nix](https://github.com/guettli/switching-to-nix)

## Direnv and Nix

[direnv](https://direnv.net/) is great to get virtual environments.

I use it Direnv together with Nix like this:

`.envrc` file:

```bash
# .envrc
# shellcheck shell=bash

# https://github.com/nix-community/nix-direnv
use flake

export FOO=BAR
# ...
```

When I enter the directory with `cd`, then the Nix env gets activated.

To auto-enter the nix environment (for example for coding agents - they do not evaluate `.envrc`):

At the top my Bash scripts:

```bash
#!/usr/bin/env bash
#...

if [[ -z ${DIRENV_DIR:-} ]]; then
    echo "not in direnv; re-running via direnv"
    exec direnv exec . "$0" "$@"
fi

# ...

```

To make this work, you should install `direnv` and `nix-direnv`, so that it is available before you
enter the Nix env.

You can do that like this:

```bash
nix profile add nixpkgs#direnv nixpkgs#nix-direnv
```

This will install the binaries into `$HOME/.nix-profile/bin`.

This way I have all I want to replace Makefiles and Docker containers which provide isolated build
environments:

- Nix Flakes for pinning dependencies
- Direnv to enter the "virtual environment" and set env vars
- Scripts can be executed from outside, and the env gets entered automatically.

No Docker, no Makefiles .... I love it.

More about that: [How I use Direnv](https://github.com/guettli/How-I-use-direnv/)

## /r/bash

Thank you to [https://www.reddit.com/r/bash/](https://www.reddit.com/r/bash/)

I got several good hints there.

## More

- [How I use Direnv](https://github.com/guettli/How-I-use-direnv/)
- [Switching to Nix](https://github.com/guettli/switching-to-nix)
- [Taskfile is great](https://github.com/guettli/taskfile-is-great)
- [Thomas WOL: Working out Loud](https://github.com/guettli/wol)
