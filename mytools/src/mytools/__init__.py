"""
Reusable helpers that back the ``mytools`` CLI.

The package exposes a ``__version__`` attribute regardless of whether it
is installed as a package or sourced directly from the repo.
"""

from __future__ import annotations

from importlib import metadata as _metadata

__all__ = ["__version__"]

try:  # Attempt to read the installed package version.
    __version__ = _metadata.version("mytools")
except _metadata.PackageNotFoundError:  # Fallback when running from source.
    __version__ = "0.0.0"
