/-
  Markup/Html.lean - Public API for HTML parsing
-/

import Markup.Parser.Document

namespace Markup

/-- Parse an HTML string into a Scribe.Html value.

    Returns an error for malformed HTML (strict parsing).

    Example:
    ```lean
    match Markup.parse "<div><p>Hello</p></div>" with
    | .ok html => -- use html
    | .error e => -- handle error
    ```
-/
def parse (input : String) : ParseResult Scribe.Html :=
  Parser.run Parser.parseDocument input

/-- Parse an HTML fragment (allows multiple root elements).

    Example:
    ```lean
    match Markup.parseFragment "<p>One</p><p>Two</p>" with
    | .ok html => -- html is a fragment with two paragraphs
    | .error e => -- handle error
    ```
-/
def parseFragment (input : String) : ParseResult Scribe.Html :=
  Parser.run Parser.parseFragment input

/-- Parse an HTML string, throwing an IO error on parse failure.

    Example:
    ```lean
    let html ← Markup.parse! "<div>content</div>"
    ```
-/
def parse! (input : String) : IO Scribe.Html := do
  match parse input with
  | .ok html => return html
  | .error e => throw (IO.userError s!"HTML parse error: {e}")

/-- Parse an HTML fragment, throwing an IO error on parse failure. -/
def parseFragment! (input : String) : IO Scribe.Html := do
  match parseFragment input with
  | .ok html => return html
  | .error e => throw (IO.userError s!"HTML parse error: {e}")

end Markup
