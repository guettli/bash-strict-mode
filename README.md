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




# Misc

shell vs bash scripting.



