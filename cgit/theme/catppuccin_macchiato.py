"""
    pygments.styles.catppuccin_macchiato
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    Catppuccin Macchiato theme for Pygments (static version)

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

__all__ = ["CatppuccinMacchiatoStyle"]


class CatppuccinMacchiatoStyle(Style):
    """Catppuccin Macchiato pygments style."""

    name = "catppuccin-macchiato"

    # --- Base colors ---
    background_color = "#1E2030"      # mantle
    highlight_color = "#363A4F"       # surface0

    # --- Line numbers ---
    line_number_background_color = "#1E2030"
    line_number_color = "#CAD3F5"
    line_number_special_background_color = "#1E2030"
    line_number_special_color = "#CAD3F5"

    # --- Token styles ---
    styles = {
        # Default
        Token: "#CAD3F5",  # text

        # --- Comments ---
        Comment: "#8087A2",               # overlay2
        Comment.Hashbang: "#8087A2",
        Comment.Multiline: "#8087A2",
        Comment.Single: "#8087A2",
        Comment.Special: "#8087A2",
        Comment.Preproc: "#F5BDE6",       # pink

        # --- Generic ---
        Generic: "#CAD3F5",
        Generic.Deleted: "#ED8796",       # red
        Generic.Emph: "#CAD3F5 underline",
        Generic.Error: "#CAD3F5",
        Generic.Heading: "#CAD3F5 bold",
        Generic.Inserted: "#CAD3F5 bold",
        Generic.Output: "#6E738D",        # overlay0
        Generic.Prompt: "#CAD3F5",
        Generic.Strong: "#CAD3F5",
        Generic.Subheading: "#CAD3F5 bold",
        Generic.Traceback: "#CAD3F5",

        # --- Errors ---
        Error: "#CAD3F5",

        # --- Keywords ---
        Keyword: "#C6A0F6",               # mauve
        Keyword.Constant: "#C6A0F6",
        Keyword.Declaration: "#C6A0F6 italic",
        Keyword.Namespace: "#C6A0F6",
        Keyword.Pseudo: "#F5BDE6",
        Keyword.Reserved: "#C6A0F6",
        Keyword.Type: "#EED49F",          # yellow

        # --- Literals ---
        Literal: "#CAD3F5",
        Literal.Date: "#CAD3F5",

        # --- Names ---
        Name: "#CAD3F5",
        Name.Attribute: "#A6DA95",        # green
        Name.Builtin: "#ED8796 italic",
        Name.Builtin.Pseudo: "#ED8796",
        Name.Class: "#EED49F",
        Name.Constant: "#CAD3F5",
        Name.Decorator: "#CAD3F5",
        Name.Entity: "#CAD3F5",
        Name.Exception: "#EED49F",
        Name.Function: "#8AADF4",         # blue
        Name.Label: "#8BD5CA italic",     # teal
        Name.Namespace: "#CAD3F5",
        Name.Other: "#CAD3F5",
        Name.Tag: "#8AADF4",
        Name.Variable: "#CAD3F5 italic",
        Name.Variable.Class: "#EED49F italic",
        Name.Variable.Global: "#CAD3F5 italic",
        Name.Variable.Instance: "#CAD3F5 italic",

        # --- Numbers ---
        Number: "#F5A97F",                # peach
        Number.Bin: "#F5A97F",
        Number.Float: "#F5A97F",
        Number.Hex: "#F5A97F",
        Number.Integer: "#F5A97F",
        Number.Integer.Long: "#F5A97F",
        Number.Oct: "#F5A97F",

        # --- Operators ---
        Operator: "#91D7E3",              # sky
        Operator.Word: "#C6A0F6",

        # --- Other ---
        Other: "#CAD3F5",

        # --- Punctuation ---
        Punctuation: "#8087A2",

        # --- Strings ---
        String: "#A6DA95",
        String.Backtick: "#A6DA95",
        String.Char: "#A6DA95",
        String.Doc: "#A6DA95",
        String.Double: "#A6DA95",
        String.Escape: "#F5BDE6",
        String.Heredoc: "#A6DA95",
        String.Interpol: "#A6DA95",
        String.Other: "#A6DA95",
        String.Regex: "#F5BDE6",
        String.Single: "#A6DA95",
        String.Symbol: "#ED8796",

        # --- Text ---
        Text: "#CAD3F5",
        Whitespace: "#CAD3F5",
    }
