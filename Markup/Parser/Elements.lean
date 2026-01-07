/-
  Markup/Parser/Elements.lean - HTML element and tag parsing (using Sift)
-/

import Markup.Parser.Attributes
import Scribe

namespace Markup.Parser

open Ascii

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
  match ← Sift.peek with
  | some c =>
    if !isTagNameStart c then
      failWith (.invalidTagName pos s!"{c}")
  | none =>
    failWith (.unexpectedEnd "tag name")
  let name ← readWhile isTagNameChar
  -- Normalize to lowercase
  pure (stringToLower name)

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
  pure (tag, attrs, selfClosing)

/-- Parse a closing tag: </tagname> -/
def parseCloseTag : Parser String := do
  let _ ← expectString "</"
  let tag ← parseTagName
  skipWhitespace
  expect '>'
  pure tag

/-- Parse raw text content until closing tag -/
partial def parseRawContent (closingTag : String) : Parser String := do
  let rec loop (acc : String) : Parser String := do
    if ← atEnd then
      let pos ← getPosition
      failWith (.unclosedTag pos closingTag)
    -- Check for closing tag (case-insensitive)
    let ahead ← peekString (2 + closingTag.length + 1)
    let aheadLower := stringToLower ahead
    if aheadLower.startsWith "</" then
      let tagStart ← peekString (2 + closingTag.length)
      if stringToLower tagStart == s!"</{closingTag}" then
        -- Check next char is > or whitespace
        let full ← peekString (2 + closingTag.length + 1)
        if full.length > 2 + closingTag.length then
          let lastChar := String.Pos.Raw.get full ⟨2 + closingTag.length⟩
          if lastChar == '>' || isWhitespace lastChar then
            pure acc
          else
            let c ← Sift.anyChar
            loop (acc.push c)
        else
          let c ← Sift.anyChar
          loop (acc.push c)
      else
        let c ← Sift.anyChar
        loop (acc.push c)
    else
      let c ← Sift.anyChar
      loop (acc.push c)
  loop ""

end Markup.Parser
