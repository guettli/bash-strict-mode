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
echo "Done"
```

The script expects that there is a file called `bar.txt`. But what happens if that file does not exist?

If the file does not exist, you get this output (without strict mode):

```terminal
❯ ~/tmp/t.sh
grep: bar.txt: No such file or directory
Done
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

## Bash Strict Mode: Use it blindly?



# Misc

shell vs bash scripting.


Thank you to https://www.reddit.com/r/bash/


https://github.com/mvdan/sh#shfmt and vscode plugin https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format


Add comment to that comment: https://www.reddit.com/r/commandline/comments/g1vsxk/comment/fniifmk/

