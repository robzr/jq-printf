# jq-printf
jq module implementing printf function

## Usage
The `printf/1` function is used by passing the format string as a function
argument, with inputs interpreted as format values.
```
$ jq -n '
include "printf";
["bird", 5.55] | printf("%-6s is the word the number is %+05.1f")
'
"bird   is the word the number is +05.6"
```
This printf implementation is written to be forgiving of input types, and accept
null, string, list, number and object inputs. If a format value does not match a
corresponding format type, it generally prints as a string. As `jq` does not have
number types (there is no distinction between a float and an integer; much less
integer lengths or sign/unsigned types), some handling has been built into the
implementation.

A subset of standard printf format types and modifiers are currently supported,
and the framework is in place to easily add more.

### Flags
As in `%<flag><type>` (ex: `%+f`):
- `-` left adjustment within the field width
- `+` force adding sign when used with `%d`, `%i` or `%f`
- `0` zero padding used to fill out remaining field width

### Field Width
As in `%<field_width><type>` (ex: `%10s`) specifies minimum field width, which
will be left padded (right aligned) unless the left adjustment flag is specified
(ex: `%-10s`).

### Precision 
As in `%.<precision><type>` (ex: `%.3f`) specifies the precision for floating
point numbers. Integers or floating points specified with lower precision are
zero padded; floating points specified with greater precision are rounded.

### Types
The following types are supported:
- `d` or `i` - signed decimal or integer
- `f` - floating point number
- `s` - string
- `%` - escape sequence, prints a literal `%`

## Debugging
To debug, change your `printf` function call to `__printf`. The `.history` list
of objects will show the state of parsing and formatting at each pass.

## License
`printf` is released under the MIT license.
