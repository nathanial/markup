/-
  Markup/Parser/Elements.lean - HTML element and tag parsing
-/

import Markup.Parser.Attributes
import Scribe

namespace Markup.Parser

open Ascii
open Parser

/-- List of HTML void elements (self-closing, no content) -/
def voidElements : List String := [
  "area", "base", "br", "col", "embed", "hr", "img", "input",
  "link", "meta", "param", "source", "track", "wbr"
]

/-- Check if a tag name is a void element -/
def isVoidElement (tag : String) : Bool :=
  voidElements.contains tag

/-- Raw text elements (content is not parsed as HTML) -/
def rawTextElements : List String := [
  "script", "style", "textarea", "title"
]

/-- Check if a tag name contains raw text -/
def isRawTextElement (tag : String) : Bool :=
  rawTextElements.contains tag

/-- Parse a tag name -/
def parseTagName : Parser String := do
  let pos ← getPosition
  match ← peek? with
  | some c =>
    if !isTagNameStart c then
      throw (.invalidTagName pos s!"{c}")
  | none =>
    throw (.unexpectedEnd "tag name")
  let name ← readWhile isTagNameChar
  -- Normalize to lowercase
  return stringToLower name

/-- Parse an opening tag: <tagname attrs...> or <tagname attrs... />
    Returns (tagName, attributes, selfClosing) -/
def parseOpenTag : Parser (String × List Scribe.Attr × Bool) := do
  expect '<'
  let tag ← parseTagName
  let attrs ← parseAttributes
  skipWhitespace
  -- Check for self-closing />
  let selfClosing ← tryString "/>"
  if !selfClosing then
    expect '>'
  return (tag, attrs, selfClosing)

/-- Parse a closing tag: </tagname> -/
def parseCloseTag : Parser String := do
  let _ ← expectString "</"
  let tag ← parseTagName
  skipWhitespace
  expect '>'
  return tag

/-- Parse raw text content until closing tag -/
def parseRawContent (closingTag : String) : Parser String := do
  let mut result := ""
  while true do
    if ← atEnd then
      let pos ← getPosition
      throw (.unclosedTag pos closingTag)
    -- Check for closing tag (case-insensitive)
    let ahead ← peekString (2 + closingTag.length + 1)
    let aheadLower := stringToLower ahead
    if aheadLower.startsWith "</" then
      let tagStart ← peekString (2 + closingTag.length)
      if stringToLower tagStart == s!"</{closingTag}" then
        -- Check next char is > or whitespace
        let full ← peekString (2 + closingTag.length + 1)
        if full.length > 2 + closingTag.length then
          let lastChar := full.get ⟨2 + closingTag.length⟩
          if lastChar == '>' || isWhitespace lastChar then
            break
    let c ← next
    result := result.push c
  return result

end Markup.Parser
