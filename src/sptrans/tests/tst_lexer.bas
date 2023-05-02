' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Explicit On
Option Default Integer

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/map.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../../common/sptools.inc"
#Include "../keywords.inc"
#Include "../lexer.inc"

keywords.init()

add_test("test_binary_literals")
add_test("test_comments")
add_test("test_directives")
add_test("test_directive_given_comments")
add_test("test_directive_given_not_first")
add_test("test_replace_directives")
add_test("test_hexadecimal_literals")
add_test("test_identifiers")
add_test("test_includes")
add_test("test_integer_literals")
add_test("test_integer_literals_with_e")
add_test("test_keywords")
add_test("test_octal_literals")
add_test("test_real_literals")
add_test("test_string_literals")
add_test("test_string_no_closing_quote")
add_test("test_symbols")
add_test("test_extended_symbols")
add_test("test_labels")
add_test("test_get_number")
add_test("test_get_string")
add_test("test_get_directive")
add_test("test_get_token_lc")
add_test("test_old_tokens_cleared")
add_test("test_parse_command_line")
add_test("test_csub")
add_test("test_insert_token")
add_test("test_remove_token")
add_test("test_replace_token")

run_tests()

End

Sub test_binary_literals()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("&b1001001"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER, "&b1001001")

  ' Because the lexer accepts BBC micro-style hex numbers this is
  ' not considered a syntax error, and nor does it result in two
  ' separate tokens "&B01" and "23456789".
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("&B0123456789"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER, "&B0123456789")
End Sub

Sub test_comments()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("' This is a comment"))
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "' This is a comment");

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("REM This is also a comment"))
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "REM This is also a comment");
End Sub

Sub test_directives()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!comment_if foo"))
  expect_token_count(2)
  expect_token(0, TK_DIRECTIVE, "'!comment_if")
  expect_token(1, TK_IDENTIFIER, "foo")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!empty-lines off"))
  expect_token_count(2)
  expect_token(0, TK_DIRECTIVE, "'!empty-lines")
  expect_token(1, TK_KEYWORD, "off")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!ifdef foo"))
  expect_token_count(2)
  expect_token(0, TK_DIRECTIVE, "'!ifdef")
  expect_token(1, TK_IDENTIFIER, "foo")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!ifndef foo"))
  expect_token_count(2)
  expect_token(0, TK_DIRECTIVE, "'!ifndef")
  expect_token(1, TK_IDENTIFIER, "foo")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!elif"))
  expect_token_count(1)
  expect_token(0, TK_DIRECTIVE, "'!elif")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!endif"))
  expect_token_count(1)
  expect_token(0, TK_DIRECTIVE, "'!endif")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!info defined foo"))
  expect_token_count(3)
  expect_token(0, TK_DIRECTIVE, "'!info")
  expect_token(1, TK_IDENTIFIER, "defined")
  expect_token(2, TK_IDENTIFIER, "foo")
End Sub

Sub test_directive_given_comments()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!endif ' my comment"))
  expect_token_count(2)
  expect_token(0, TK_DIRECTIVE, "'!endif")
  expect_token(1, TK_COMMENT, "' my comment")
End Sub

' A directive should only be recognised as such if it is the first token on a line
Sub test_directive_given_not_first()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("PRINT '!ifdef FOO"))
  expect_token_count(2)
  expect_token(0, TK_KEYWORD, "PRINT")
  expect_token(1, TK_COMMENT, "'!ifdef FOO")
End Sub

