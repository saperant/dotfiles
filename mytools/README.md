# mytools

Small collection of personal utilities that can be called either from a shell
or as regular Python modules in a REPL.

## Install / upgrade

From the repo root run an editable install so the ``mytools`` console script is
added to your ``PATH`` while still letting you edit the sources:

```bash
pip install --user --editable .
# or with uv/pipx/etc.
```

Any virtual environment works too.  Re-run the command after adding new
dependencies.

## CLI usage

The package exposes the ``mytools`` command (and ``python -m mytools``).  The
command discovers modules under ``mytools.commands`` and automatically adds them
as subcommands.

```bash
mytools hello
mytools hello Ada --shout
python -m mytools hello
```

This works from ``bash``, ``xonsh`` or any shell capable of running regular
executables.

## REPL usage

Because every tool is just a module, it can be imported directly:

```python
>>> from mytools.commands import hello
>>> import argparse
>>> ns = argparse.Namespace(name="Ada", shout=False)
>>> hello._run(ns)
Hello, Ada!
```

You can also reuse the helper functions inside any other project without going
through the CLI.

## Adding new commands

1. Create ``src/mytools/commands/<name>.py``.
2. Implement a ``register(subparsers)`` function that defines arguments and sets
   ``parser.set_defaults(handler=callable)``.
3. The callable should accept the ``argparse`` namespace and return ``0`` on
   success (any other value is treated as an error exit code).

The CLI automatically picks up the new module the next time it runs.
