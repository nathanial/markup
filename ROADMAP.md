# Markup Roadmap

This document outlines potential improvements, new features, and code cleanup opportunities for the Markup HTML parser library.

## Feature Proposals

### [Priority: High] Lenient Parsing Mode

**Description:** Add a lenient/permissive parsing mode that recovers from common HTML errors instead of failing, similar to how real browsers parse HTML.

**Rationale:** Real-world HTML is often malformed. A lenient parser would enable processing HTML from external sources (scraped content, user input, legacy systems) without requiring perfect syntax. This is essential for practical HTML processing tasks like web scraping or HTML sanitization.

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/State.lean` - Add mode flag to ParserState
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Document.lean` - Recovery logic for unclosed tags, auto-closing
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Html.lean` - New `parseLenient` API functions

**Estimated Effort:** Large

**Implementation Notes:**
- Auto-close unclosed tags when parent closes
- Ignore orphan closing tags
- Handle implicit tag closing (e.g., `<p><p>` auto-closes first `<p>`)
- Return warnings alongside parsed result
- Add `ParserConfig` structure with `strict : Bool` option

---

### [Priority: High] Complete HTML5 Named Entity Support

**Description:** Expand the named entity table to cover all 2,231 HTML5 named character references instead of the current ~40 common entities.

**Rationale:** The current implementation only handles ~40 common entities. Real HTML documents may contain any of the 2,231 named entities defined in the HTML5 spec. Missing entity support causes parse failures for valid HTML.

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Entities.lean` - Complete entity table

**Estimated Effort:** Medium

**Implementation Notes:**
- Consider generating the entity table at compile-time from an external source
- Could use `staple`'s `include_str%` macro to embed entity data
- Consider a HashMap for O(1) lookup instead of linear list search
- Current linear search through ~40 entities will become problematic with 2,231

---

### [Priority: Medium] CDATA Section Support

**Description:** Add support for parsing CDATA sections (`<![CDATA[...]]>`).

**Rationale:** CDATA sections are valid in XHTML and SVG embedded in HTML. Parsing documents containing CDATA without this support will fail.

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Document.lean` - Add CDATA detection and parsing
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Core/Error.lean` - Add CDATA-related errors if needed

**Estimated Effort:** Small

---

### [Priority: Medium] Processing Instruction Support

**Description:** Add support for XML processing instructions (`<?xml version="1.0"?>`, `<?php ... ?>`).

**Rationale:** XHTML documents often include XML declarations. PHP-generated HTML may contain processing instructions. The parser should either skip or capture these.

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Document.lean` - Add PI detection and handling

**Estimated Effort:** Small

---

### [Priority: Medium] Source Position Tracking in AST

**Description:** Optionally embed source position information (line, column, byte offset) in the parsed `Html` AST nodes.

**Rationale:** Essential for tooling that needs to report errors or provide diagnostics referencing the original source location (linters, formatters, IDE integration).

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Html.lean` - Add position-aware parse API
- Potentially requires extending Scribe's Html type or creating a wrapper type

**Estimated Effort:** Medium

**Dependencies:** May require coordination with the Scribe library or introducing a local positioned wrapper type

---

### [Priority: Medium] HTML Diff/Patch Utilities

**Description:** Add utilities to diff two `Html` values and produce a minimal set of changes, or apply patches.

**Rationale:** Useful for testing (showing exactly what differs), virtual DOM-style diffing, or incremental updates in web applications.

**Affected Files:**
- New file: `Markup/Diff.lean`

**Estimated Effort:** Medium

---

### [Priority: Low] CSS Selector Query API

**Description:** Add a query API to select nodes from parsed HTML using CSS selector syntax (e.g., `div.class > p`, `#id`, `[data-attr]`).

**Rationale:** Greatly simplifies extracting data from parsed HTML. A common requirement for web scraping and template processing.

**Affected Files:**
- New file: `Markup/Query.lean` or `Markup/Selector.lean`
- May integrate with the `rune` regex library for attribute value matching

**Estimated Effort:** Large

**Dependencies:** Could leverage the `rune` regex library for pattern matching in selectors

---

### [Priority: Low] HTML Sanitization API

**Description:** Add a configurable HTML sanitizer that removes dangerous elements/attributes based on a whitelist policy.

**Rationale:** Essential for accepting user-generated HTML content safely. Prevents XSS attacks by stripping script tags, event handlers, and dangerous attributes.

