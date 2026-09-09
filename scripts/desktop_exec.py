"""Validate both desktop key-file escapes and Exec argument quoting offline."""
import re
import shlex


def validate_exec(value):
    # Desktop Entry string escapes are processed before Exec command quoting.
    # A shell escape such as \$ must therefore be stored with two backslashes.
    escapes = {'s': ' ', 'n': '\n', 't': '\t', 'r': '\r', '\\': '\\'}

    def decode(match):
        escaped = match.group()[1:]
        if escaped not in escapes:
            raise ValueError('invalid desktop key-file escape')
        return escapes[escaped]

    decoded = re.sub(r'\\(?:.|$)', decode, value)
    if not shlex.split(decoded):
        raise ValueError('empty desktop Exec')
