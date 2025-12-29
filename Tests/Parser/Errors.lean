/-
  Tests/Parser/Errors.lean - Error case tests
-/

import Markup
import Crucible

namespace Tests.Parser.Errors

open Crucible
open Markup

testSuite "Parse Errors"

test "reject unclosed tag" := do
  match parse "<div>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    match e with
    | .unclosedTag _ _ => pure ()
    | _ => ensure false s!"expected unclosedTag error, got {e}"

test "reject mismatched tags" := do
  match parse "<div></span>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    match e with
    | .unmatchedCloseTag _ _ _ => pure ()
    | _ => ensure false s!"expected unmatchedCloseTag error, got {e}"

test "reject orphan close tag" := do
  match parse "</div>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    match e with
    | .unmatchedCloseTag _ _ _ => pure ()
    | _ => ensure false s!"expected unmatchedCloseTag error, got {e}"

test "reject invalid entity" := do
  match parse "<p>&invalid;</p>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    match e with
    | .invalidEntity _ _ => pure ()
    | _ => ensure false s!"expected invalidEntity error, got {e}"

test "reject duplicate attribute" := do
  match parse "<div class=\"a\" class=\"b\"></div>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    match e with
    | .duplicateAttribute _ _ => pure ()
    | _ => ensure false s!"expected duplicateAttribute error, got {e}"

test "reject unclosed comment" := do
  match parse "<!-- unclosed" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    match e with
    | .invalidComment _ _ => pure ()
    | _ => ensure false s!"expected invalidComment error, got {e}"

test "reject invalid tag name" := do
  match parse "<123></123>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    match e with
    | .invalidTagName _ _ => pure ()
    | .unexpectedChar _ _ _ => pure ()  -- Also acceptable
    | _ => ensure false s!"expected invalidTagName error, got {e}"

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
    match e with
    | .unmatchedCloseTag _ _ _ => pure ()
    | _ => ensure false s!"expected unmatchedCloseTag error, got {e}"

test "reject empty attribute value" := do
  match parse "<div class=></div>" with
  | .ok _ => ensure false "should have failed"
  | .error e =>
    match e with
    | .invalidAttribute _ _ => pure ()
    | _ => ensure false s!"expected invalidAttribute error, got {e}"

#generate_tests

end Tests.Parser.Errors
