"""
Command line interface for ``mytools``.

Each command lives in ``mytools.commands`` and exposes a ``register``
function that receives the shared ``argparse`` subparser collection.
"""

from __future__ import annotations

import argparse
from typing import Sequence

from . import __version__
from . import commands


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="mytools",
        description="Collection of small personal helpers.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
        help="Show the installed version and exit.",
    )

    subparsers = parser.add_subparsers(
        title="available tools",
        metavar="<tool>",
        dest="command",
    )
    commands.register(subparsers)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    """Entry point used by both ``python -m mytools`` and the console script."""
    parser = _build_parser()
    args = parser.parse_args(argv)

    handler = getattr(args, "handler", None)
    if handler is None:
        parser.print_help()
        return 0

    return int(handler(args))  # type: ignore[return-value]
