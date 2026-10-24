"""Example command that proves the CLI wiring works."""

from __future__ import annotations

def register(subparsers) -> None:
    parser = subparsers.add_parser(
        "hello",
        help="Print a friendly greeting.",
        description="Say hello to someone (or the world).",
    )
    parser.add_argument(
        "name",
        nargs="?",
        default="friend",
        help="Name to greet; defaults to a friendly generic.",
    )
    parser.add_argument(
        "--shout",
        action="store_true",
        help="Print the greeting in uppercase characters.",
    )
    parser.set_defaults(handler=_run)


def _run(args) -> int:
    greeting = f"Hello, {args.name}!"
    if args.shout:
        greeting = greeting.upper()
    print(greeting)
    return 0
