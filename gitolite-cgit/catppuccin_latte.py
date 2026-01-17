"""
    pygments.styles.catppuccin_latte
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    Catppuccin Latte theme for Pygments (static version)

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

__all__ = ["CatppuccinLatteStyle"]


class CatppuccinLatteStyle(Style):
    """Catppuccin Latte pygments style."""

    name = "catppuccin-latte"

    # --- Base colors ---
    background_color = "#E6E9EF"      # mantle
    highlight_color = "#CCD0DA"       # surface0

    # --- Line numbers ---
    line_number_background_color = "#E6E9EF"
    line_number_color = "#4C4F69"
    line_number_special_background_color = "#E6E9EF"
    line_number_special_color = "#4C4F69"

    # --- Token styles ---
    styles = {
        # Default
        Token: "#4C4F69",  # text

        # --- Comments ---
        Comment: "#8C8FA1",               # overlay2
        Comment.Hashbang: "#8C8FA1",
        Comment.Multiline: "#8C8FA1",
        Comment.Single: "#8C8FA1",
        Comment.Special: "#8C8FA1",
        Comment.Preproc: "#EA76CB",       # pink

        # --- Generic ---
        Generic: "#4C4F69",
        Generic.Deleted: "#D20F39",       # red
        Generic.Emph: "#4C4F69 underline",
        Generic.Error: "#4C4F69",
        Generic.Heading: "#4C4F69 bold",
        Generic.Inserted: "#4C4F69 bold",
        Generic.Output: "#9CA0B0",        # overlay0
        Generic.Prompt: "#4C4F69",
        Generic.Strong: "#4C4F69",
        Generic.Subheading: "#4C4F69 bold",
        Generic.Traceback: "#4C4F69",

        # --- Errors ---
        Error: "#4C4F69",

        # --- Keywords ---
        Keyword: "#8839EF",               # mauve
        Keyword.Constant: "#8839EF",
        Keyword.Declaration: "#8839EF italic",
        Keyword.Namespace: "#8839EF",
        Keyword.Pseudo: "#EA76CB",
        Keyword.Reserved: "#8839EF",
        Keyword.Type: "#DF8E1D",          # yellow

        # --- Literals ---
        Literal: "#4C4F69",
        Literal.Date: "#4C4F69",

        # --- Names ---
        Name: "#4C4F69",
        Name.Attribute: "#40A02B",        # green
        Name.Builtin: "#D20F39 italic",
        Name.Builtin.Pseudo: "#D20F39",
        Name.Class: "#DF8E1D",
        Name.Constant: "#4C4F69",
        Name.Decorator: "#4C4F69",
        Name.Entity: "#4C4F69",
        Name.Exception: "#DF8E1D",
        Name.Function: "#1E66F5",         # blue
        Name.Label: "#179299 italic",     # teal
        Name.Namespace: "#4C4F69",
        Name.Other: "#4C4F69",
        Name.Tag: "#1E66F5",
        Name.Variable: "#4C4F69 italic",
        Name.Variable.Class: "#DF8E1D italic",
        Name.Variable.Global: "#4C4F69 italic",
        Name.Variable.Instance: "#4C4F69 italic",

        # --- Numbers ---
        Number: "#FE640B",                # peach
        Number.Bin: "#FE640B",
        Number.Float: "#FE640B",
        Number.Hex: "#FE640B",
        Number.Integer: "#FE640B",
        Number.Integer.Long: "#FE640B",
        Number.Oct: "#FE640B",

        # --- Operators ---
        Operator: "#04A5E5",              # sky
        Operator.Word: "#8839EF",

        # --- Other ---
        Other: "#4C4F69",

        # --- Punctuation ---
        Punctuation: "#8C8FA1",

        # --- Strings ---
        String: "#40A02B",
        String.Backtick: "#40A02B",
        String.Char: "#40A02B",
        String.Doc: "#40A02B",
        String.Double: "#40A02B",
        String.Escape: "#EA76CB",
        String.Heredoc: "#40A02B",
        String.Interpol: "#40A02B",
        String.Other: "#40A02B",
        String.Regex: "#EA76CB",
        String.Single: "#40A02B",
        String.Symbol: "#D20F39",

        # --- Text ---
        Text: "#4C4F69",
        Whitespace: "#4C4F69",
    }
