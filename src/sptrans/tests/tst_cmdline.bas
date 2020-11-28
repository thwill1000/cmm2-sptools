' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../../common/system.inc"
#Include "../../common/array.inc"
#Include "../../common/list.inc"
#Include "../../common/string.inc"
#Include "../../common/file.inc"
#Include "../../common/set.inc"
#Include "../../common/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../lexer.inc"
#Include "../cmdline.inc"
#Include "../options.inc"

Const input_file$ = Chr$(34) + "input.bas" + Chr$(34)
Const output_file$ = Chr$(34) + "output.bas" + Chr$(34)

add_test("test_no_input_file")
add_test("test_input_file")
add_test("test_unquoted_input_file")
add_test("test_colour")
add_test("test_no_comments")
add_test("test_empty_lines")
add_test("test_format_only")
add_test("test_indent")
add_test("test_spacing")
add_test("test_output_file")
add_test("test_unquoted_output_file")
add_test("test_unknown_option")
add_test("test_too_many_arguments")
add_test("test_everything")

run_tests()

End

Sub setup_test()
  opt.init()
End Sub

Sub teardown_test()
End Sub

Sub test_no_input_file()
  cli.parse("-f")

  assert_error("no input file specified")
End Sub

Sub test_input_file()
  cli.parse(input_file$)

  assert_no_error()
  assert_string_equals("input.bas", opt.infile$)
End Sub

Sub test_unquoted_input_file()
  cli.parse("input.bas")

  assert_error("input file name must be quoted")
End Sub

Sub test_colour()
  cli.parse("--colour " + input_file$)
  assert_no_error()
  assert_equals(1, opt.colour)

  cli.parse("-C=1 " + input_file$)
  assert_error("option '-C' does not expect argument")
End Sub

Sub test_no_comments()
  opt.comments = 999
  cli.parse("--no-comments " + input_file$)
  assert_no_error()
  assert_equals(0, opt.comments)

  opt.comments = 999
  cli.parse("-n " + input_file$)
  assert_no_error()
  assert_equals(0, opt.comments)

  cli.parse("--no-comments=1" + input_file$)
  assert_error("option '--no-comments' does not expect argument")
End Sub

Sub test_empty_lines()
  cli.parse("--empty-lines=0 " + input_file$)
  assert_no_error()
  assert_equals(0, opt.empty_lines)

  cli.parse("--empty-lines=1 " + input_file$)
  assert_no_error()
  assert_equals(1, opt.empty_lines)

  cli.parse("--empty-lines " + input_file$)
  assert_error("option '--empty-lines' expects {0|1} argument")

  cli.parse("--empty-lines=3" + input_file$)
  assert_error("option '--empty-lines' expects {0|1} argument")
End Sub

Sub test_format_only()
  cli.parse("--format-only " + input_file$)
  assert_no_error()
  assert_equals(1, opt.format_only)

  cli.parse("-f=1 " + input_file$)
  assert_error("option '-f' does not expect argument")
End Sub

Sub test_indent()
  cli.parse("--indent=0 " + input_file$)
  assert_no_error()
  assert_equals(0, opt.indent_sz)

  cli.parse("--indent=1 " + input_file$)
  assert_no_error()
  assert_equals(1, opt.indent_sz)

  cli.parse("--indent " + input_file$)
  assert_error("option '--indent' expects <number> argument")

  cli.parse("--indent=3 " + input_file$)
  assert_no_error()
  assert_equals(3, opt.indent_sz)
End Sub

Sub test_spacing()
  cli.parse("--spacing=0 " + input_file$)
  assert_no_error()
  assert_equals(0, opt.spacing)

  cli.parse("--spacing=1 " + input_file$)
  assert_no_error()
  assert_equals(1, opt.spacing)

  cli.parse("--spacing=2 " + input_file$)
  assert_no_error()
  assert_equals(2, opt.spacing)

  cli.parse("--spacing " + input_file$)
  assert_error("option '--spacing' expects {0|1|2} argument")

  cli.parse("--spacing=3 " + input_file$)
  assert_error("option '--spacing' expects {0|1|2} argument")
End Sub

Sub test_output_file()
  cli.parse(input_file$ + " " + output_file$)

  assert_no_error()
  assert_string_equals("input.bas", opt.infile$)
  assert_string_equals("output.bas", opt.outfile$)
End Sub

Sub test_unquoted_output_file()
  cli.parse(input_file$ + " output.bas")

  assert_error("output file name must be quoted")
End Sub

Sub test_unknown_option()
  cli.parse("--wombat " + input_file$)

  assert_error("option '--wombat' is unknown")
End Sub

Sub test_too_many_arguments()
  cli.parse(input_file$ + " " + output_file$ + " wombat")

  assert_error("unexpected argument 'wombat'")
End Sub

Sub test_everything()
  cli.parse("-f -C -e=1 -i=2 -s=0 -n " + input_file$ + " " + output_file$)

  assert_no_error()
  assert_equals(1, opt.format_only)
  assert_string_equals("input.bas", opt.infile$)
  assert_string_equals("output.bas", opt.outfile$)
  assert_equals(1, opt.colour)
  assert_equals(0, opt.comments)
  assert_equals(1, opt.empty_lines)
  assert_equals(2, opt.indent_sz)
  assert_equals(0, opt.spacing)
End Sub
