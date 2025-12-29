# Markup

A strict HTML parser for Lean 4 that produces [Scribe](https://github.com/nathanial/scribe) `Html` values.

## Features

- **Strict parsing** - Returns errors for malformed HTML
- **Position-tracked errors** - Line and column numbers in error messages
- **Entity decoding** - Named (`&amp;`), decimal (`&#65;`), and hex (`&#x41;`) entities
- **All attribute forms** - Double-quoted, single-quoted, unquoted, and boolean
- **Void elements** - Proper handling of `br`, `img`, `input`, `meta`, etc.
- **Raw text elements** - Script and style content not parsed as HTML
- **Comments and DOCTYPE** - Skipped during parsing

## Installation

Add to your `lakefile.lean`:

```lean
require markup from git "https://github.com/nathanial/markup" @ "v0.1.0"
```

## Usage

```lean
import Markup
import Scribe

-- Parse HTML string
match Markup.parse "<div><p>Hello &amp; welcome</p></div>" with
| .ok html =>
  -- html : Scribe.Html
  IO.println (Scribe.Html.render html)
| .error e =>
  IO.println s!"Parse error: {e}"

-- Parse fragment (multiple root elements allowed)
match Markup.parseFragment "<p>One</p><p>Two</p>" with
| .ok html => -- html is a fragment
| .error e => -- handle error

-- Parse with IO error on failure
let html ← Markup.parse! "<div>content</div>"
```

## API

```lean
namespace Markup

/-- Parse HTML string, returning error for malformed input -/
def parse (input : String) : Except ParseError Scribe.Html

/-- Parse HTML fragment (allows multiple root elements) -/
def parseFragment (input : String) : Except ParseError Scribe.Html

/-- Parse HTML, throwing IO error on failure -/
def parse! (input : String) : IO Scribe.Html

/-- Parse fragment, throwing IO error on failure -/
def parseFragment! (input : String) : IO Scribe.Html

end Markup
```

## Error Handling

Errors include position information for debugging:

```lean
match Markup.parse "<div><span></div>" with
| .error e =>
  -- "line 1, column 12: unmatched closing tag </div> (expected </span>)"
  IO.println s!"{e}"
| .ok _ => pure ()
```

Error types:
- `unexpectedChar` - Unexpected character at position
- `unexpectedEnd` - Unexpected end of input
- `invalidTagName` - Invalid HTML tag name
- `unmatchedCloseTag` - Closing tag doesn't match opening tag
- `unclosedTag` - Tag was never closed
- `invalidAttribute` - Malformed attribute
- `invalidEntity` - Unknown or malformed entity
- `duplicateAttribute` - Same attribute specified twice
- `invalidComment` - Malformed HTML comment

## Supported HTML

### Void Elements (self-closing)
`area`, `base`, `br`, `col`, `embed`, `hr`, `img`, `input`, `link`, `meta`, `param`, `source`, `track`, `wbr`

### Raw Text Elements
`script`, `style`, `textarea`, `title` - Content is not parsed as HTML

### Entities
- Named: `&amp;`, `&lt;`, `&gt;`, `&quot;`, `&apos;`, `&nbsp;`, `&copy;`, `&reg;`, etc.
- Decimal: `&#65;` (character code)
- Hexadecimal: `&#x41;` or `&#X41;`

## Building

```bash
lake build        # Build library
lake test         # Run tests (50 tests)
```

## Project Structure

```
Markup/
├── Core/
│   ├── Error.lean       # ParseError, Position types
│   └── Ascii.lean       # Character classification
├── Parser/
│   ├── State.lean       # Parser monad
│   ├── Primitives.lean  # Low-level helpers
│   ├── Entities.lean    # Entity decoding
│   ├── Attributes.lean  # Attribute parsing
│   ├── Elements.lean    # Tag/element parsing
│   └── Document.lean    # Document parsing
└── Html.lean            # Public API
```

## License

MIT License - see [LICENSE](LICENSE) for details.