Sub test_replace_directives()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!replace DEF Sub"))
  expect_token_count(3)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_KEYWORD,   "DEF")
  expect_token(2, TK_KEYWORD,   "Sub")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!replace ENDPROC { End Sub }"))
  expect_token_count(6)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_KEYWORD,   "ENDPROC")
  expect_token(2, TK_SYMBOL,    "{")
  expect_token(3, TK_KEYWORD,   "End")
  expect_token(4, TK_KEYWORD,   "Sub")
  expect_token(5, TK_SYMBOL,    "}")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!replace { THEN ENDPROC } { Then Exit Sub }"))
  expect_token_count(10)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_SYMBOL,    "{")
  expect_token(2, TK_KEYWORD,   "THEN")
  expect_token(3, TK_KEYWORD,   "ENDPROC")
  expect_token(4, TK_SYMBOL,    "}")
  expect_token(5, TK_SYMBOL,    "{")
  expect_token(6, TK_KEYWORD,   "Then")
  expect_token(7, TK_KEYWORD,   "Exit")
  expect_token(8, TK_KEYWORD,   "Sub")
  expect_token(9, TK_SYMBOL,    "}")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!replace GOTO%d { Goto %1 }"))
  expect_token_count(6)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_KEYWORD,   "GOTO%d")
  expect_token(2, TK_SYMBOL,    "{")
  expect_token(3, TK_KEYWORD,   "Goto")
  expect_token(4, TK_KEYWORD,   "%1")
  expect_token(5, TK_SYMBOL,    "}")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!replace { THEN %d } { Then Goto %1 }"))
  expect_token_count(10)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_SYMBOL,    "{")
  expect_token(2, TK_KEYWORD,   "THEN")
  expect_token(3, TK_KEYWORD,   "%d")
  expect_token(4, TK_SYMBOL,    "}")
  expect_token(5, TK_SYMBOL,    "{")
  expect_token(6, TK_KEYWORD,   "Then")
  expect_token(7, TK_KEYWORD,   "Goto")
  expect_token(8, TK_KEYWORD,   "%1")
  expect_token(9, TK_SYMBOL,    "}")

  ' Apostrophes inside directives are accepted as identifier characters.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!replace '%% { CRLF %1 }"))
  expect_token_count(6)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_KEYWORD,   "'%%")
  expect_token(2, TK_SYMBOL,    "{")
  expect_token(3, TK_KEYWORD,   "CRLF")
  expect_token(4, TK_KEYWORD,   "%1")
  expect_token(5, TK_SYMBOL,    "}")

  ' REM commands inside directives are treated as keywords not as the prefix of a comment.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!replace REM foo"))
  expect_token_count(3)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_KEYWORD,   "REM")
  expect_token(2, TK_KEYWORD,   "foo")
End Sub

Sub test_includes()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("#Include " + str.quote$("foo.inc")))
  expect_token_count(2)
  expect_token(0, TK_KEYWORD, "#Include")
  expect_token(1, TK_STRING, str.quote$("foo.inc"))
End Sub

Sub test_hexadecimal_literals()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("&hABCDEF"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER, "&hABCDEF")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("&Habcdefghijklmn"))
  expect_token_count(2)
  expect_token(0, TK_NUMBER, "&Habcdef")
  expect_token(1, TK_IDENTIFIER, "ghijklmn")

  ' To facilitate transpiling BBC Basic source code the lexer accepts
  ' hex numbers which begin just & instead of &h.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("&ABCDEF"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER, "&ABCDEF")
End Sub

Sub test_identifiers()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("xx s$ foo.bar wom.bat$ a! b%"))
  expect_token_count(6)
  expect_token(0, TK_IDENTIFIER, "xx")
  expect_token(1, TK_IDENTIFIER, "s$")
  expect_token(2, TK_IDENTIFIER, "foo.bar")
  expect_token(3, TK_IDENTIFIER, "wom.bat$")
  expect_token(4, TK_IDENTIFIER, "a!")
  expect_token(5, TK_IDENTIFIER, "b%")
End Sub

Sub test_integer_literals()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("421"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER, "421")
End Sub

Sub test_integer_literals_with_e()
  ' If there is just a trailing E then it is part of the number literal.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("12345E"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER,     "12345E")

  ' Otherwise it is the start of a separate identifier.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("12345ENDPROC"))
  expect_token_count(2)
  expect_token(0, TK_NUMBER,     "12345")
  expect_token(1, TK_IDENTIFIER, "ENDPROC")
End Sub

