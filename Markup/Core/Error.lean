/-
  Markup/Core/Error.lean - Parse error types with position tracking
-/

namespace Markup

/-- Position in HTML source with line/column for better error messages -/
structure Position where
  offset : Nat      -- Byte offset from start
  line : Nat        -- 1-based line number
  column : Nat      -- 1-based column number
  deriving Repr, BEq, Inhabited

instance : ToString Position where
  toString p := s!"line {p.line}, column {p.column}"

/-- Parse errors with position information -/
inductive ParseError where
  | unexpectedChar (pos : Position) (char : Char) (expected : String)
  | unexpectedEnd (context : String)
  | invalidTagName (pos : Position) (name : String)
  | unmatchedCloseTag (pos : Position) (found : String) (expected : Option String)
  | unclosedTag (pos : Position) (tag : String)
  | invalidAttribute (pos : Position) (msg : String)
  | invalidEntity (pos : Position) (entity : String)
  | duplicateAttribute (pos : Position) (name : String)
  | invalidComment (pos : Position) (msg : String)
  | other (pos : Position) (msg : String)
  deriving Repr, BEq, Inhabited

namespace ParseError

def position : ParseError → Option Position
  | unexpectedChar pos _ _ => some pos
  | unexpectedEnd _ => none
  | invalidTagName pos _ => some pos
  | unmatchedCloseTag pos _ _ => some pos
  | unclosedTag pos _ => some pos
  | invalidAttribute pos _ => some pos
  | invalidEntity pos _ => some pos
  | duplicateAttribute pos _ => some pos
  | invalidComment pos _ => some pos
  | other pos _ => some pos

end ParseError

instance : ToString ParseError where
  toString e := match e with
    | .unexpectedChar pos c exp =>
        s!"{pos}: unexpected character '{c}', expected {exp}"
    | .unexpectedEnd ctx =>
        s!"unexpected end of input while parsing {ctx}"
    | .invalidTagName pos name =>
        s!"{pos}: invalid tag name '{name}'"
    | .unmatchedCloseTag pos found expected =>
        let exp := expected.map (s!" (expected </{·}>)") |>.getD ""
        s!"{pos}: unmatched closing tag </{found}>{exp}"
    | .unclosedTag pos tag =>
        s!"{pos}: unclosed tag <{tag}>"
    | .invalidAttribute pos msg =>
        s!"{pos}: invalid attribute: {msg}"
    | .invalidEntity pos entity =>
        s!"{pos}: invalid entity '{entity}'"
    | .duplicateAttribute pos name =>
        s!"{pos}: duplicate attribute '{name}'"
    | .invalidComment pos msg =>
        s!"{pos}: invalid comment: {msg}"
    | .other pos msg =>
        s!"{pos}: {msg}"

abbrev ParseResult (α : Type) := Except ParseError α

end Markup
