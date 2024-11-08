# Bash Strict Mode

## Introduction

In this text, I explain how I use the Bash shell. Of course, there are several other ways to use Bash; this is my personal point of view.

If you think there is something wrong or could be improved, please create an issue in this GitHub project. Thank you!

## Bash Strict Mode: Activating it

I use this at the top of my Bash scripts:

```bash
#!/bin/bash
trap 'echo "Warning: A command has failed. Exiting the script. Line was ($0:$LINENO): $(sed -n "${LINENO}p" "$0")"; exit 3' ERR
set -Eeuo pipefail
```

Let's have a closer look:

```bash
#!/bin/bash
```

This makes sure we use the Bash shell, and not a different shell. Writing portable shell scripts is more complicated, and I want to get things done, so I use Bash and its handy features.

---

This line prints a warning if the shell script terminates because a command returned a non-zero exit code:

```
trap 'echo "Warning: A command has failed. Exiting the script. Line was ($0:$LINENO): $(sed -n "${LINENO}p" "$0")"; exit 3' ERR
```

It shows the line that caused the shell script to exit and exits with `3`.

Why `3`? I use that according to the [Nagios Plugin Return Codes](https://nagios-plugins.org/doc/guidelines.html), although I don't use Nagios anymore. `3` means "Unknown."

---

```bash
set -Eeuo pipefail
```

`-E`: **ERR Trap Inheritance** Ensures that the ERR trap is inherited by shell functions, command substitutions, and subshells.

`-e`: **Exit on Error** Causes the script to immediately exit if any command returns a non-zero exit status unless that command is followed by `||` to explicitly handle the error.

`-u`: **Undefined Variables** Treats the use of undefined variables as an error, causing the script to exit.

`-o pipefail`: **Pipeline Failure** Ensures that a pipeline (a series of commands connected by `|`) fails if any command within it fails, rather than only failing if the last command fails.

## Bash Strict Mode: Errors should never pass silently

Quoting the [Zen of Python](https://peps.python.org/pep-0020/):

> Errors should never pass silently.
> Unless explicitly silenced.

I think the above strict mode ensures that errors don’t go unnoticed and prevents scripts from running into unexpected issues. I prefer a command to fail and show me the failed line, rather than the default behavior of bash (continuing with the next line in the script).

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

If you use strict mode, then you will get:

```terminal
grep: bar.txt: No such file or directory
Warning: A command has failed. Exiting the script. Line was (/home/user/tmp/t.sh:5): grep foo bar.txt >out.txt
```

And the exit status of the script will be `3`, which indicates an error.

## Bash Strict Mode: Use it blindly?

If you post about `set -e` on the Bash subreddit, you get an automated comment like this:

[Don't blindly use set -euo pipefail.](https://www.reddit.com/r/commandline/comments/g1vsxk/comment/fniifmk/)

The link explains why you should not use `set -Eeuo pipefail` everywhere.

I disagree. The strict mode has consequences, and dealing with these consequences requires some extra typing. But typing is not the bottleneck. I prefer to type a bit more if it results in more reliable Bash scripts.

## Bash Strict Mode: Handle unset variables

This line would fail in strict mode if `VAR` is not set:

```bash
echo "${VAR?Variable is not set or is empty}"
```

You can work around that easily by setting a default value:

```bash
VAR="${VAR:-default_value}"
echo "${VAR?Variable is not set or is empty}"
```

## Bash Strict Mode: Handle non-zero exit codes

Non-zero exit codes often indicate an error, but not always.

The command `grep` returns `0` if a line matches, otherwise `1`.

For example, you want to filter comments into a file:

```bash
echo -e "foo\n#comment\nbar" | grep '^#' >comments.txt
```

The code above works in strict mode because there is a match. But it fails if there is no comment.

In that case, I expect `comments.txt` to be an empty file, and the script should not fail but continue to the next line.

This code fails in strict mode:

```bash
echo -e "foo\nbar" | grep '^#' >comments.txt
```

Workaround:

```bash
echo -e "foo\nbar" | { grep '^#' >comments.txt || true; }
```

With this pattern, you can easily ignore non-zero exit statuses.

## Bash Strict Mode: Conclusion

My conclusion: Use strict mode!

## General Bash Hints: Use sub-scripts instead of functions

I don't like writing functions in Bash scripts because functions return a plain string.

You can't easily distinguish between a successful function call and a call that failed.

Maybe I was brain-washed by Golang :-)

That's why I prefer to write a small second or third script (with strict mode) and call that.

If I want to distinguish between a successful function call and a call that failed, I can do it easily like this:

```bash
if ./my-small-script.sh; then
    echo "Success"
else
    echo "Failure"
fi
```

## Misc: Shell vs Bash

I think writing portable shell scripts is unnecessary in most cases. It is like trying to write a script that works in both Python and Ruby interpreters at the same time.

## shfmt

There is a handy shell formatter: [shfmt](https://github.com/mvdan/sh#shfmt) and a [VS Code plugin shell-format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format).

## ShellCheck

There is [ShellCheck](https://github.com/koalaman/shellcheck) and a [VS Code plugin for ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck) which helps you find errors in your script.

ShellCheck can recognize several types of incorrect quoting. It warns you about every unquoted variable. Since it is not much work, I follow ShellCheck's recommendations.


## Fish Shell

BTW, I use the Fish Shell for interactive usage on the terminal, and for scripts I use Bash.

## /r/bash

Thank you to [https://www.reddit.com/r/bash/](https://www.reddit.com/r/bash/)

I got several good hints there.

# More

* [Thomas WOL: Working out Loud](https://github.com/guettli/wol)