Sub test_keywords()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("For Next Do Loop Chr$"))
  expect_token_count(5)
  expect_token(0, TK_KEYWORD, "For")
  expect_token(1, TK_KEYWORD, "Next")
  expect_token(2, TK_KEYWORD, "Do")
  expect_token(3, TK_KEYWORD, "Loop")
  expect_token(4, TK_KEYWORD, "Chr$")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  #gps @ YELLOW  "))
  expect_token_count(3)
  expect_token(0, TK_KEYWORD, "#gps")
  expect_token(1, TK_KEYWORD, "@")
  expect_token(2, TK_KEYWORD, "YELLOW")
End Sub

Sub test_octal_literals()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("&O1234"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER, "&O1234")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("&O123456789"))
  expect_token_count(2)
  expect_token(0, TK_NUMBER, "&O1234567")
  expect_token(1, TK_NUMBER, "89")
End Sub

Sub test_real_literals()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("3.421"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER, "3.421")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("3.421e5"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER, "3.421e5")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("3.421e-17"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER, "3.421e-17")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("3.421e+17"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER, "3.421e+17")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%(".3421"))
  expect_token_count(1)
  expect_token(0, TK_NUMBER, ".3421")
End Sub

Sub test_string_literals()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%(str.quote$("This is a string")))
  expect_token_count(1)
  expect_token(0, TK_STRING, str.quote$("This is a string"))
End Sub

Sub test_string_no_closing_quote()
  assert_int_equals(sys.FAILURE, lx.parse_basic%(Chr$(34) + "String literal with no closing quote"))
  assert_error("No closing quote")
End Sub

Sub test_symbols()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("a=b/c*d\e<=f=<g>=h=>i:j;k,l<m>n"))
  expect_token_count(27)
  expect_token(0, TK_IDENTIFIER, "a")
  expect_token(1, TK_SYMBOL, "=")
  expect_token(2, TK_IDENTIFIER, "b")
  expect_token(3, TK_SYMBOL, "/")
  expect_token(4, TK_IDENTIFIER, "c")
  expect_token(5, TK_SYMBOL, "*")
  expect_token(6, TK_IDENTIFIER, "d")
  expect_token(7, TK_SYMBOL, "\")
  expect_token(8, TK_IDENTIFIER, "e")
  expect_token(9, TK_SYMBOL, "<=")
  expect_token(10, TK_IDENTIFIER, "f")
  expect_token(11, TK_SYMBOL, "=<")
  expect_token(12, TK_IDENTIFIER, "g")
  expect_token(13, TK_SYMBOL, ">=")
  expect_token(14, TK_IDENTIFIER, "h")
  expect_token(15, TK_SYMBOL, "=>")
  expect_token(16, TK_IDENTIFIER, "i")
  expect_token(17, TK_SYMBOL, ":")
  expect_token(18, TK_IDENTIFIER, "j")
  expect_token(19, TK_SYMBOL, ";")
  expect_token(20, TK_IDENTIFIER, "k")
  expect_token(21, TK_SYMBOL, ",")
  expect_token(22, TK_IDENTIFIER, "l")
  expect_token(23, TK_SYMBOL, "<")
  expect_token(24, TK_IDENTIFIER, "m")
  expect_token(25, TK_SYMBOL, ">")
  expect_token(26, TK_IDENTIFIER, "n")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("a$(i + 1)"))
  expect_token_count(6)
  expect_token(0, TK_IDENTIFIER, "a$")
  expect_token(1, TK_SYMBOL, "(")
  expect_token(2, TK_IDENTIFIER, "i")
  expect_token(3, TK_SYMBOL, "+")
  expect_token(4, TK_NUMBER, "1")
  expect_token(5, TK_SYMBOL, ")")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("xx=xx+1"))
  expect_token_count(5)
  expect_token(0, TK_IDENTIFIER, "xx")
  expect_token(1, TK_SYMBOL, "=")
  expect_token(2, TK_IDENTIFIER, "xx")
  expect_token(3, TK_SYMBOL, "+")
  expect_token(4, TK_NUMBER, "1")
End Sub

Sub test_extended_symbols()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("&& ||"))
  expect_token_count(2)
  expect_token(0, TK_SYMBOL, "&&")
  expect_token(1, TK_SYMBOL, "||")
