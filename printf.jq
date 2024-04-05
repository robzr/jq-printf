module {
  "name": "printf",
  "description": "jq module implementing printf function",
  "homepage": "https://github.com/robzr/jq-printf",
  "license": "MIT",
  "author": "Rob Zwissler",
  "version": "0.0.3",
  "jq": "1.6",
  "repository": {
    "type": "git",
    "url": "https://github.com/robzr/jq-printf.git"
  }
};

def __printf_regex:
  "(?<!%)%(?<flags>[-+0]+)?(?<width>[1-9][0-9]*)?(\\.(?<precision>[0-9]*))?(?<type>[dfis])"
  ;

def __printf_pad($width; $arg; $flags; $sign):
  (
    if $flags | contains("0") then
      "0"
    else
      " "
    end
  ) as $pad_char |
  (
    if ($flags | contains("+")) and $sign == "+" then
      $sign
    else
      ""
    end
  ) as $sign_string |
  (
    (
      $pad_char * (
        ($width | tonumber) -
        ($sign_string | length) -
        ($arg | length)
      )
    )? // ""
  ) as $pad |
  if $flags | contains("-") then
    $sign_string + $arg + $pad
  elif $flags | contains("0") then
    $sign_string + $pad + $arg
  else
    $pad + $sign_string + $arg
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
    .arg = ($arg | tostring) |
    . + {
      number: (
        .arg |
        capture("^(?<sign>[-+])?(?<head>[0-9]*)(\\.(?<tail>[0-9]*))?") // {} |
        . + { sign: (.sign // "+") }
      ),
      token: (
        .format |
        (
          capture(__printf_regex) // {} |
          . + { 
             flags: (.flags? // ""),
             width: (.width? // 0 | tonumber),
          }
        ) +
        (
          match(__printf_regex) // {} |
          {
            begins: .offset,
            ends: (.offset + .length),
          }
        )
      )
    } |
    .result += (.format[0:.token.begins] | gsub("%%"; "%")) |
    . + {
      format: .format[(.token.ends // .format | length):],
    } |
    .result += (
      if .token.type == "f" and .token.precision? then
        if .token.precision == "0" then
          .arg |= (tonumber | round | tostring)
        else
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
        end
      else
        .
      end |
      if .token.type | IN("d", "f", "i", "s") then
        __printf_pad(.token.width; .arg; .token.flags; .number.sign)
      else
        ""
      end
    ) |
    .history += [del(.history)]
  )
  ;

def printf($format):
  __printf($format) |
  .result +
  .format
  ;
