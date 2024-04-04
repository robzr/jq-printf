# jq-printf
jq module implementing printf function

## Usage
The `printf/1` function is used by passing the format string as a function
argument, and inputs are interpreted as format values.
```
import "printf";

["bird", 123.456] | printf("%6s is the word the number is %1.2f")
```
The function is pretty forgiving and can handle null, string, list, number and
object inputs. If a format type does not match a corresponding value, it is also
pretty forgiving and generally prints as a string, with some exceptions (like
trying to format a string as a floating point). A subset of printf format types
and modifiers are currently supported, although the framework is in place to
easily add more.

### Flags
As in `%<flag><type>` (ex: `%+f`):
- `-` left alignment within the field width
- `+` when specified with a `%d` or `%f`, will force adding the sign of the value
- `0` zero padding used to fill out remaining field width, when specified

### Field Width
As in `%<field_width><type>` (ex: `%10s`) specifieds minimum field width, which
will be left padded (right aligned) unless the left adjustment flag is specified
(ex: `%-10s`).

### Precision 
As in `%.<precision><type>` (ex: `%.3f`) specifies the precision for floating
point numbers. Integers or floating points specified with lower precision will
be zero padded; floating points specified with greater precision will be rounded.

### Types
The following types are supported:
- `d` or `i` - signed decimal or integer
- `f` - floating point number
- `s` - string
- `%` - escape sequence, prints a literal `%`

## Debugging
To debug, change your `printf` function call to `__printf`. The `.history` list
of objects shows the state of parsing and formatting at each step.

## License
`printf` is released under the MIT license.