**Affected Files:**
- New file: `Markup/Sanitize.lean`

**Estimated Effort:** Medium

---

### [Priority: Low] Streaming Parser

**Description:** Add a streaming/incremental parser that can process HTML in chunks without loading the entire document into memory.

**Rationale:** Enables processing very large HTML documents or parsing HTML as it arrives over the network.

**Affected Files:**
- New module: `Markup/Stream/`

**Estimated Effort:** Large

---

## Code Improvements

### [Priority: High] Optimize Entity Lookup with HashMap

**Current State:** Named entity lookup uses linear search through a list of tuples: `namedEntities.find? (fun (n, _) => n == name)`.

**Proposed Change:** Replace the list with a `Batteries.HashMap` for O(1) average-case lookup.

**Benefits:**
- Improved parse performance for entity-heavy documents
- Essential when expanding to full HTML5 entity set (2,231 entries)

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Entities.lean` (lines 12-54, 57-58)

**Estimated Effort:** Small

---

### [Priority: High] Optimize Void/Raw Element Checks

**Current State:** `isVoidElement` and `isRawTextElement` use `List.contains` with linear search.

**Proposed Change:** Use a `HashSet` or inline pattern matching for these small, fixed sets.

**Benefits:** Minor performance improvement, but these checks occur for every element parsed.

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Elements.lean` (lines 14-30)

**Estimated Effort:** Small

---

### [Priority: Medium] Reduce String Concatenation Overhead

**Current State:** Several parsers build strings character-by-character using `result := result.push c` in loops.

**Proposed Change:** Use `String.Builder` or accumulate to a list and join, which is more efficient for large strings.

**Benefits:** Improved parse performance, especially for documents with large text nodes or raw content.

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Primitives.lean` (lines 25-36, 42-53)
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Elements.lean` (lines 67-87)
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Entities.lean` (lines 105-119)

**Estimated Effort:** Small

---

### [Priority: Medium] Extract Common Test Patterns

**Current State:** Test files contain repetitive patterns for parsing and matching results.

**Proposed Change:** Create test helper functions like:
- `shouldParseAs : String -> Html -> TestM Unit`
- `shouldFailWith : String -> ParseError -> TestM Unit`

**Benefits:** More concise tests, easier to add new test cases.

**Affected Files:**
- All files in `/Users/Shared/Projects/lean-workspace/web/markup/Tests/Parser/`

**Estimated Effort:** Small

---

### [Priority: Medium] Add Benchmarking Infrastructure

**Current State:** No performance benchmarks exist.

**Proposed Change:** Add benchmark suite for parsing various document sizes and complexity levels.

**Benefits:** Track performance regressions, guide optimization efforts.

**Affected Files:**
- New file: `Bench/Main.lean`
- Update `lakefile.lean` to add benchmark target

**Estimated Effort:** Small

---

### [Priority: Low] Unify Duplicate voidElements Lists

**Current State:** `voidElements` is defined in both:
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Elements.lean` (lines 14-17)
- Scribe's `Html.lean` (also has `voidElements`)

**Proposed Change:** Use a single source of truth, either by importing from Scribe or extracting to a shared location.

**Benefits:** Consistency, single point of maintenance.

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Elements.lean`

**Estimated Effort:** Small

---

### [Priority: Low] Improve Attribute List Building

**Current State:** Attributes are built using `attrs := attrs ++ [attr]` which is O(n) per append.

**Proposed Change:** Build list in reverse order and reverse at the end, or use a different data structure.

**Benefits:** O(n) total instead of O(n^2) for attribute list building.

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Attributes.lean` (line 104)

**Estimated Effort:** Small

---

### [Priority: Low] Improve Children List Building

**Current State:** Similar to attributes, children are built with `children := children ++ [node]`.

**Proposed Change:** Same optimization as attributes.

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Parser/Document.lean` (line 108)

**Estimated Effort:** Small

---

## Code Cleanup

### [Priority: Medium] Add Module Documentation

**Issue:** Most modules lack comprehensive documentation describing their purpose and usage.

**Location:**
- All `.lean` files in `Markup/` and `Markup/Parser/`

**Action Required:**
- Add module-level docstrings explaining the module's role
- Document key types and functions with examples
- Add usage examples in docstrings

**Estimated Effort:** Small

---

### [Priority: Medium] Expand Test Coverage for Edge Cases

**Issue:** Some edge cases are not covered by tests.

**Location:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Tests/Parser/`

