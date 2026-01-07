/-
  Markup/Parser/Entities.lean - HTML entity decoding (using Sift)
-/

import Sift
import Markup.Core.Error
import Markup.Core.Ascii

namespace Markup.Parser

open Sift
open Ascii

/-- Parser state: tag stack -/
structure ParserUserState where
  tagStack : List String := []
  deriving Repr

/-- Parser type: Sift parser with our custom user state -/
abbrev Parser (α : Type) := Sift.Parser ParserUserState α

/-- Get current position from Sift state -/
def getPosition : Parser Position := do
  let pos ← Sift.Parser.position
  pure { offset := pos.offset, line := pos.line, column := pos.column }

/-- Fail with a Markup ParseError (converted to Sift error) -/
def failWith {α : Type} (e : ParseError) : Parser α :=
  Sift.Parser.fail (toString e)

/-- Push a tag onto the open tag stack -/
def pushTag (tag : String) : Parser Unit := do
  let us ← Sift.Parser.getUserState
  Sift.Parser.setUserState { us with tagStack := tag :: us.tagStack }

/-- Pop a tag from the stack, returning it -/
def popTag : Parser (Option String) := do
  let us ← Sift.Parser.getUserState
  match us.tagStack with
  | [] => pure none
  | t :: rest =>
    Sift.Parser.setUserState { us with tagStack := rest }
    pure (some t)

/-- Peek at the current open tag -/
def currentTag : Parser (Option String) := do
  let us ← Sift.Parser.getUserState
  pure us.tagStack.head?

/-- Check if at end of input -/
def atEnd : Parser Bool := Sift.atEnd

/-- Skip whitespace characters -/
def skipWhitespace : Parser Unit :=
  Sift.skipMany (Sift.satisfy isWhitespace)

/-- Read characters while predicate holds -/
def readWhile (pred : Char → Bool) : Parser String :=
  Sift.takeWhile pred

/-- Require at least one character matching predicate -/
def readWhile1 (pred : Char → Bool) (errorMsg : String) : Parser String := do
  let result ← Sift.takeWhile pred
  if result.isEmpty then
    let pos ← getPosition
    failWith (.other pos errorMsg)
  pure result

/-- Read characters until a specific string is found (exclusive) -/
partial def readUntilString (stop : String) : Parser String := do
  let rec loop (acc : String) : Parser String := do
    if ← atEnd then pure acc
    else
      let ahead ← Sift.peekString stop.length
      match ahead with
      | some s =>
        if s == stop then pure acc
        else
          let c ← Sift.anyChar
          loop (acc.push c)
      | none => pure acc
  loop ""

/-- Try to match and consume a string, returning Bool -/
def tryString (s : String) : Parser Bool := do
  match ← Sift.optional (Sift.attempt (Sift.string s)) with
  | some _ => pure true
  | none => pure false

/-- Try to match a character, returning Bool -/
def tryChar (c : Char) : Parser Bool := do
  match ← Sift.optional (Sift.char c) with
  | some _ => pure true
  | none => pure false

/-- Expect and consume a specific character -/
def expect (c : Char) : Parser Unit := do
  let pos ← getPosition
  match ← Sift.optional (Sift.char c) with
  | some _ => pure ()
  | none =>
    let actual ← Sift.peek
    match actual with
    | some ch => failWith (.unexpectedChar pos ch s!"'{c}'")
    | none => failWith (.unexpectedEnd "input")

/-- Expect and consume a specific string -/
def expectString (s : String) : Parser Unit := do
  let _ ← Sift.string s

/-- Peek ahead n characters -/
def peekString (n : Nat) : Parser String := do
  match ← Sift.peekString n with
  | some s => pure s
  | none =>
    -- Return what we can
    let state ← Sift.Parser.get
    let available := state.input.utf8ByteSize - state.pos
    if available > 0 then
      match ← Sift.peekString available with
      | some s => pure s
      | none => pure ""
    else
      pure ""

/-- Run parser on input -/
def run {α : Type} (p : Parser α) (input : String) : ParseResult α :=
  let initState : ParserUserState := {}
  let result := p (ParseState.init input initState)
  match result with
  | .ok (a, _) => .ok a
  | .error e =>
    let pos : Position := { offset := e.pos.offset, line := e.pos.line, column := e.pos.column }
    .error (.other pos e.message)

-- Entity parsing

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
  let name ← readWhile isAlphaNum
  if name.isEmpty then
    failWith (.invalidEntity pos "&")
  let _ ← Sift.char ';'
  match lookupEntity name with
  | some c => pure c
  | none => failWith (.invalidEntity pos s!"&{name};")

/-- Read a decimal number -/
def readDecimal : Parser Nat := do
  let digits ← readWhile isDigit
  if digits.isEmpty then
    let pos ← getPosition
    failWith (.other pos "expected decimal number")
  match digits.toNat? with
  | some n => pure n
  | none =>
    let pos ← getPosition
    failWith (.other pos s!"invalid decimal: {digits}")

/-- Read a hexadecimal number -/
def readHex : Parser Nat := do
  let digits ← readWhile isHexDigit
  if digits.isEmpty then
    let pos ← getPosition
    failWith (.other pos "expected hexadecimal number")
  let mut result := 0
  for c in digits.toList do
    match hexValue c with
    | some v => result := result * 16 + v
    | none =>
      let pos ← getPosition
      failWith (.other pos s!"invalid hex digit: {c}")
  pure result

/-- Parse a decimal numeric entity (after &#) -/
def parseDecimalEntity : Parser Char := do
  let pos ← getPosition
  let num ← readDecimal
  let _ ← Sift.char ';'
  if num > 0x10FFFF then
    failWith (.invalidEntity pos s!"&#{num};")
  pure (Char.ofNat num)

/-- Parse a hex numeric entity (after &#x or &#X) -/
def parseHexEntity : Parser Char := do
  let pos ← getPosition
  let num ← readHex
  let _ ← Sift.char ';'
  if num > 0x10FFFF then
    failWith (.invalidEntity pos s!"&#x{num};")
  pure (Char.ofNat num)

/-- Parse any entity (starting with &) -/
def parseEntity : Parser Char := do
  let _ ← Sift.char '&'
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
partial def parseTextContent (stopChars : Char → Bool) : Parser String := do
  let rec loop (acc : String) : Parser String := do
    match ← Sift.peek with
    | none => pure acc
    | some c =>
      if stopChars c then
        pure acc
      else if c == '&' then
        let decoded ← parseEntity
        loop (acc.push decoded)
      else
        let _ ← Sift.anyChar
        loop (acc.push c)
  loop ""

/-- Parse text until a specific character (decoding entities) -/
def parseTextUntil (stop : Char) : Parser String :=
  parseTextContent (· == stop)

/-- Parse general text content (stops at < for tags) -/
def parseText : Parser String :=
  parseTextContent (· == '<')

end Markup.Parser