End Sub

Sub test_labels()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  label:"))
  expect_token_count(1)
  expect_token(0, TK_LABEL, "label:")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  label: not_a_label:"))
  expect_token_count(3)
  expect_token(0, TK_LABEL,      "label:")
  expect_token(1, TK_IDENTIFIER, "not_a_label")
  expect_token(2, TK_SYMBOL,     ":")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  not_a_label : not_a_label:"))
  expect_token_count(4)
  expect_token(0, TK_IDENTIFIER, "not_a_label")
  expect_token(1, TK_SYMBOL,     ":")
  expect_token(2, TK_IDENTIFIER, "not_a_label")
  expect_token(3, TK_SYMBOL,     ":")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  1234: ' label"))
  expect_token_count(2)
  expect_token(0, TK_LABEL,   "1234:")
  expect_token(1, TK_COMMENT, "' label")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  1234 ' not a label"))
  expect_token_count(2)
  expect_token(0, TK_NUMBER,  "1234")
  expect_token(1, TK_COMMENT, "' not a label")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  foo 1234: ' not a label"))
  expect_token_count(4)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_NUMBER,     "1234")
  expect_token(2, TK_SYMBOL,     ":")
  expect_token(3, TK_COMMENT,    "' not a label")

End Sub

Sub test_get_number()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("1 2 3.14 3.14e-15"))
  assert_float_equals(1, lx.number!(0))
  assert_float_equals(2, lx.number!(1))
  assert_float_equals(3.14, lx.number!(2))
  assert_float_equals(3.14e-15, lx.number!(3))
End Sub

Sub test_get_string()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%(str.quote$("foo") + " " + str.quote$("wom bat")))
  assert_string_equals("foo", lx.string$(0))
  assert_string_equals("wom bat", lx.string$(1))
End Sub

Sub test_get_directive()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("'!foo"))
  assert_string_equals("!foo", lx.directive$(0))
End Sub

Sub test_get_token_lc()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("FOO '!BAR 1E7"))
  assert_string_equals("foo", lx.token_lc$(0))
  assert_string_equals("'!bar 1e7", lx.token_lc$(1))
End Sub

Sub test_parse_command_line()
  ' assert_int_equals(sys.SUCCESS, lx.parse_command_line%("--foo -bar /wombat"))
  assert_int_equals(sys.SUCCESS, lx.parse_command_line%("--foo -bar"))
  assert_string_equals("--foo", lx.token_lc$(0))
  assert_string_equals("foo", lx.option$(0))
  assert_string_equals("-bar", lx.token_lc$(1))
  assert_string_equals("bar", lx.option$(1))
  ' assert_string_equals("/wombat", lx.token_lc$(2))
  ' assert_string_equals("wombat", lx.option$(2))

  assert_int_equals(sys.FAILURE, lx.parse_command_line%("--"))
  assert_error("Illegal command-line option format: --")

  assert_int_equals(sys.FAILURE, lx.parse_command_line%("-"))
  assert_error("Illegal command-line option format: -")

  ' assert_int_equals(sys.FAILURE, lx.parse_command_line%("/"))
  ' assert_error("Illegal command-line option format: /")

  assert_int_equals(sys.FAILURE, lx.parse_command_line%("--foo@ bar"))
  assert_error("Illegal command-line option format: --foo@")

  ' Given hyphen in unquoted argument.
  assert_int_equals(sys.SUCCESS, lx.parse_command_line%("foo-bar.bas"))
  assert_string_equals("foo-bar.bas", lx.token$(0))
  assert_int_equals(TK_IDENTIFIER, lx.type(0))

  ' Given forward slash in unquoted argument.
  assert_int_equals(sys.SUCCESS, lx.parse_command_line%("foo/bar.bas"))
  assert_string_equals("foo/bar.bas", lx.token$(0))
  assert_int_equals(TK_IDENTIFIER, lx.type(0))
End Sub