**Action Required:**
- Add tests for deeply nested elements
- Add tests for very long attribute values
- Add tests for mixed quote styles in attributes
- Add tests for all void elements
- Add tests for unusual but valid whitespace patterns
- Add tests for numeric entities at Unicode boundaries (e.g., surrogate pairs)
- Add tests for `textarea` and `title` raw content parsing
- Add tests for attributes with colons (e.g., `xml:lang`, `xlink:href`)

**Estimated Effort:** Small

---

### [Priority: Low] Consistent Error Message Formatting

**Issue:** Error messages have inconsistent formatting (some use quotes around values, some don't).

**Location:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Core/Error.lean` (lines 48-69)

**Action Required:**
- Standardize quote usage and formatting across all error variants
- Consider adding structured error codes for programmatic handling

**Estimated Effort:** Small

---

### [Priority: Low] Add README.md

**Issue:** The project lacks a README file with usage examples and API documentation.

**Location:**
- `/Users/Shared/Projects/lean-workspace/web/markup/README.md` (new file)

**Action Required:**
- Create README with installation instructions
- Add basic usage examples
- Document the relationship with Scribe
- Explain strict vs. lenient parsing (once implemented)

**Estimated Effort:** Small

---

### [Priority: Low] Add LICENSE File

**Issue:** No license file present.

**Location:**
- `/Users/Shared/Projects/lean-workspace/web/markup/LICENSE` (new file)

**Action Required:**
- Add appropriate license file

**Estimated Effort:** Small

---

## API Enhancements

### [Priority: Medium] Add Traversal and Transformation Helpers

**Description:** Add utility functions for working with parsed HTML:
- `Html.map : (Html -> Html) -> Html -> Html` - Transform all nodes
- `Html.fold : (a -> Html -> a) -> a -> Html -> a` - Fold over nodes
- `Html.find : (Html -> Bool) -> Html -> Option Html` - Find first matching node
- `Html.findAll : (Html -> Bool) -> Html -> List Html` - Find all matching nodes
- `Html.filter : (Html -> Bool) -> Html -> Html` - Remove non-matching nodes

**Rationale:** Common operations for working with HTML trees. Currently users must implement these manually.

**Affected Files:**
- New file: `Markup/Traversal.lean` or extend `Markup/Html.lean`

**Estimated Effort:** Small

---

### [Priority: Medium] Add Convenience Parse Functions

**Description:** Add specialized parse functions:
- `parseFile : FilePath -> IO (ParseResult Html)` - Parse from file
- `parseWithWarnings : String -> (Html, List Warning)` - Parse with non-fatal warnings

**Rationale:** Common use cases that currently require boilerplate.

**Affected Files:**
- `/Users/Shared/Projects/lean-workspace/web/markup/Markup/Html.lean`

**Estimated Effort:** Small

---

### [Priority: Low] Expose Parser Internals for Extension

**Description:** Export parser combinators and state management for users who want to extend the parser.

**Rationale:** Enables custom parsing logic (e.g., parsing custom elements, HTML-embedded DSLs).

**Affected Files:**
- Update module exports in `/Users/Shared/Projects/lean-workspace/web/markup/Markup.lean`

**Estimated Effort:** Small

---

## Summary by Priority

### High Priority
1. Lenient Parsing Mode - Critical for real-world HTML processing
2. Complete HTML5 Named Entity Support - Required for full HTML5 compliance
3. Optimize Entity Lookup with HashMap - Performance-critical for entity expansion
4. Optimize Void/Raw Element Checks - Easy win for parse performance

### Medium Priority
1. CDATA Section Support
2. Processing Instruction Support
3. Source Position Tracking in AST
4. HTML Diff/Patch Utilities
5. Reduce String Concatenation Overhead
6. Extract Common Test Patterns
7. Add Benchmarking Infrastructure
8. Add Module Documentation
9. Expand Test Coverage for Edge Cases
10. Add Traversal and Transformation Helpers
11. Add Convenience Parse Functions

### Low Priority
1. CSS Selector Query API
2. HTML Sanitization API
3. Streaming Parser
4. Unify Duplicate voidElements Lists
5. Improve Attribute List Building
6. Improve Children List Building
7. Consistent Error Message Formatting
8. Add README.md
9. Add LICENSE File
10. Expose Parser Internals for Extension
