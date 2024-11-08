# Bash Strict Mode

## Introduction

In this text I explain how I use the Bash shell. Of course there are several other ways to use
the Bash, this is my personal point of view.

If you think there is something wrong, or could be improved, please create an issue in this Github project. Thank you!

## Bash Strict Mode: Activating it

I use that at the top of my Bash scripts:

```bash
#!/bin/bash
trap 'echo "Warning: A command has failed. Exiting the script. Line was ($0:$LINENO): $(sed -n "${LINENO}p" "$0")"; exit 3' ERR
set -Eeuo pipefail

```

Let's have a closer look:

```bash
#!/bin/bash
```  

This makes sure we use the Bash shell, and not a different shell. Writing portable shell scripts is way more complicated, and I want to get things done, so I use the Bash and its handy features.

---

This line prints a warning if the shell script gets terminated because a command returned a non-zero exit code:

```
trap 'echo "Warning: A command has failed. Exiting the script. Line was ($0:$LINENO): $(sed -n "${LINENO}p" "$0")"; exit 3' ERR
```

It shows the line which caused the shell script to exit, and it exists with `3`.

Why `3`? I use that according to the [Nagios Plugin Return Codes](https://nagios-plugins.org/doc/guidelines.html), although I don't use Nagios any more. `3` means "Unknown".

---

```bash
set -Eeuo pipefail
```

`-E`: **ERR Trap Inheritance** Ensures that the ERR trap is inherited by shell functions, command substitutions, and subshells.

`-e`: **Exit on Error** Causes the script to immediately exit if any command returns a non-zero exit status, unless that command is followed by || to explicitly handle the error.

`-u` **Undefined Variables** Treats the use of undefined variables as an error, causing the script to exit.

`-o pipefail` **Pipeline Failure** Ensures that a pipeline (a series of commands connected by `|`) fails if any command within it fails, rather than only failing if the last command fails.

## Bash Strict Mode: Errors should never pass silently.

Quoting the [Zen of Python](https://peps.python.org/pep-0020/):

> Errors should never pass silently.
> Unless explicitly silenced.

I think the above strict mode ensures that errors don’t go unnoticed and prevents scripts from running into unexpected issues. I prefer a command to fail, and showing me the failed line, to the default mode of bash (continue with the next line in the script).

# Bash Strict Mode: Simple Example

Imagine you have simple script:

```bash
grep foo bar.txt >out.txt
echo "all is fine"
```

The script expects that there is a file called `bar.txt`. But what happens if that file does not exist?

If the file does not exist, you get this output (without strict mode):

```terminal
❯ ~/tmp/t.sh
grep: bar.txt: No such file or directory
all is fine
```
The script terminates with a zero (means "OK") exit status, although there was something wrong.

That's something I would like to avoid.

If you use the strict mode, then you will get:

```terminal
grep: bar.txt: No such file or directory
Warning: A command has failed. Exiting the script. Line was (/home/user/tmp/t.sh:5): grep foo bar.txt >out.txt
```

And the exit status of the script will be `3`, which indicates an error.

## Bash Strict Mode: Use it blindly?

If you post about `set -e`, on the subreddit of Bash, you get an automated comment like this:

[Don't blindly use set -euo pipefail.](https://www.reddit.com/r/commandline/comments/g1vsxk/comment/fniifmk/)

The link explains why you should not use `set -Eeuo pipefail` everywhere.

I disagree. The strict mode has consequences, and dealing with these consequences needs some 
more typing. But typing is not the bottle-neck. I prefer to type a bit more, if that
results in more reliable Bash scripts.

## Bash Strict Mode: Handle unset variables

This line would fail in strict mode, if VAR is not set:

```bash
echo "${VAR?Variable is not set or is empty}"
```

You can work-around that easily by setting a default value:

```bash
VAR="${VAR:-default_value}"
echo "${VAR?Variable is not set or is empty}"
```

## Bash Strict Mode: Handle non-zero exit codes

Non-zero exit codes often indicate an error, but not always.

The command `grep` returns `0` if a line matched, otherwise `1`.

For example, you want to filter comments into a file:

```bash
echo -e "foo\n#comment\nbar" | grep '^#' >comments.txt
```

Above code works in strict mode, because there is a match. But it fails, if there is not comment.

In that case I expect that `comments.txt` is an empty file, and the script should not fail, but
continue to the next line.

This code fails in strict mode:

```bash
echo -e "foo\nbar" | grep '^#' >comments.txt
```

Work-around:

```bash
echo -e "foo\nbar" | { grep '^#' >comments.txt || true; }
```

With this pattern you can easily ignore non-zero exit statues.

## Bash Strict Mode: Conclusion

My conclusion: Use strict mode!

## General Bash Hints: Use sub scripts instead of functions

I don't like writing functions in Bash scripts, because functions return a plain string.

You can't easily distinguish between an sucessful function call and a call which failed.

That's why I prefer to write a small second/third script (with strict mode), and call that.

If I want to distinguish between a sucessful function call and a call which failed,
I can do that easily like this: 

```bash
if ./my-small-script.sh; then
    echo "Success"
else
    echo "Failure"
fi
```

## Misc: Shell vs Bash

I think writing portable shell scripts is useless in most cases. It is like trying to write a script which works in the Python and Ruby interpreter at the same time.

## shfmt

There is a handy shell formatter: [shfmt](https://github.com/mvdan/sh#shfmt) and [vscode plugin shell-format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format)

## ShellCheck

There is [ShellCheck](https://github.com/koalaman/shellcheck) and [vscode plugin shell-check](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck) which helps you to find 
errors in your script.

ShellCheck can recognize several types of incorrect quoting. It warns you about every unquoted variable. Since it is not much work, I follow the recommendations of ShellCheck.

## /r/bash

Thank you to https://www.reddit.com/r/bash/

I got several good hints there.
