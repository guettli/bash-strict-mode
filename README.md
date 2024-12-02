# Bash Strict Mode

## Introduction

In this text, I explain how I use the Bash shell. Of course, there are several other ways to use Bash; this is my personal point of view.

If you think there is something wrong or could be improved, please create an issue in this GitHub project. Thank you!

This text contains to parts: Bash Strict Mode and General Hints and Opinions

## Part 1: Bash Strict Mode

Bash strict mode refers to a set of options and practices used in Bash scripting to make scripts
more robust, reliable, and easier to debug. By enabling strict mode, you can prevent common scripting errors,
detect issues early, and make your scripts fail in a controlled way when something unexpected happens.

## Bash Strict Mode: Activating it

I use this at the top of my Bash scripts:

```bash
#!/usr/bin/env bash
trap 'echo "Warning: A command has failed. Exiting the script. Line was ($0:$LINENO): $(sed -n "${LINENO}p" "$0")"; exit 3' ERR
set -Eeuo pipefail
```

Let's have a closer look:

```bash
#!/usr/bin/env bash
```

This makes sure we use the Bash shell, and not a different shell. Writing portable shell scripts is more complicated,
and I want to get things done, so I use Bash and its handy features.

The command `/usr/bin/env` lookups `bash` in `$PATH`. This is handy if `/bin/bash` is outdated on your system,
and you installed a new version in your home directory

---

This line prints a warning if the shell script terminates because a command returned a non-zero exit code:

```bash
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

## Part 2: General Hints and Opinions

## To Bash or not to Bash

Use the right tool. But which tool is the right one?

I use Bash if I need to execute several Linux command-line tools (one after the other) to achieve my goal.

This means the script is straightforward. There are no functions, only a few "if/else" statements (mostly for error handling) and a few loops.

For example, provisioning a vanilla virtual machine into a custom virtual machine to meet specific requirements is such a task. Bash fits perfectly for that.

Bash is not a real programming language. For applications, it’s better to use Golang or Python (in my opinion).

## General Bash Hints: Avoid `find ... | while read -r file` use `while read -r file; do ...; done < <(find ...)`

Image you want to collect errors like this, and fail after the loop if the string error is not empty:

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

This won't work because the block in the loop is executed in a new subshell.
Variables set inside a subshell are not accessible outside.

If you do it like this, it works:

```bash
while read -r file; do
    ...
done < <(find ... )
```

## General Bash Hints: Use sub-scripts instead of functions

TODO: this is wrong. <https://www.reddit.com/r/bash/comments/1gmufop/comment/lw6s6ko/>

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

## Makefiles

Makefiles are similar to the strict mode. Let's look at an example:

```makefile
target: prerequisites
    command-1
    command-2
    command-3
```

If `command-1` fails the Makefile stops, and does not execute `command-2`.

The syntax in a Makefile looks like shell, but it is not.

As soon as the commands in a Makefile get complicated, I recommend to keep it simple:

```makefile
target: prerequisites
    ./bash-script-written-in-strict-mode.sh
```

Instead of trying to understand the syntax of Makefile (for example `$(shell ...)`), I recommend to call a Bash script.

A Bash script has the benefit that formatting (shfmt) and ShellCheck are available in the editor.

## Perl Compatible Regular Expressions: `grep -P`

Unfortunately there are several different flavours of regular expressions.

Instead of learning the old regular expressions, I recommend to use the Perl Compatible Regular Expressions.

The good news: `grep` supports PCRE with the `-P` flag. I suggest to use it.

## I don't use `awk`

I avoid use `awk`, because I am not familiar with the syntax, and from 1996 up to now this worked out fine.

From time to time I use `perl` one-liners.

## Shell vs Bash

I think writing portable shell scripts is unnecessary in most cases. It is like trying to write a script that works in both, the Python and the Ruby interpreters at the same time. Don't do it. Be explicit and write a Bash script (not a shell script).

## shfmt

There is a handy shell formatter: [shfmt](https://github.com/mvdan/sh#shfmt) and a [VS Code plugin shell-format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format).

## ShellCheck

There is [ShellCheck](https://github.com/koalaman/shellcheck) and a [VS Code plugin for ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck) which helps you find errors in your script.

ShellCheck can recognize several types of incorrect quoting. It warns you about every unquoted variable. Since it is not much work, I follow ShellCheck's recommendations.

## Provisioning a machine: Fancy Tools or boring Bash?

There are several well known tools for provisioning a machine: Ansible, SaltStack, Puppet, Chef, ...

All of them have their learning costs.

It depends on the environment, but maybe a Bash script in strict mode is easier to maintain.

Some years ago, we used SaltStack to provision and update a lot of virtual machines. We wasted so much time because things did not work as expected, or error messages got swallowed. In hindsight, we would have been much faster if we had taken the pragmatic approach (Bash) instead of being proud to use the same tools as big tech companies.

## Interactive Shell

This article is about Bash scripting.

For **interative** I use:

* [Fish Shell](https://fishshell.com/)
* [Starship](https://starship.rs/) for the prompt.
* [Atuin](https://github.com/atuinsh/atuin) for the shell history.
* [direnv](https://direnv.net/) to set directoy specific env variables.
* [brew](https://brew.sh/)
* [ripgrep](https://github.com/BurntSushi/ripgrep)
* [fd find](https://github.com/sharkdp/fd)
* [CopyQ](https://hluk.github.io/CopyQ/) Clipboard Manager
* [Activity Watch](https://activitywatch.net/) Automatic time tracker
* VSCode
* Ubuntu LTS.

Usualy don't use `ripgrep` and `fd` in Bash scripts, because these are not available on most systems.

## /r/bash

Thank you to [https://www.reddit.com/r/bash/](https://www.reddit.com/r/bash/)

I got several good hints there.

## More

* [Thomas WOL: Working out Loud](https://github.com/guettli/wol)
