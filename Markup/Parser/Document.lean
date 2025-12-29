/-
  Markup/Parser/Document.lean - Top-level document parsing
-/

import Markup.Parser.Elements
import Scribe

namespace Markup.Parser

open Scribe
open Parser

/-- Parse an HTML comment: <!-- ... --> -/
def parseComment : Parser Unit := do
  let pos ← getPosition
  let _ ← expectString "<!--"
  -- Read until -->
  let mut foundEnd := false
  while !foundEnd do
    if ← atEnd then
      throw (.invalidComment pos "unclosed comment")
    let ahead ← peekString 3
    if ahead == "-->" then
      let _ ← expectString "-->"
      foundEnd := true
    else if ahead.startsWith "--" then
      -- "--" inside comment is technically invalid in strict HTML
      throw (.invalidComment pos "\"--\" not allowed inside comments")
    else
      let _ ← next

/-- Parse DOCTYPE declaration: <!DOCTYPE html> -/
def parseDoctype : Parser Unit := do
  let _ ← expectString "<!"
  -- Read DOCTYPE (case-insensitive)
  let doctype ← readWhile Ascii.isAlpha
  if Ascii.stringToLower doctype != "doctype" then
    let pos ← getPosition
    throw (.other pos s!"expected DOCTYPE, got {doctype}")
  skipWhitespace
  -- Read until >
  let _ ← readUntilChar (· == '>')
  expect '>'

/-- Parse a text node -/
def parseTextNode : Parser Html := do
  let text ← parseText
  return .text text

/-- Check if at a closing tag for a specific element -/
def atCloseTag (tag : String) : Parser Bool := do
  let ahead ← peekString (2 + tag.length + 1)
  let aheadLower := Ascii.stringToLower ahead
  if !aheadLower.startsWith "</" then return false
  let tagPart := aheadLower.extract ⟨2⟩ ⟨2 + tag.length⟩
  if tagPart != tag then return false
  -- Check the character after tag name
  if ahead.length > 2 + tag.length then
    let c := ahead.get ⟨2 + tag.length⟩
    return c == '>' || Ascii.isWhitespace c
  return false

mutual
  /-- Parse a single node (element, text, or skip comment) -/
  partial def parseNode : Parser (Option Html) := do
    skipWhitespace
    if ← atEnd then return none
    match ← peek? with
    | some '<' =>
      -- Check what kind of < construct
      let ahead ← peekString 4
      if ahead.startsWith "<!--" then
        -- Comment - skip it
        parseComment
        return none  -- Comments produce no HTML node
      else if ahead.startsWith "<!" then
        -- DOCTYPE or other declaration
        parseDoctype
        return none
      else if ahead.startsWith "</" then
        -- Closing tag - don't consume, let caller handle
        return none
      else
        -- Opening tag
        let elem ← parseElement
        return some elem
    | some _ =>
      -- Text content
      let text ← parseText
      if text.isEmpty || text.all Ascii.isWhitespace then
        return none  -- Skip whitespace-only text
      return some (.text text)
    | none => return none

  /-- Parse children until a closing tag or end -/
  partial def parseChildren (parentTag : Option String) : Parser (List Html) := do
    let mut children : List Html := []
    while true do
      -- Check for closing tag
      match parentTag with
      | some tag =>
        if ← atCloseTag tag then break
      | none => pure ()

      if ← atEnd then break

      match ← parseNode with
      | some node => children := children ++ [node]
      | none =>
        -- Check if we hit a closing tag or EOF
        match ← peek? with
        | some '<' =>
          let ahead ← peekString 2
          if ahead == "</" then break
        | _ => break

    return children

  /-- Parse a complete element -/
  partial def parseElement : Parser Html := do
    let openPos ← getPosition
    let (tag, attrs, selfClosing) ← parseOpenTag

    -- Void elements never have children
    if isVoidElement tag || selfClosing then
      return .element tag attrs []

    -- Raw text elements (script, style, etc.)
    if isRawTextElement tag then
      let content ← parseRawContent tag
      let _ ← parseCloseTag  -- Consume the closing tag
      return .element tag attrs [.raw content]

    -- Push tag for validation
    pushTag tag

    -- Parse children
    let children ← parseChildren (some tag)

    -- Expect and consume closing tag
    if ← atEnd then
      throw (.unclosedTag openPos tag)

    let closeTag ← parseCloseTag
    if closeTag != tag then
      let pos ← getPosition
      throw (.unmatchedCloseTag pos closeTag (some tag))

    let _ ← popTag

    return .element tag attrs children
end

/-- Parse a complete HTML document -/
def parseDocument : Parser Html := do
  skipWhitespace

  -- Skip leading comments and DOCTYPE
  while true do
    let ahead ← peekString 4
    if ahead.startsWith "<!--" then
      parseComment
      skipWhitespace
    else if ahead.startsWith "<!" then
      parseDoctype
      skipWhitespace
    else
      break

  -- Parse root elements
  let children ← parseChildren none

  skipWhitespace

  -- Check for trailing content
  if !(← atEnd) then
    match ← peek? with
    | some '<' =>
      let ahead ← peekString 2
      if ahead == "</" then
        let pos ← getPosition
        let closeTag ← parseCloseTag
        throw (.unmatchedCloseTag pos closeTag none)
    | _ => pure ()

  match children with
  | [] => throw (.other { offset := 0, line := 1, column := 1 } "empty document")
  | [single] => return single
  | multiple => return .fragment multiple

/-- Parse an HTML fragment (multiple root elements allowed) -/
def parseFragment : Parser Html := do
  let children ← parseChildren none
  skipWhitespace
  match children with
  | [] => return .fragment []
  | [single] => return single
  | multiple => return .fragment multiple

end Markup.Parser