Sub test_old_tokens_cleared()
  Local i

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("Dim s$(20) Length 20"))
  assert_int_equals(7, lx.num)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("' comment"))
  assert_int_equals(1, lx.num)
  For i = 1 To 10
    assert_int_equals(0, lx.type(i))
    assert_int_equals(0, lx.start(i))
    assert_int_equals(0, lx.len(i))
  Next i
End Sub

Sub test_csub()
  ' Within the confines of the CSUB we expect numbers to be treated as identifiers.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("CSub foo() 00000000 00AABBCC 0.7 &hFF &b0101 &o1234 FFFFFFFF End CSub"))
  expect_token_count(13)
  expect_token(0, TK_KEYWORD,    "CSub")
  expect_token(1, TK_IDENTIFIER, "foo")
  expect_token(2, TK_SYMBOL,     "(")
  expect_token(3, TK_SYMBOL,     ")")
  expect_token(4, TK_IDENTIFIER, "00000000")
  expect_token(5, TK_IDENTIFIER, "00AABBCC")
  expect_token(6, TK_IDENTIFIER, "0.7")
  expect_token(7, TK_IDENTIFIER, "&hFF")
  expect_token(8, TK_IDENTIFIER, "&b0101")
  expect_token(9, TK_IDENTIFIER, "&o1234")
  expect_token(10, TK_IDENTIFIER, "FFFFFFFF")
  expect_token(11, TK_KEYWORD,    "End")
  expect_token(12, TK_KEYWORD,    "CSub")

  ' But once we get outside the CSUB numbers and identifiers are distinct again.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("0.12345 00AABBCC"))
  expect_token_count(3)
  expect_token(0, TK_NUMBER,     "0.12345")
  expect_token(1, TK_NUMBER,     "00")
  expect_token(2, TK_IDENTIFIER, "AABBCC")

  ' It should also work when the CSUB is split over multiple lines.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("CSub foo() ' comment"))
  expect_token_count(5)
  expect_token(0, TK_KEYWORD,    "CSub")
  expect_token(1, TK_IDENTIFIER, "foo")
  expect_token(2, TK_SYMBOL,     "(")
  expect_token(3, TK_SYMBOL,     ")")
  expect_token(4, TK_COMMENT,    "' comment")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  00000000"))
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "00000000")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  00AABBCC 0.7 &hFF &b0101 &o1234 FFFFFFFF"))
  expect_token_count(6)
  expect_token(0, TK_IDENTIFIER, "00AABBCC")
  expect_token(1, TK_IDENTIFIER, "0.7")
  expect_token(2, TK_IDENTIFIER, "&hFF")
  expect_token(3, TK_IDENTIFIER, "&b0101")
  expect_token(4, TK_IDENTIFIER, "&o1234")
  expect_token(5, TK_IDENTIFIER, "FFFFFFFF")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("End CSub"))
  expect_token_count(2)
  expect_token(0, TK_KEYWORD, "End")
  expect_token(1, TK_KEYWORD, "CSub")

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("0.12345 00AABBCC"))
  expect_token_count(3)
  expect_token(0, TK_NUMBER,     "0.12345")
  expect_token(1, TK_NUMBER,     "00")
  expect_token(2, TK_IDENTIFIER, "AABBCC")
End Sub

Sub test_insert_token()
  ' Test insertion into an empty line.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%(""))
  lx.insert_token(0, "foo", TK_IDENTIFIER)
  assert_string_equals("foo", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "foo", 1)

  ' Test insertion into a line only containing whitespace.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  "))
  lx.insert_token(0, "foo", TK_IDENTIFIER)
  assert_string_equals("  foo", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "foo", 3)

  ' Test insertion before the first token.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  foo"))
  lx.insert_token(0, "bar", TK_IDENTIFIER)
  assert_string_equals("  bar foo", lx.line$)
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "bar", 3)
  expect_token(1, TK_IDENTIFIER, "foo", 7)

  ' Test insertion after the last token.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  foo"))
  lx.insert_token(1, "bar", TK_IDENTIFIER)
  assert_string_equals("  foo bar", lx.line$)
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "foo", 3)
  expect_token(1, TK_IDENTIFIER, "bar", 7)

  ' Test insertion between two tokens.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  foo  bar"))
  lx.insert_token(1, "wombat", TK_IDENTIFIER)
  assert_string_equals("  foo wombat  bar", lx.line$)
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "foo", 3)
  expect_token(1, TK_IDENTIFIER, "wombat", 7)
  expect_token(2, TK_IDENTIFIER, "bar", 15)
