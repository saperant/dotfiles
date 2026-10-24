"""
Command discovery utilities.

Every module in this package can implement a ``register(subparsers)``
function to hook into the top-level CLI.  The discovery keeps imports lazy,
so the same modules can be imported directly in a REPL.
"""

from __future__ import annotations

from importlib import import_module
from pkgutil import iter_modules
from types import ModuleType
from typing import Iterable


def _iter_command_modules() -> Iterable[ModuleType]:
    package_name = __name__
    package_path = __path__  # type: ignore[name-defined]

    for finder, name, is_pkg in iter_modules(package_path):
        if is_pkg or name.startswith("_"):
            continue
        yield import_module(f"{package_name}.{name}")


def register(subparsers) -> None:
    """Register every command defined under ``mytools.commands``."""
    for module in _iter_command_modules():
        hook = getattr(module, "register", None)
        if hook is None:
            continue
        hook(subparsers)
