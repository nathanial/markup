/-
  Markup/Parser/Document.lean - Top-level document parsing (using Sift)
-/

import Markup.Parser.Elements
import Scribe

namespace Markup.Parser

open Scribe
open Ascii

/-- Parse an HTML comment: <!-- ... --> -/
partial def parseComment : Parser Unit := do
  let pos ← getPosition
  let _ ← expectString "<!--"
  -- Read until -->
  let rec loop : Parser Unit := do
    if ← atEnd then
      failWith (.invalidComment pos "unclosed comment")
    let ahead ← peekString 3
    if ahead == "-->" then
      let _ ← expectString "-->"
    else if ahead.startsWith "--" then
      -- "--" inside comment is technically invalid in strict HTML
      failWith (.invalidComment pos "\"--\" not allowed inside comments")
    else
      let _ ← Sift.anyChar
      loop
  loop

/-- Parse DOCTYPE declaration: <!DOCTYPE html> -/
def parseDoctype : Parser Unit := do
  let _ ← expectString "<!"
  -- Read DOCTYPE (case-insensitive)
  let doctype ← readWhile isAlpha
  if stringToLower doctype != "doctype" then
    let pos ← getPosition
    failWith (.other pos s!"expected DOCTYPE, got {doctype}")
  skipWhitespace
  -- Read until >
  let _ ← readWhile (· != '>')
  expect '>'

/-- Parse a text node -/
def parseTextNode : Parser Html := do
  let text ← parseText
  pure (.text text)

/-- Check if at a closing tag for a specific element -/
def atCloseTag (tag : String) : Parser Bool := do
  let ahead ← peekString (2 + tag.length + 1)
  let aheadLower := stringToLower ahead
  if !aheadLower.startsWith "</" then pure false
  else
    let tagPart := String.Pos.Raw.extract aheadLower ⟨2⟩ ⟨2 + tag.length⟩
    if tagPart != tag then pure false
    else
      -- Check the character after tag name
      if ahead.length > 2 + tag.length then
        let c := String.Pos.Raw.get ahead ⟨2 + tag.length⟩
        pure (c == '>' || isWhitespace c)
      else
        pure false

mutual
  /-- Parse a single node (element, text, or skip comment) -/
  partial def parseNode : Parser (Option Html) := do
    skipWhitespace
    if ← atEnd then pure none
    else
      match ← Sift.peek with
      | some '<' =>
        -- Check what kind of < construct
        let ahead ← peekString 4
        if ahead.startsWith "<!--" then
          -- Comment - skip it
          parseComment
          pure none  -- Comments produce no HTML node
        else if ahead.startsWith "<!" then
          -- DOCTYPE or other declaration
          parseDoctype
          pure none
        else if ahead.startsWith "</" then
          -- Closing tag - don't consume, let caller handle
          pure none
        else
          -- Opening tag
          let elem ← parseElement
          pure (some elem)
      | some _ =>
        -- Text content
        let text ← parseText
        if text.isEmpty || text.all isWhitespace then
          pure none  -- Skip whitespace-only text
        else
          pure (some (.text text))
      | none => pure none

  /-- Parse children until a closing tag or end -/
  partial def parseChildren (parentTag : Option String) : Parser (List Html) := do
    let rec loop (children : List Html) : Parser (List Html) := do
      -- Check for closing tag
      let shouldStop ← match parentTag with
        | some tag => atCloseTag tag
        | none => pure false
      if shouldStop then
        pure children
      else if ← atEnd then
        pure children
      else
        match ← parseNode with
        | some node => loop (children ++ [node])
        | none =>
          -- Check if we hit a closing tag or EOF
          match ← Sift.peek with
          | some '<' =>
            let ahead ← peekString 2
            if ahead == "</" then pure children
            else loop children
          | _ => pure children
    loop []

  /-- Parse a complete element -/
  partial def parseElement : Parser Html := do
    let openPos ← getPosition
    let (tag, attrs, selfClosing) ← parseOpenTag

    -- Void elements never have children
    if isVoidElement tag || selfClosing then
      pure (.element tag attrs [])
    else if isRawTextElement tag then
      -- Raw text elements (script, style, etc.)
      let content ← parseRawContent tag
      let _ ← parseCloseTag  -- Consume the closing tag
      pure (.element tag attrs [.raw content])
    else
      -- Push tag for validation
      pushTag tag

      -- Parse children
      let children ← parseChildren (some tag)

      -- Expect and consume closing tag
      if ← atEnd then
        failWith (.unclosedTag openPos tag)

      let closeTag ← parseCloseTag
      if closeTag != tag then
        let pos ← getPosition
        failWith (.unmatchedCloseTag pos closeTag (some tag))

      let _ ← popTag

      pure (.element tag attrs children)
end

/-- Parse a complete HTML document -/
partial def parseDocument : Parser Html := do
  skipWhitespace

  -- Skip leading comments and DOCTYPE
  let rec skipPreamble : Parser Unit := do
    let ahead ← peekString 4
    if ahead.startsWith "<!--" then
      parseComment
      skipWhitespace
      skipPreamble
    else if ahead.startsWith "<!" then
      parseDoctype
      skipWhitespace
      skipPreamble
    else
      pure ()
  skipPreamble

  -- Parse root elements
  let children ← parseChildren none

  skipWhitespace

  -- Check for trailing content
  if !(← atEnd) then
    match ← Sift.peek with
    | some '<' =>
      let ahead ← peekString 2
      if ahead == "</" then
        let pos ← getPosition
        let closeTag ← parseCloseTag
        failWith (.unmatchedCloseTag pos closeTag none)
    | _ => pure ()

  match children with
  | [] => failWith (.other { offset := 0, line := 1, column := 1 } "empty document")
  | [single] => pure single
  | multiple => pure (.fragment multiple)

/-- Parse an HTML fragment (multiple root elements allowed) -/
def parseFragment : Parser Html := do
  let children ← parseChildren none
  skipWhitespace
  match children with
  | [] => pure (.fragment [])
  | [single] => pure single
  | multiple => pure (.fragment multiple)

end Markup.Parser
