module {
  "name": "printf",
  "description": "jq module implementing printf function",
  "homepage": "https://github.com/robzr/jq-printf",
  "license": "MIT",
  "author": "Rob Zwissler",
  "version": "0.0.0",
  "jq": "1.6",
  "repository": {
    "type": "git",
    "url": "https://github.com/robzr/jq-printf.git"
  }
};

def __printf_regex:
  "%(?<flags>[-+0]+)?(?<width>[1-9][0-9]*)?(.(?<precision>[0-9]*))?(?<type>[dfs])"
  ;

def __printf_pad($width; $arg; $char):
  $char * (($width | tonumber) - ($arg | length))
  ;

def __printf_add_pad($width; $arg; $char; $flags): 
  __printf_pad($width // 0; $arg; $char) as $pad |
  if $width then
    if $flags | contains("-") then
      $arg + $pad
    elif $width then
      $pad + $arg
    end
  else
    $arg
  end
  ;

def __printf($format):
  if type == "null" then
    []
  elif type | IN("number", "string") then
    [.]
  else
    .
  end |
  reduce .[] as $arg (
    { history: [], format: $format, result: "" };
    . + {
      arg: $arg,
      number: (
        $arg |
        tostring |
        capture("^(?<sign>[-+])?(?<head>[0-9]*)(\\.(?<tail>[0-9]*))?") // {}
      ),
      token: (
        (.format | capture(__printf_regex) // {}) + 
        (
          .format |
          match(__printf_regex) // {} |
          {
            begins: .offset,
            ends: (.offset + .length),
          }
        )
      )

    } |
    . + {
      format: .format[(.token.ends // .format | length):],
      number: (
        .number + 
        if (.token.flags? // "") | contains("+") then
          { sign: (.sign? // "+") }
        elif .numbers.sign != "+" then
          { sign: null }
        else
          {}
        end
      ),
      pad_character: (
        if (.token.flags? // "" | contains("0")) then
          "0"
        else
          " "
        end
      ),
      result: (.result + .format[0:.token.begins]),
    } |
    . + {
      result: (
        .result + (
          if .token.type | IN("d", "i") then
            if (.token.flags // "" | contains("+")) and .arg >= 0 then
              . + { arg: "+\(.arg | round | tostring)" }
            else
              . + { arg: (.arg | round | tostring) }
            end |
            __printf_add_pad(.token.width; .arg; .pad_character; .token.flags // "")
          elif .token.type == "f" then
            if (.token.flags // "" | contains("+")) and .arg >= 0 then
              . + { arg: "+\(.arg | tostring)" }
            else
              . + { arg: (.arg | tostring) }
            end |

            if (.token.precision? and .token.precision == "0") then
              . + { arg: ($arg | tonumber | round | tostring) }
            elif .token.precision? then
              . + {
                arg: (
                  (.token.precision | tonumber) as $precision |
                  .number.head + "." + (
                    if (.number.tail | length) > $precision then
                      "\(.number.tail[0:$precision]).\(.number.tail[$precision:])" | tonumber | round | tostring
                    else
                      .number.tail + __printf_pad($precision; .number.tail; "0")
                    end
                  )
                )
              }
            else
              .
            end |
            __printf_add_pad(.token.width; .arg; .pad_character; .token.flags // "")
          elif .token.type == "s" then
            __printf_add_pad(.token.width; .arg | tostring; .pad_character; .token.flags // "")
          else
            . + { arg: (.arg | tostring) }
          end
        )
      ),
    } |
    . + { history: (.history + [. | del(.history)]) }
  )
  ;

def printf($format):
  __printf($format) |
  .result +
  .format
  ;
