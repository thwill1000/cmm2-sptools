' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Dim err$

#Include "unittest.inc"
#Include "../options.inc"

Cls

ut_add_test("test_colour")
ut_add_test("test_comments")
ut_add_test("test_empty_lines")
ut_add_test("test_format_only")
ut_add_test("test_indent")
ut_add_test("test_spacing")
'ut_add_test("test_unknown")

ut_run_tests()

End

' TODO: automate calling this before each test function
Sub test_setup()
  err$ = ""
  op_init()
End Sub

Function test_colour()
  Local elements$(10) Length 10, i

  test_setup()
  ut_assert_equals(0, op_colour)

  elements$(0) = "0"
  elements$(1) = "off"
  elements$(2) = ""
  elements$(3) = "default"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_colour = 999
    op_set("colour", elements$(i))
    ut_assert_equals(0, op_colour)
    i = i + 1
  Loop

  elements$(0) = "1"
  elements$(1) = "on"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_colour = 999
    op_set("colour", elements$(i))
    ut_assert_equals(1, op_colour)
    i = i + 1
  Loop

  op_set("colour", "foo")
  ut_assert_string_equals("expects 'on|off' argument", err$)
End Function

Function test_comments()
  Local elements$(10) Length 10, i

  test_setup()
  ut_assert_equals(-1, op_comments)

  elements$(0) = "preserve"
  elements$(1) = "default"
  elements$(2) = "on"
  elements$(3) = "-1"
  elements$(4) = ""
  elements$(5) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_comments = 999
    op_set("comments", elements$(i))
    ut_assert_equals(-1, op_comments)
    i = i + 1
  Loop

  elements$(0) = "omit"
  elements$(1) = "off"
  elements$(2) = "none"
  elements$(3) = "0"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_comments = 999
    op_set("comments", elements$(i))
    ut_assert_equals(0, op_comments)
    i = i + 1
  Loop

  op_set("comments", "foo")
  ut_assert_string_equals("expects 'on|off' argument", err$)
End Function

Function test_empty_lines()
  Local elements$(10) Length 10, i

  test_setup()
  ut_assert_equals(-1, op_empty_lines)

  elements$(0) = "preserve"
  elements$(1) = "default"
  elements$(1) = "on"
  elements$(2) = "-1"
  elements$(3) = ""
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_empty_lines = 999
    op_set("empty-lines", elements$(i))
    ut_assert_equals(-1, op_empty_lines)
    i = i + 1
  Loop

  elements$(0) = "none"
  elements$(1) = "omit"
  elements$(2) = "off"
  elements$(3) = "0"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_comments = 999
    op_set("empty-lines", elements$(i))
    ut_assert_equals(0, op_empty_lines)
    i = i + 1
  Loop

  elements$(0) = "single"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_comments = 999
    op_set("empty-lines", elements$(i))
    ut_assert_equals(1, op_empty_lines)
    i = i + 1
  Loop

  op_set("empty-lines", "foo")
  ut_assert_string_equals("expects 'on|off|single' argument", err$)
End Function

Function test_format_only()
  Local elements$(10) Length 10, i

  test_setup()
  ut_assert_equals(0, op_format_only)

  elements$(0) = "0"
  elements$(1) = "off"
  elements$(2) = ""
  elements$(3) = "default"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_format_only = 999
    op_set("format-only", elements$(i))
    ut_assert_equals(0, op_format_only)
    i = i + 1
  Loop

  elements$(0) = "1"
  elements$(1) = "on"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_format_only = 999
    op_set("format-only", elements$(i))
    ut_assert_equals(1, op_format_only)
    i = i + 1
  Loop

  op_set("format-only", "foo")
  ut_assert_string_equals("expects 'on|off' argument", err$)
End Function

Function test_indent()
  Local elements$(10) Length 10, i

  test_setup()
  ut_assert_equals(-1, op_indent_sz)

  elements$(0) = "-1"
  elements$(1) = "preserve"
  elements$(2) = ""
  elements$(3) = "default"
  elements$(4) = "on"
  elements$(5) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_indent_sz = 999
    op_set("indent", elements$(i))
    ut_assert_equals(-1, op_indent_sz)
    i = i + 1
  Loop

  elements$(0) = "0"
  elements$(1) = "1"
  elements$(2) = "2"
  elements$(3) = "3"
  elements$(4) = "4"
  elements$(5) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_indent_sz = 999
    op_set("indent", elements$(i))
    ut_assert_equals(i, op_indent_sz)
    i = i + 1
  Loop

  err$ = ""
  op_set("indent", "foo")
  ut_assert_string_equals("expects 'on|<number>' argument", err$)

  err$ = ""
  op_set("indent", "-2")
  ut_assert_string_equals("expects 'on|<number>' argument", err$)
End Function

Function test_spacing()
  Local elements$(10) Length 10, i

  test_setup()
  ut_assert_equals(-1, op_spacing)

  elements$(0) = "preserve"
  elements$(1) = "default"
  elements$(2) = "on"
  elements$(3) = ""
  elements$(4) = "-1"
  elements$(5) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_spacing = 999
    op_set("spacing", elements$(i))
    ut_assert_equals(-1, op_spacing)
    i = i + 1
  Loop

  elements$(0) = "minimal"
  elements$(1) = "0"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_spacing = 999
    op_set("spacing", elements$(i))
    ut_assert_equals(0, op_spacing)
    i = i + 1
  Loop

  elements$(0) = "compact"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_spacing = 999
    op_set("spacing", elements$(i))
    ut_assert_equals(1, op_spacing)
    i = i + 1
  Loop

  elements$(0) = "generous"
  elements$(1) = "2"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    op_spacing = 999
    op_set("spacing", elements$(i))
    ut_assert_equals(2, op_spacing)
    i = i + 1
  Loop

  err$ = ""
  op_set("spacing", "foo")
  ut_assert_string_equals("expects 'on|minimal|compact|generous' argument", err$)

  err$ = ""
  op_set("spacing", "3")
  ut_assert_string_equals("expects 'on|minimal|compact|generous' argument", err$)
End Function

