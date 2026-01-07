/-
  Markup/Parser/Attributes.lean - HTML attribute parsing (using Sift)
-/

import Markup.Parser.Entities
import Scribe

namespace Markup.Parser

open Ascii

/-- Parse an attribute name -/
def parseAttrName : Parser String := do
  let pos ← getPosition
  match ← Sift.peek with
  | some c =>
    if !isAttrNameStart c then
      failWith (.invalidAttribute pos s!"expected attribute name, got '{c}'")
  | none =>
    failWith (.unexpectedEnd "attribute name")
  let name ← readWhile isAttrNameChar
  -- Normalize to lowercase
  pure (stringToLower name)

/-- Parse a double-quoted attribute value -/
def parseDoubleQuotedValue : Parser String := do
  expect '"'
  let value ← parseTextContent (· == '"')
  expect '"'
  pure value

/-- Parse a single-quoted attribute value -/
def parseSingleQuotedValue : Parser String := do
  expect '\''
  let value ← parseTextContent (· == '\'')
  expect '\''
  pure value

/-- Parse an unquoted attribute value -/
def parseUnquotedValue : Parser String := do
  let pos ← getPosition
  let value ← readWhile isUnquotedAttrChar
  if value.isEmpty then
    failWith (.invalidAttribute pos "empty unquoted attribute value")
  pure value

/-- Parse an attribute value (quoted or unquoted) -/
def parseAttrValue : Parser String := do
  match ← Sift.peek with
  | some '"' => parseDoubleQuotedValue
  | some '\'' => parseSingleQuotedValue
  | some c =>
    if isUnquotedAttrChar c then
      parseUnquotedValue
    else
      let pos ← getPosition
      failWith (.invalidAttribute pos s!"unexpected character '{c}' in attribute value")
  | none =>
    failWith (.unexpectedEnd "attribute value")

/-- Parse a single attribute (name, optional =value) -/
def parseAttribute : Parser Scribe.Attr := do
  let name ← parseAttrName
  skipWhitespace
  -- Check for = and value
  if ← tryChar '=' then
    skipWhitespace
    let value ← parseAttrValue
    pure { name, value }
  else
    -- Boolean attribute (e.g., disabled, checked)
    pure { name, value := name }

/-- Check if we're at an attribute start position -/
def atAttributeStart : Parser Bool := do
  match ← Sift.peek with
  | some c => pure (isAttrNameStart c)
  | none => pure false

/-- Parse all attributes until > or /> -/
partial def parseAttributes : Parser (List Scribe.Attr) := do
  let rec loop (attrs : List Scribe.Attr) (seen : List String) : Parser (List Scribe.Attr) := do
    skipWhitespace
    match ← Sift.peek with
    | some '>' => pure attrs
    | some '/' =>
      -- Check for />
      let ahead ← peekString 2
      if ahead == "/>" then pure attrs
      else pure attrs  -- Otherwise / might be part of something else
    | some c =>
      if isAttrNameStart c then
        let pos ← getPosition
        let attr ← parseAttribute
        -- Check for duplicates
        if seen.contains attr.name then
          failWith (.duplicateAttribute pos attr.name)
        loop (attrs ++ [attr]) (attr.name :: seen)
      else
        pure attrs
    | none => pure attrs
  loop [] []

end Markup.Parser
