"""
MkDocs MobileWheels Plugin

A plugin that adds Python package search functionality to MkDocs sites
using a WASM-powered SQLite database.
"""

__version__ = "0.1.0"

from .plugin import MobileWheelsPlugin

__all__ = ["MobileWheelsPlugin"]
