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

def __printf_pad($width; $arg; $flags; $sign):
  (
    if (.token.flags? // "" | contains("0")) then
      "0"
    else
      " "
    end
  ) as $char |
  ($arg | tostring) as $arg_string |
  ($sign // "") as $sign_string |
  (
    if $sign then
      .token.width - 1
    else
      .token.width
     end
  ) as $adjusted_width |
  (
    (
      $char * (
        ($adjusted_width | tonumber) - ($arg_string | length)
      )
    )? // ""
  ) as $pad |
  if $flags | contains("-") then
    $sign_string + $arg_string + $pad
  elif $flags | contains("0") then
    $sign_string + $pad + $arg_string
  else
    $pad + $sign_string + $arg_string
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
        (
          .format |
          capture(__printf_regex) // {} |
          . + { width: (.width? // 0 | tonumber) }
        ) +
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
      result: (.result + .format[0:.token.begins]),
    } |
    . + {
      result: (
        .result + (
          if .token.type | IN("d", "i") then
            __printf_pad(.token.width; .arg; .token.flags // ""; .number.sign)
          elif .token.type == "f" then
            if (.token.precision? and .token.precision == "0") then
              . + { arg: ($arg | tonumber | round | tostring) }
            elif .token.precision? then
              . + {
                arg: (
                  (.token.precision | tonumber) as $precision |
                  .number.head + "." + (
                    if (.number.tail | length) > $precision then
                      "\(.number.tail[0:$precision]).\(.number.tail[$precision:])" |
                      tonumber |
                      round |
                      tostring
                    else
                      __printf_pad($precision; .number.tail; ""; "")
                    end
                  )
                )
              }
            else
              .
            end |
            __printf_pad(.token.width; .arg; .token.flags // ""; .number.sign)
          elif .token.type == "s" then
            __printf_pad(.token.width; .arg | tostring; .token.flags // ""; .number.sign)
          else
            ""
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
