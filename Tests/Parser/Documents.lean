/-
  Tests/Parser/Documents.lean - Full document parsing tests
-/

import Markup
import Crucible
import Scribe

namespace Tests.Parser.Documents

open Crucible
open Markup
open Scribe

testSuite "Document Parsing"

test "parse minimal document" := do
  match parse "<html></html>" with
  | .ok html =>
    match html with
    | .element "html" [] [] => pure ()
    | _ => ensure false "expected html element"
  | .error e => ensure false s!"parse failed: {e}"

test "parse with DOCTYPE" := do
  match parse "<!DOCTYPE html><html></html>" with
  | .ok html =>
    match html with
    | .element "html" [] [] => pure ()
    | _ => ensure false "expected html element"
  | .error e => ensure false s!"parse failed: {e}"

test "parse with comment" := do
  match parse "<!-- comment --><div></div>" with
  | .ok html =>
    match html with
    | .element "div" [] [] => pure ()
    | _ => ensure false "expected div element"
  | .error e => ensure false s!"parse failed: {e}"

test "parse fragment multiple roots" := do
  match parseFragment "<p>One</p><p>Two</p>" with
  | .ok html =>
    match html with
    | .fragment children =>
      children.length ≡ 2
    | _ => ensure false "expected fragment"
  | .error e => ensure false s!"parse failed: {e}"

test "parse fragment single root" := do
  match parseFragment "<p>Single</p>" with
  | .ok html =>
    match html with
    | .element "p" [] _ => pure ()
    | _ => ensure false "expected single p element"
  | .error e => ensure false s!"parse failed: {e}"

test "parse with head and body" := do
  match parse "<html><head><title>Test</title></head><body></body></html>" with
  | .ok html =>
    match html with
    | .element "html" [] children =>
      children.length ≡ 2
    | _ => ensure false "expected html with head and body"
  | .error e => ensure false s!"parse failed: {e}"

test "parse complex document" := do
  let doc := "<!DOCTYPE html><html><head><title>Page</title></head><body><div class=\"content\"><p>Hello &amp; welcome</p></div></body></html>"
  match parse doc with
  | .ok html =>
    match html with
    | .element "html" [] _ => pure ()
    | _ => ensure false "expected html element"
  | .error e => ensure false s!"parse failed: {e}"

test "skip multiple comments" := do
  match parse "<!-- one --><!-- two --><div></div>" with
  | .ok html =>
    match html with
    | .element "div" [] [] => pure ()
    | _ => ensure false "expected div element"
  | .error e => ensure false s!"parse failed: {e}"

test "parse inline comment" := do
  match parse "<div><!-- inline --></div>" with
  | .ok html =>
    match html with
    | .element "div" [] [] => pure ()  -- Comment produces no child
    | _ => ensure false "expected empty div"
  | .error e => ensure false s!"parse failed: {e}"

test "whitespace-only text stripped" := do
  -- Note: Whitespace-only text nodes between elements are stripped
  match parseFragment "<span>a</span> <span>b</span>" with
  | .ok html =>
    match html with
    | .fragment children =>
      -- Whitespace between elements is stripped, so just 2 spans
      children.length ≡ 2
    | _ => ensure false "expected fragment"
  | .error e => ensure false s!"parse failed: {e}"

#generate_tests

end Tests.Parser.Documents
