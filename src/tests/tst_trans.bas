' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Dim err$
Const MAX_NUM_FILES = 5
Dim num_files = 1

#Include "unittest.inc"
#Include "../lexer.inc"
#Include "../map.inc"
#Include "../trans.inc"
#Include "../set.inc"

lx_load_keywords("\mbt\resources\keywords.txt")

add_test("test_replace")

run_tests()

End

Sub setup_test()
  err$ = ""
End Sub

Sub teardown_test()
End Sub

Function test_replace()
  map_clear(replace$(), with$(), replace_sz)
  transpile("'!replace x      y")
  transpile("'!replace &hFFFF z")

  transpile("Dim x = &hFFFF ' comment")

  expect_tokens(5)
  expect_tk(0, TK_KEYWORD, "Dim")
  expect_tk(1, TK_IDENTIFIER, "y")
  expect_tk(2, TK_SYMBOL, "=")
  expect_tk(3, TK_IDENTIFIER, "z")
  expect_tk(4, TK_COMMENT, "' comment")
  assert_string_equals("Dim y = z ' comment", lx_line$)
End Function

Sub expect_tokens(num)
  assert_no_error()
  assert_true(lx_num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx_num))
End Sub

Sub expect_tk(i, type, s$)
  assert_true(lx_type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx_type(i)))
  assert_string_equals(s$, lx_token$(i))
End Sub

