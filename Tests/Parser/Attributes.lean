/-
  Tests/Parser/Attributes.lean - Attribute parsing tests
-/

import Markup
import Crucible
import Scribe

namespace Tests.Parser.Attributes

open Crucible
open Markup
open Scribe

testSuite "Attribute Parsing"

test "parse double-quoted attribute" := do
  match parse "<div class=\"foo\"></div>" with
  | .ok html =>
    match html with
    | .element "div" attrs [] =>
      (attrs.find? (·.name == "class")).map (·.value) ≡ some "foo"
    | _ => ensure false "expected div with class"
  | .error e => ensure false s!"parse failed: {e}"

test "parse single-quoted attribute" := do
  match parse "<div class='bar'></div>" with
  | .ok html =>
    match html with
    | .element "div" attrs [] =>
      (attrs.find? (·.name == "class")).map (·.value) ≡ some "bar"
    | _ => ensure false "expected div with class"
  | .error e => ensure false s!"parse failed: {e}"

test "parse unquoted attribute" := do
  match parse "<div class=simple></div>" with
  | .ok html =>
    match html with
    | .element "div" attrs [] =>
      (attrs.find? (·.name == "class")).map (·.value) ≡ some "simple"
    | _ => ensure false "expected div with class"
  | .error e => ensure false s!"parse failed: {e}"

test "parse boolean attribute" := do
  match parse "<input disabled>" with
  | .ok html =>
    match html with
    | .element "input" attrs [] =>
      (attrs.find? (·.name == "disabled")).isSome ≡ true
    | _ => ensure false "expected input with disabled"
  | .error e => ensure false s!"parse failed: {e}"

test "parse multiple attributes" := do
  match parse "<a href=\"/\" class=\"link\" id=\"home\">Home</a>" with
  | .ok html =>
    match html with
    | .element "a" attrs _ =>
      attrs.length ≡ 3
      (attrs.find? (·.name == "href")).map (·.value) ≡ some "/"
      (attrs.find? (·.name == "class")).map (·.value) ≡ some "link"
      (attrs.find? (·.name == "id")).map (·.value) ≡ some "home"
    | _ => ensure false "expected a with attributes"
  | .error e => ensure false s!"parse failed: {e}"

test "attribute names are case-insensitive" := do
  match parse "<div CLASS=\"foo\"></div>" with
  | .ok html =>
    match html with
    | .element "div" attrs [] =>
      (attrs.find? (·.name == "class")).isSome ≡ true
    | _ => ensure false "expected div with class (lowercase)"
  | .error e => ensure false s!"parse failed: {e}"

test "parse attribute with entity" := do
  match parse "<div title=\"A &amp; B\"></div>" with
  | .ok html =>
    match html with
    | .element "div" attrs [] =>
      (attrs.find? (·.name == "title")).map (·.value) ≡ some "A & B"
    | _ => ensure false "expected div with decoded title"
  | .error e => ensure false s!"parse failed: {e}"

test "parse data attributes" := do
  match parse "<div data-id=\"123\" data-name=\"test\"></div>" with
  | .ok html =>
    match html with
    | .element "div" attrs [] =>
      (attrs.find? (·.name == "data-id")).map (·.value) ≡ some "123"
      (attrs.find? (·.name == "data-name")).map (·.value) ≡ some "test"
    | _ => ensure false "expected div with data attributes"
  | .error e => ensure false s!"parse failed: {e}"

#generate_tests

end Tests.Parser.Attributes
