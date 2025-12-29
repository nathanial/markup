/-
  Markup/Parser/Primitives.lean - Low-level parsing helpers
-/

import Markup.Parser.State
import Markup.Core.Ascii

namespace Markup.Parser

open Ascii
open Parser

/-- Skip whitespace characters -/
def skipWhitespace : Parser Unit := do
  while true do
    match ← peek? with
    | some c =>
      if isWhitespace c then
        let _ ← next
      else
        break
    | none => break

/-- Read characters while predicate holds -/
def readWhile (pred : Char → Bool) : Parser String := do
  let mut result := ""
  while true do
    match ← peek? with
    | some c =>
      if pred c then
        let _ ← next
        result := result.push c
      else
        break
    | none => break
  return result

/-- Read characters until predicate holds (exclusive) -/
def readUntilChar (pred : Char → Bool) : Parser String := do
  readWhile (fun c => !pred c)

/-- Read characters until a specific string is found (exclusive) -/
def readUntilString (stop : String) : Parser String := do
  let mut result := ""
  while true do
    if ← atEnd then
      break
    let ahead ← peekString stop.length
    if ahead == stop then
      break
    let c ← next
    result := result.push c
  return result

/-- Try to run a parser, backtracking on failure -/
def tryParse {α : Type} (p : Parser α) : Parser (Option α) := do
  let s ← get
  try
    let result ← p
    return some result
  catch _ =>
    set s
    return none

/-- Run parser, returning result or default on failure -/
def withDefault {α : Type} (default : α) (p : Parser α) : Parser α := do
  match ← tryParse p with
  | some result => return result
  | none => return default

/-- Skip a specific string if present -/
def skipString (s : String) : Parser Bool := tryString s

/-- Read a decimal number -/
def readDecimal : Parser Nat := do
  let digits ← readWhile isDigit
  if digits.isEmpty then
    let pos ← getPosition
    throw (.other pos "expected decimal number")
  match digits.toNat? with
  | some n => return n
  | none =>
    let pos ← getPosition
    throw (.other pos s!"invalid decimal: {digits}")

/-- Read a hexadecimal number -/
def readHex : Parser Nat := do
  let digits ← readWhile isHexDigit
  if digits.isEmpty then
    let pos ← getPosition
    throw (.other pos "expected hexadecimal number")
  let mut result := 0
  for c in digits.toList do
    match hexValue c with
    | some v => result := result * 16 + v
    | none =>
      let pos ← getPosition
      throw (.other pos s!"invalid hex digit: {c}")
  return result

/-- Require at least one character matching predicate -/
def readWhile1 (pred : Char → Bool) (errorMsg : String) : Parser String := do
  let result ← readWhile pred
  if result.isEmpty then
    let pos ← getPosition
    throw (.other pos errorMsg)
  return result

end Markup.Parser
