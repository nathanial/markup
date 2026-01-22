/-
  Tests/Parser/Elements.lean - Element parsing tests
-/

import Markup
import Crucible
import Scribe

namespace Tests.Parser.Elements

open Crucible
open Markup
open Scribe

testSuite "Element Parsing"

test "parse simple div" := do
  match parse "<div></div>" with
  | .ok html =>
    match html with
    | .element "div" [] [] => pure ()
    | _ => ensure false "expected empty div element"
  | .error e => ensure false s!"parse failed: {e}"

test "parse div with text" := do
  match parse "<div>Hello</div>" with
  | .ok html =>
    match html with
    | .element "div" [] [.text "Hello"] => pure ()
    | _ => ensure false "expected div with text"
  | .error e => ensure false s!"parse failed: {e}"

test "parse nested elements" := do
  match parse "<div><span>text</span></div>" with
  | .ok html =>
    match html with
    | .element "div" [] [.element "span" [] [.text "text"]] => pure ()
    | _ => ensure false "expected nested structure"
  | .error e => ensure false s!"parse failed: {e}"

test "parse void element br" := do
  match parse "<br>" with
  | .ok html =>
    match html with
    | .element "br" [] [] => pure ()
    | _ => ensure false "expected br element"
  | .error e => ensure false s!"parse failed: {e}"

test "parse void element img" := do
  match parse "<img src=\"test.png\">" with
  | .ok html =>
    match html with
    | .element "img" attrs [] =>
      (attrs.find? (·.name == "src")).isSome ≡ true
    | _ => ensure false "expected img element"
  | .error e => ensure false s!"parse failed: {e}"

test "parse self-closing element" := do
  match parse "<br/>" with
  | .ok html =>
    match html with
    | .element "br" [] [] => pure ()
    | _ => ensure false "expected self-closing br"
  | .error e => ensure false s!"parse failed: {e}"

test "parse self-closing with space" := do
  match parse "<br />" with
  | .ok html =>
    match html with
    | .element "br" [] [] => pure ()
    | _ => ensure false "expected self-closing br"
  | .error e => ensure false s!"parse failed: {e}"

test "parse multiple children" := do
  match parse "<ul><li>A</li><li>B</li></ul>" with
  | .ok html =>
    match html with
    | .element "ul" [] children =>
      children.length ≡ 2
    | _ => ensure false "expected ul with children"
  | .error e => ensure false s!"parse failed: {e}"

test "tag names are case-insensitive" := do
  match parse "<DIV></div>" with
  | .ok html =>
    match html with
    | .element "div" [] [] => pure ()
    | _ => ensure false "expected div (lowercase)"
  | .error e => ensure false s!"parse failed: {e}"

test "parse script raw content" := do
  match parse "<script>var x = 1 < 2;</script>" with
  | .ok html =>
    match html with
    | .element "script" [] [.raw content] =>
      content ≡ "var x = 1 < 2;"
    | _ => ensure false "expected script with raw content"
  | .error e => ensure false s!"parse failed: {e}"

test "parse style raw content" := do
  match parse "<style>.a > .b { color: red; }</style>" with
  | .ok html =>
    match html with
    | .element "style" [] [.raw _] => pure ()
    | _ => ensure false "expected style with raw content"
  | .error e => ensure false s!"parse failed: {e}"



end Tests.Parser.Elements
