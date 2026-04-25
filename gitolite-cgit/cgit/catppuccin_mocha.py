"""
    pygments.styles.catppuccin_mocha
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    Catppuccin Mocha theme for Pygments (static version)

    Palette source:
    https://github.com/catppuccin/catppuccin

    This file is fully self-contained and does not depend on
    the catppuccin Python package.

    :license: BSD
"""

from pygments.style import Style
from pygments.token import (
    Token,
    Comment,
    Error,
    Generic,
    Keyword,
    Literal,
    Name,
    Number,
    Operator,
    Other,
    Punctuation,
    String,
    Text,
    Whitespace,
)

__all__ = ["CatppuccinMochaStyle"]


class CatppuccinMochaStyle(Style):
    """Catppuccin Mocha pygments style."""

    name = "catppuccin-mocha"

    # --- Base colors ---
    background_color = "#181825"      # mantle
    highlight_color = "#313244"       # surface0

    # --- Line numbers ---
    line_number_background_color = "#181825"
    line_number_color = "#CDD6F4"
    line_number_special_background_color = "#181825"
    line_number_special_color = "#CDD6F4"

    # --- Token styles ---
    styles = {
        # Default
        Token: "#CDD6F4",  # text

        # --- Comments ---
        Comment: "#7F849C",               # overlay2
        Comment.Hashbang: "#7F849C",
        Comment.Multiline: "#7F849C",
        Comment.Single: "#7F849C",
        Comment.Special: "#7F849C",
        Comment.Preproc: "#F5C2E7",       # pink

        # --- Generic ---
        Generic: "#CDD6F4",
        Generic.Deleted: "#F38BA8",       # red
        Generic.Emph: "#CDD6F4 underline",
        Generic.Error: "#CDD6F4",
        Generic.Heading: "#CDD6F4 bold",
        Generic.Inserted: "#CDD6F4 bold",
        Generic.Output: "#6C7086",        # overlay0
        Generic.Prompt: "#CDD6F4",
        Generic.Strong: "#CDD6F4",
        Generic.Subheading: "#CDD6F4 bold",
        Generic.Traceback: "#CDD6F4",

        # --- Errors ---
        Error: "#CDD6F4",

        # --- Keywords ---
        Keyword: "#CBA6F7",               # mauve
        Keyword.Constant: "#CBA6F7",
        Keyword.Declaration: "#CBA6F7 italic",
        Keyword.Namespace: "#CBA6F7",
        Keyword.Pseudo: "#F5C2E7",
        Keyword.Reserved: "#CBA6F7",
        Keyword.Type: "#F9E2AF",          # yellow

        # --- Literals ---
        Literal: "#CDD6F4",
        Literal.Date: "#CDD6F4",

        # --- Names ---
        Name: "#CDD6F4",
        Name.Attribute: "#A6E3A1",        # green
        Name.Builtin: "#F38BA8 italic",
        Name.Builtin.Pseudo: "#F38BA8",
        Name.Class: "#F9E2AF",
        Name.Constant: "#CDD6F4",
        Name.Decorator: "#CDD6F4",
        Name.Entity: "#CDD6F4",
        Name.Exception: "#F9E2AF",
        Name.Function: "#89B4FA",         # blue
        Name.Label: "#94E2D5 italic",     # teal
        Name.Namespace: "#CDD6F4",
        Name.Other: "#CDD6F4",
        Name.Tag: "#89B4FA",
        Name.Variable: "#CDD6F4 italic",
        Name.Variable.Class: "#F9E2AF italic",
        Name.Variable.Global: "#CDD6F4 italic",
        Name.Variable.Instance: "#CDD6F4 italic",

        # --- Numbers ---
        Number: "#FAB387",                # peach
        Number.Bin: "#FAB387",
        Number.Float: "#FAB387",
        Number.Hex: "#FAB387",
        Number.Integer: "#FAB387",
        Number.Integer.Long: "#FAB387",
        Number.Oct: "#FAB387",

        # --- Operators ---
        Operator: "#89DCEB",              # sky
        Operator.Word: "#CBA6F7",

        # --- Other ---
        Other: "#CDD6F4",

        # --- Punctuation ---
        Punctuation: "#7F849C",

        # --- Strings ---
        String: "#A6E3A1",
        String.Backtick: "#A6E3A1",
        String.Char: "#A6E3A1",
        String.Doc: "#A6E3A1",
        String.Double: "#A6E3A1",
        String.Escape: "#F5C2E7",
        String.Heredoc: "#A6E3A1",
        String.Interpol: "#A6E3A1",
        String.Other: "#A6E3A1",
        String.Regex: "#F5C2E7",
        String.Single: "#A6E3A1",
        String.Symbol: "#F38BA8",

        # --- Text ---
        Text: "#CDD6F4",
        Whitespace: "#CDD6F4",
    }
