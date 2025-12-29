/-
  Markup/Parser/Attributes.lean - HTML attribute parsing
-/

import Markup.Parser.Entities
import Scribe

namespace Markup.Parser

open Ascii
open Parser

/-- Parse an attribute name -/
def parseAttrName : Parser String := do
  let pos ← getPosition
  match ← peek? with
  | some c =>
    if !isAttrNameStart c then
      throw (.invalidAttribute pos s!"expected attribute name, got '{c}'")
  | none =>
    throw (.unexpectedEnd "attribute name")
  let name ← readWhile isAttrNameChar
  -- Normalize to lowercase
  return stringToLower name

/-- Parse a double-quoted attribute value -/
def parseDoubleQuotedValue : Parser String := do
  expect '"'
  let value ← parseTextContent (· == '"')
  expect '"'
  return value

/-- Parse a single-quoted attribute value -/
def parseSingleQuotedValue : Parser String := do
  expect '\''
  let value ← parseTextContent (· == '\'')
  expect '\''
  return value

/-- Parse an unquoted attribute value -/
def parseUnquotedValue : Parser String := do
  let pos ← getPosition
  let value ← readWhile isUnquotedAttrChar
  if value.isEmpty then
    throw (.invalidAttribute pos "empty unquoted attribute value")
  return value

/-- Parse an attribute value (quoted or unquoted) -/
def parseAttrValue : Parser String := do
  match ← peek? with
  | some '"' => parseDoubleQuotedValue
  | some '\'' => parseSingleQuotedValue
  | some c =>
    if isUnquotedAttrChar c then
      parseUnquotedValue
    else
      let pos ← getPosition
      throw (.invalidAttribute pos s!"unexpected character '{c}' in attribute value")
  | none =>
    throw (.unexpectedEnd "attribute value")

/-- Parse a single attribute (name, optional =value) -/
def parseAttribute : Parser Scribe.Attr := do
  let name ← parseAttrName
  skipWhitespace
  -- Check for = and value
  if ← tryChar '=' then
    skipWhitespace
    let value ← parseAttrValue
    return { name, value }
  else
    -- Boolean attribute (e.g., disabled, checked)
    return { name, value := name }

/-- Check if we're at an attribute start position -/
def atAttributeStart : Parser Bool := do
  match ← peek? with
  | some c => return isAttrNameStart c
  | none => return false

/-- Parse all attributes until > or /> -/
def parseAttributes : Parser (List Scribe.Attr) := do
  let mut attrs : List Scribe.Attr := []
  let mut seen : List String := []  -- Track seen attribute names

  while true do
    skipWhitespace
    match ← peek? with
    | some '>' => break
    | some '/' =>
      -- Check for />
      let ahead ← peekString 2
      if ahead == "/>" then break
      -- Otherwise / might be part of something else
      break
    | some c =>
      if isAttrNameStart c then
        let pos ← getPosition
        let attr ← parseAttribute
        -- Check for duplicates
        if seen.contains attr.name then
          throw (.duplicateAttribute pos attr.name)
        seen := attr.name :: seen
        attrs := attrs ++ [attr]
      else
        break
    | none => break

  return attrs

end Markup.Parser
