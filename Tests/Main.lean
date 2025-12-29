/-
  Tests/Main.lean - Test entry point for Markup HTML parser
-/

import Crucible
import Tests.Parser.Elements
import Tests.Parser.Attributes
import Tests.Parser.Entities
import Tests.Parser.Documents
import Tests.Parser.Errors

open Crucible

def main : IO UInt32 := runAllSuites
