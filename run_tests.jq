#!/usr/bin/env jq --run-tests

# test input transforms
#
include "printf"; printf("%s")
null
"%s"

include "printf"; printf("%s")
["a"]
"a"

include "printf"; printf("%s")
{ "test": "a" }
"a"

include "printf"; printf("%s")
"a"
"a"

include "printf"; printf("%s")
1
"1"

include "printf"; printf("%s")
1.1
"1.1"


# test string alignments
#
include "printf"; printf("%5s")
"a"
"    a"

include "printf"; printf("%-5s")
"a"
"a    "


# test decimal/int
#
include "printf"; printf("%d")
"a"
# error (no output)

include "printf"; printf("%d")
1
"1"

include "printf"; printf("%d")
-1
"-1"

include "printf"; printf("%-d")
1
"1"

include "printf"; printf("%+d")
1
"+1"

include "printf"; printf("%+3d")
1
" +1"

include "printf"; printf("%-3d")
1
"1  "

include "printf"; printf("%03d")
1
"001"

include "printf"; printf("%+03d")
1
"+01"


# test floats
#
include "printf"; printf("%f")
12.345
"12.345"

include "printf"; printf("%+f")
12.345
"+12.345"

include "printf"; printf("%5.1f")
12.345
" 12.3"

include "printf"; printf("%5.2f")
12.345
"12.35"

include "printf"; printf("%.2f")
12.345
"12.35"

include "printf"; printf("%3.2f")
12.345
"12.35"

include "printf"; printf("%6.2f")
12.345
" 12.35"