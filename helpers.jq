# helpers.jq - A collection of useful jq helper functions

## OBJECT FUNCTIONS ##
# Consolidate array of objects by collecting values with the same keys. Values can be mixed format so they are always wrapped in arrays.
# [{"a":[1]}, {"a":[2]}, {"b":[3]}] -> [{"a":[1,2]}, {"b":[3]}] 
def collect_values:
  reduce .[] as $item (
    {};
    ($item | keys_unsorted[0]) as $key |
    .[$key] = (.[$key] // []) + [$item[$key]]) | to_entries | map({(.key): .value});

## MATH FUNCTIONS ##

# pow(a,b | b needs to be an integer)
def pow(a; b):
  [range(b)] | reduce .[] as $item (1; a * .);

# Normalize array of numbers
def normalize: 
  add as $sum | map(. / $sum);
    
# Round to decimal places: value | round_to(2)
def round_to(places): 
  . * (places | exp10) | round | . / (places | exp10);

## FLOAT FUNCTIONS ##

# Convert number using binary prefixes (powers of 1024)
# Usage: number | convert_units("k")  # converts to kibibytes
# Supported units: k (kibi), m (mebi), g (gibi), t (tebi), p (pebi)
def convert_units(unit):
  . as $value |
  {
    "k": pow(1024;1),
    "m": pow(1024;2),
    "g": pow(1024;3),
    "t": pow(1024;4),
    "p": pow(1024;5)
  }[unit] as $divisor |
  if $divisor then
    $value / $divisor
  else
    error("Invalid unit: '\(unit)'. Supported: k, m, g, t, p")
  end;

## STRING FUNCTIONS ##

# Capitalize first letter of a string
def capitalize:
  if length == 0 then ""
  else .[0:1] | ascii_upcase + .[1:] | ascii_downcase
  end;

# Trim whitespace from both ends
def trim: sub("^\\s+"; "") | sub("\\s+$"; "");

# Reverse a string
def reverse: explode | reverse | implode;

## ARRAY FUNCTIONS ##

# Get the value at a given percentile (0-100)
# Usage: array | percentile(75)  # returns value at 75th percentile
def percentile(pct):
  if length == 0 then null
  else
    sort as $sorted |
    length as $len |
    # Calculate index using linear interpolation
    (($len - 1) * pct / 100) as $index |
    # Get floor and ceiling indices
    ($index | floor) as $floor |
    ($index | ceil) as $ceil |
    # Linear interpolation between values
    if $floor == $ceil then
      $sorted[$floor]
    else
      $sorted[$floor] + ($index - $floor) * ($sorted[$ceil] - $sorted[$floor])
    end
  end;

# Calculate median of an array
def median:
  if length == 0 then null
  else
    sort as $sorted |
    length as $len |
    if $len % 2 == 1 then
      # Odd length - return middle element
      $sorted[$len / 2 | floor]
    else
      # Even length - return average of two middle elements
      ($sorted[($len / 2) - 1] + $sorted[$len / 2]) / 2
    end
  end;

# Get average
def mean:
  length as $l | add / $l;

# Calculate sample standard deviation; denominator (n-1)
def stddev:
  if length == 0 then null
  else
    . as $data |
    ($data | mean) as $mean |
    ($data | map((. - $mean) * (. - $mean)) | add / (length - 1)) | sqrt
  end;

# Remove duplicates from array
def unique:
  reduce .[] as $item ([]; 
    if . | contains([$item]) then . else . + [$item] end);

# Return duplicates from array in the order they are identified
# [2,3,4,4,3,2,0,4] - > [4,3,2,4]
def duplicates:
  reduce .[] as $item (
    {seen: [], dup: []};
    if .seen | contains([$item]) then
      .dup |= (. + [$item] )
    else
      .seen |= (. + [$item])
    end
  ) | .dup;

# Return frequency of numbers, characters, or arrays from array sorted by keys
# [2,3,4,4,3,2,0,4] -> [{"0":1, "2":2, "3":2, "4":3}]
def freq:
  reduce .[] as $item (
    {};
    if .[$item | tostring] then .[$item | tostring] = .[$item | tostring] + 1
    else
      .[$item | tostring] = 1
    end
  ) | to_entries | sort_by(.key) | from_entries;

## VALIDATION FUNCTIONS ##

# Check if value is empty (null, empty string, empty array, empty object)
def is_empty:
  . == null or . == "" or . == [] or . == {};

# Check if value is not empty
def is_not_empty: is_empty | not;

# Flatten nested arrays
def deep_flatten:
  if type == "array" then map(deep_flatten) | add
  else [.]
  end;

# Convert seconds to H:M:S format
# Usage: 3665 | seconds_to_hms  # returns "1:01:05"
# Handles both integer and float seconds
def to_hms:
  . as $s |
  if $s == null then null
  else
    ($s / 3600 | floor) as $hours |
    (($s % 3600) / 60 | floor) as $minutes |
    ($s % 60) as $seconds |
    if $hours > 0 then
      "\($hours):\($minutes | tostring | "0"*(2 - ($minutes | tostring | length)) + ($minutes | tostring)):\($seconds | tostring | split(".")[0] | "0"*(2 - length) + .)"
    else
      "\($minutes):\($seconds | tostring | split(".")[0] | "0"*(2 - length) + .)"
    end
  end;

# Convert seconds to human readable format with units
# Usage: 3665 | seconds_to_readable  # returns "1 hour, 1 minute, 5 seconds"
def to_hms_readable:
  . as $s |
  if $s == null then null
  else
    ($s / 3600 | floor) as $hours |
    (($s % 3600) / 60 | floor) as $minutes |
    ($s % 60 | floor) as $seconds |
    [
      if $hours > 0 then "\($hours) hour" + (if $hours > 1 then "s" else "" end) else empty end,
      if $minutes > 0 then "\($minutes) minute" + (if $minutes > 1 then "s" else "" end) else empty end,
      if $seconds > 0 then "\($seconds) second" + (if $seconds > 1 then "s" else "" end) else empty end
    ] | join(", ")
  end;