End Sub

Sub test_remove_token()
  ' Test removing the first (index = 0) token.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  token1 token2  token3"))
  lx.remove_token(0)
  assert_string_equals("  token2  token3", lx.line$)
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "token2", 3)
  expect_token(1, TK_IDENTIFIER, "token3", 11)

  ' Test removing the last token.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  token1 token2  token3"))
  lx.remove_token(2)
  assert_string_equals("  token1 token2", lx.line$)
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "token1", 3)
  expect_token(1, TK_IDENTIFIER, "token2", 10)

  ' Test removing an intermediate token.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  token1 token2  token3"))
  lx.remove_token(1)
  assert_string_equals("  token1  token3", lx.line$)
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "token1", 3)
  expect_token(1, TK_IDENTIFIER, "token3", 11)

  ' Test removing the only token.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  token1  "))
  lx.remove_token(0)
  assert_string_equals("  ", lx.line$)
  expect_token_count(0)

  ' Test something more interesting.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("let y(3) = (" + str.quote$("foo") + ", " + str.quote$("bar") + ")"))
  lx.remove_token(2)
  lx.remove_token(2)
  lx.remove_token(2)
  assert_string_equals("let y = (" + str.quote$("foo") + ", " + str.quote$("bar") + ")", lx.line$)
  expect_token_count(8)
  expect_token(0, TK_KEYWORD, "let", 1)
  expect_token(1, TK_IDENTIFIER, "y", 5)
  expect_token(2, TK_SYMBOL, "=", 7)
  expect_token(3, TK_SYMBOL, "(", 9)
  expect_token(4, TK_STRING, str.quote$("foo"), 10)
  expect_token(5, TK_SYMBOL, ",", 15)
  expect_token(6, TK_STRING, str.quote$("bar"), 17)
  expect_token(7, TK_SYMBOL, ")", 22)
End Sub

Sub test_replace_token()
  ' Test replacing the first (index = 0) token.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%(" one  two   three"))
  lx.replace_token(0, "wombat", TK_KEYWORD)
  assert_string_equals(" wombat  two   three", lx.line$)
  expect_token_count(3)
  expect_token(0, TK_KEYWORD, "wombat", 2)
  expect_token(1, TK_IDENTIFIER, "two", 10)
  expect_token(2, TK_IDENTIFIER, "three", 16)

  ' Test replacing an intermediate token.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%(" one  two   three"))
  lx.replace_token(1, "wombat", TK_KEYWORD)
  assert_string_equals(" one  wombat   three", lx.line$)
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "one", 2)
  expect_token(1, TK_KEYWORD, "wombat", 7)
  expect_token(2, TK_IDENTIFIER, "three", 16)

  ' Test replacing the last token.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%(" one  two   three"))
  lx.replace_token(2, "wombat", TK_KEYWORD)
  assert_string_equals(" one  two   wombat", lx.line$)
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "one", 2)
  expect_token(1, TK_IDENTIFIER, "two", 7)
  expect_token(2, TK_KEYWORD, "wombat", 13)

  ' Test replacing the only token.
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  token1  "))
  lx.replace_token(0, "wombat", TK_KEYWORD)
  assert_string_equals("  wombat  ", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_KEYWORD, "wombat", 3)
End Sub

Sub expect_token_count(num)
  assert_no_error()
  assert_true(lx.num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx.num))
End Sub

Sub expect_token(i, type, s$, start%)
  assert_true(lx.type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx.type(i)))
  Local actual$ = lx.token$(i)
  assert_true(actual$ = s$, "expected " + s$ + ", found " + actual$)
  assert_int_equals(Len(s$), lx.len(i%))
  If start% > 0 Then assert_int_equals(start%, lx.start(i%))
End Sub

