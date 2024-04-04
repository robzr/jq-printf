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
  "%(?<flags>[-+0%]+)?(?<width>[1-9][0-9]*)?(.(?<precision>[0-9]*))?(?<type>[%dfs])"
  ;

def __printf_pad($width; $arg; $char):
  $char * (($width | tonumber) - ($arg | length))
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
          # first we convert non-strings into formatted strings
          if .token.type == "d" then
            if (.token.flags // "" | contains("+")) and .arg >= 0 then
              . + { arg: "+\(.arg | round | tostring)" }
            else
              . + { arg: (.arg | round | tostring) }
            end
          elif .token.type == "f" then
            if (.token.flags // "" | contains("+")) and .arg >= 0 then
              . + { arg: "+\(.arg | tostring)" }
            else
              . + { arg: (.arg | tostring) }
            end |
            if (.token.precision? and .token.precision == "0") then . + { arg: ($arg | tonumber | round | tostring) }
            elif .token.precision? then
              . + {
                arg: (
                  (.token.precision | tonumber) as $precision |
                  (.arg | capture("^(?<head>[0-9]*)\\.?(?<tail>[0-9]*)?")) as $float |
                  $float.head + "." + (
                    if ($float.tail | length) > $precision then
                      "\($float.tail[0:$precision]).\($float.tail[$precision:])" | tonumber | round | tostring
                    else
                      $float.tail + __printf_pad($precision; $float.tail; "0")
                    end
                  )
                )
              }
            else
              .
            end
          else
            .
          end |
          # now take care of left/right pad and the string .arg
          if .token.width and (.token.flags // "" | contains("-")) then
            .arg + __printf_pad(.token.width; .arg; .pad_character)
          elif .token.width then
            __printf_pad(.token.width; .arg; .pad_character) + .arg
          else
            .arg
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
