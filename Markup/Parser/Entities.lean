/-
  Markup/Parser/Entities.lean - HTML entity decoding
-/

import Markup.Parser.Primitives

namespace Markup.Parser

open Parser

/-- Common HTML named entities -/
def namedEntities : List (String × Char) := [
  -- Basic XML entities
  ("amp", '&'),
  ("lt", '<'),
  ("gt", '>'),
  ("quot", '"'),
  ("apos", '\''),
  -- Common HTML entities
  ("nbsp", '\u00A0'),   -- Non-breaking space
  ("copy", '\u00A9'),   -- Copyright
  ("reg", '\u00AE'),    -- Registered trademark
  ("trade", '\u2122'),  -- Trademark
  ("euro", '\u20AC'),   -- Euro sign
  ("pound", '\u00A3'),  -- Pound sign
  ("yen", '\u00A5'),    -- Yen sign
  ("cent", '\u00A2'),   -- Cent sign
  ("deg", '\u00B0'),    -- Degree
  ("plusmn", '\u00B1'), -- Plus-minus
  ("times", '\u00D7'),  -- Multiplication
  ("divide", '\u00F7'), -- Division
  ("frac12", '\u00BD'), -- 1/2
  ("frac14", '\u00BC'), -- 1/4
  ("frac34", '\u00BE'), -- 3/4
  -- Punctuation
  ("ndash", '\u2013'),  -- En dash
  ("mdash", '\u2014'),  -- Em dash
  ("lsquo", '\u2018'),  -- Left single quote
  ("rsquo", '\u2019'),  -- Right single quote
  ("ldquo", '\u201C'),  -- Left double quote
  ("rdquo", '\u201D'),  -- Right double quote
  ("bull", '\u2022'),   -- Bullet
  ("hellip", '\u2026'), -- Ellipsis
  -- Arrows
  ("larr", '\u2190'),   -- Left arrow
  ("uarr", '\u2191'),   -- Up arrow
  ("rarr", '\u2192'),   -- Right arrow
  ("darr", '\u2193'),   -- Down arrow
  -- Math symbols
  ("ne", '\u2260'),     -- Not equal
  ("le", '\u2264'),     -- Less than or equal
  ("ge", '\u2265'),     -- Greater than or equal
  ("infin", '\u221E'),  -- Infinity
]

/-- Look up a named entity -/
def lookupEntity (name : String) : Option Char :=
  namedEntities.find? (fun (n, _) => n == name) |>.map Prod.snd

/-- Parse a named entity (after &) -/
def parseNamedEntity : Parser Char := do
  let pos ← getPosition
  let name ← readWhile Ascii.isAlphaNum
  if name.isEmpty then
    throw (.invalidEntity pos "&")
  expect ';'
  match lookupEntity name with
  | some c => return c
  | none => throw (.invalidEntity pos s!"&{name};")

/-- Parse a decimal numeric entity (after &#) -/
def parseDecimalEntity : Parser Char := do
  let pos ← getPosition
  let num ← readDecimal
  expect ';'
  if num > 0x10FFFF then
    throw (.invalidEntity pos s!"&#{num};")
  return Char.ofNat num

/-- Parse a hex numeric entity (after &#x or &#X) -/
def parseHexEntity : Parser Char := do
  let pos ← getPosition
  let num ← readHex
  expect ';'
  if num > 0x10FFFF then
    throw (.invalidEntity pos s!"&#x{num};")
  return Char.ofNat num

/-- Parse any entity (starting with &) -/
def parseEntity : Parser Char := do
  expect '&'
  if ← tryChar '#' then
    -- Numeric entity
    if ← tryChar 'x' then
      parseHexEntity
    else if ← tryChar 'X' then
      parseHexEntity
    else
      parseDecimalEntity
  else
    -- Named entity
    parseNamedEntity

/-- Parse text content, decoding entities -/
def parseTextContent (stopChars : Char → Bool) : Parser String := do
  let mut result := ""
  while true do
    match ← peek? with
    | none => break
    | some c =>
      if stopChars c then
        break
      else if c == '&' then
        let decoded ← parseEntity
        result := result.push decoded
      else
        let _ ← next
        result := result.push c
  return result

/-- Parse text until a specific character (decoding entities) -/
def parseTextUntil (stop : Char) : Parser String :=
  parseTextContent (· == stop)

/-- Parse general text content (stops at < for tags) -/
def parseText : Parser String :=
  parseTextContent (· == '<')

end Markup.Parser
