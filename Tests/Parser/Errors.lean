/-
  Tests/Parser/Errors.lean - Error case tests
-/

import Markup
import Crucible

namespace Tests.Parser.Errors

open Crucible
open Markup

testSuite "Parse Errors"

-- Helper to check if error message contains expected text
def errorContains (e : ParseError) (text : String) : Bool :=
  let msg := toString e
  -- Simple substring search using iteration
  let end_ := msg.length
  let textLen := text.length
  Id.run do
    for i in [0:end_] do
      if i + textLen <= end_ then
        if String.Pos.Raw.extract msg ⟨i⟩ ⟨i + textLen⟩ == text then
          return true
    return false

test "reject unclosed tag" := do
  match parse "<div>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    -- Error message should mention "unclosed tag"
    ensure (errorContains e "unclosed tag") s!"expected unclosed tag error, got {e}"

test "reject mismatched tags" := do
  match parse "<div></span>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    ensure (errorContains e "unmatched closing tag") s!"expected unmatched tag error, got {e}"

test "reject orphan close tag" := do
  match parse "</div>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    ensure (errorContains e "unmatched closing tag") s!"expected unmatched tag error, got {e}"

test "reject invalid entity" := do
  match parse "<p>&invalid;</p>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    ensure (errorContains e "invalid entity") s!"expected invalid entity error, got {e}"

test "reject duplicate attribute" := do
  match parse "<div class=\"a\" class=\"b\"></div>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    ensure (errorContains e "duplicate attribute") s!"expected duplicate attribute error, got {e}"

test "reject unclosed comment" := do
  match parse "<!-- unclosed" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    ensure (errorContains e "invalid comment" || errorContains e "unclosed comment")
      s!"expected invalid comment error, got {e}"

test "reject invalid tag name" := do
  match parse "<123></123>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    ensure (errorContains e "invalid tag name" || errorContains e "unexpected")
      s!"expected invalid tag name error, got {e}"

test "error has position info" := do
  match parse "\n\n  <div></span>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    match e.position with
    | some pos =>
      pos.line ≡ 3  -- Error on line 3
    | none => ensure false "expected position info"

test "reject nested unclosed tags" := do
  match parse "<div><span></div>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    ensure (errorContains e "unmatched closing tag") s!"expected unmatched tag error, got {e}"

test "reject empty attribute value" := do
  match parse "<div class=></div>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    ensure (errorContains e "invalid attribute" || errorContains e "unexpected character")
      s!"expected invalid attribute error, got {e}"

#generate_tests

end Tests.Parser.Errors
