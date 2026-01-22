/-
  Tests/Parser/Entities.lean - Entity decoding tests
-/

import Markup
import Crucible
import Scribe

namespace Tests.Parser.Entities

open Crucible
open Markup
open Scribe

testSuite "Entity Parsing"

test "decode amp entity" := do
  match parse "<p>A &amp; B</p>" with
  | .ok html =>
    match html with
    | .element "p" [] [.text text] =>
      text ≡ "A & B"
    | _ => ensure false "expected p with text"
  | .error e => ensure false s!"parse failed: {e}"

test "decode lt entity" := do
  match parse "<p>1 &lt; 2</p>" with
  | .ok html =>
    match html with
    | .element "p" [] [.text text] =>
      text ≡ "1 < 2"
    | _ => ensure false "expected p with text"
  | .error e => ensure false s!"parse failed: {e}"

test "decode gt entity" := do
  match parse "<p>2 &gt; 1</p>" with
  | .ok html =>
    match html with
    | .element "p" [] [.text text] =>
      text ≡ "2 > 1"
    | _ => ensure false "expected p with text"
  | .error e => ensure false s!"parse failed: {e}"

test "decode quot entity" := do
  match parse "<p>&quot;quoted&quot;</p>" with
  | .ok html =>
    match html with
    | .element "p" [] [.text text] =>
      text ≡ "\"quoted\""
    | _ => ensure false "expected p with text"
  | .error e => ensure false s!"parse failed: {e}"

test "decode apos entity" := do
  match parse "<p>it&apos;s</p>" with
  | .ok html =>
    match html with
    | .element "p" [] [.text text] =>
      text ≡ "it's"
    | _ => ensure false "expected p with text"
  | .error e => ensure false s!"parse failed: {e}"

test "decode nbsp entity" := do
  match parse "<p>a&nbsp;b</p>" with
  | .ok html =>
    match html with
    | .element "p" [] [.text text] =>
      text.length ≡ 3  -- a + nbsp + b
    | _ => ensure false "expected p with text"
  | .error e => ensure false s!"parse failed: {e}"

test "decode decimal entity" := do
  match parse "<p>&#65;</p>" with  -- 65 = 'A'
  | .ok html =>
    match html with
    | .element "p" [] [.text text] =>
      text ≡ "A"
    | _ => ensure false "expected p with text"
  | .error e => ensure false s!"parse failed: {e}"

test "decode hex entity lowercase" := do
  match parse "<p>&#x41;</p>" with  -- 0x41 = 'A'
  | .ok html =>
    match html with
    | .element "p" [] [.text text] =>
      text ≡ "A"
    | _ => ensure false "expected p with text"
  | .error e => ensure false s!"parse failed: {e}"

test "decode hex entity uppercase" := do
  match parse "<p>&#X42;</p>" with  -- 0x42 = 'B'
  | .ok html =>
    match html with
    | .element "p" [] [.text text] =>
      text ≡ "B"
    | _ => ensure false "expected p with text"
  | .error e => ensure false s!"parse failed: {e}"

test "decode multiple entities" := do
  match parse "<p>&lt;div&gt; &amp; &lt;span&gt;</p>" with
  | .ok html =>
    match html with
    | .element "p" [] [.text text] =>
      text ≡ "<div> & <span>"
    | _ => ensure false "expected p with text"
  | .error e => ensure false s!"parse failed: {e}"

test "decode unicode entity" := do
  match parse "<p>&#x20AC;</p>" with  -- Euro sign
  | .ok html =>
    match html with
    | .element "p" [] [.text text] =>
      text ≡ "€"
    | _ => ensure false "expected p with text"
  | .error e => ensure false s!"parse failed: {e}"



end Tests.Parser.Entities
