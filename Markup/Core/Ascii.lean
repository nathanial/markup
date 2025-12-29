/-
  Markup/Core/Ascii.lean - ASCII character classification predicates
-/

namespace Markup.Ascii

/-- Whitespace: space, tab, newline, carriage return -/
@[inline]
def isWhitespace (c : Char) : Bool :=
  c == ' ' || c == '\t' || c == '\n' || c == '\r'

/-- ASCII alphabetic character (a-z, A-Z) -/
@[inline]
def isAlpha (c : Char) : Bool :=
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')

/-- ASCII digit (0-9) -/
@[inline]
def isDigit (c : Char) : Bool :=
  c >= '0' && c <= '9'

/-- Alphanumeric character -/
@[inline]
def isAlphaNum (c : Char) : Bool :=
  isAlpha c || isDigit c

/-- Hexadecimal digit (0-9, a-f, A-F) -/
@[inline]
def isHexDigit (c : Char) : Bool :=
  isDigit c || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')

/-- Convert hex digit to numeric value -/
def hexValue (c : Char) : Option Nat :=
  if c >= '0' && c <= '9' then some (c.toNat - '0'.toNat)
  else if c >= 'a' && c <= 'f' then some (c.toNat - 'a'.toNat + 10)
  else if c >= 'A' && c <= 'F' then some (c.toNat - 'A'.toNat + 10)
  else none

/-- Valid HTML tag name start character (letters only) -/
@[inline]
def isTagNameStart (c : Char) : Bool :=
  isAlpha c

/-- Valid HTML tag name character (letters, digits, hyphens) -/
@[inline]
def isTagNameChar (c : Char) : Bool :=
  isAlphaNum c || c == '-' || c == '_' || c == ':'

/-- Valid HTML attribute name start character -/
@[inline]
def isAttrNameStart (c : Char) : Bool :=
  isAlpha c || c == '_' || c == ':'

/-- Valid HTML attribute name character -/
@[inline]
def isAttrNameChar (c : Char) : Bool :=
  isAlphaNum c || c == '-' || c == '_' || c == ':' || c == '.'

/-- Valid unquoted attribute value character -/
@[inline]
def isUnquotedAttrChar (c : Char) : Bool :=
  !isWhitespace c && c != '"' && c != '\'' && c != '=' && c != '<' && c != '>' && c != '`'

/-- Convert character to lowercase -/
@[inline]
def toLower (c : Char) : Char :=
  if c >= 'A' && c <= 'Z' then
    Char.ofNat (c.toNat - 'A'.toNat + 'a'.toNat)
  else
    c

/-- Convert string to lowercase -/
def stringToLower (s : String) : String :=
  s.map toLower

end Markup.Ascii
