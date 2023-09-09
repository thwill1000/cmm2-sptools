' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("map2")
sys.provides("symbols")
If sys.err$ <> "" Then Error sys.err$

Const sym.MAX_FILES% = 32
Const sym.MAX_FUNCTIONS% = 256
Const sym.MAX_IDS% = 4096
Const sym.MAX_ID_LEN% = 33
Const sym.MAX_PATH_LEN% = 128
Const sym.REFERENCES_SIZE_KB% = 32

' Files table/map data:
'   K is case-sensitive file path
'   V is "<file index>"
Dim sym.files$(map2.new%(sym.MAX_FILES%)) Length sym.MAX_PATH_LEN%+8

' Functions table/map data:
'   K is lower-case function name
'   V is "<function name>,<file index>,<line number>,<reference offset>,<identifier index>"
Dim sym.functions$(map2.new%(sym.MAX_FUNCTIONS%)) Length 80

' Identifiers table/map data:
'   K is lower-case identifier
'   V is "<identifier index>"
Dim sym.ids$(map2.new%(sym.MAX_IDS%)) Length sym.MAX_ID_LEN% + 8

' References table data:
'   Entries are unsigned 32-bit integers
'   Each entry is an <identifier index> for the 'Identifiers' table.
'   &hFFFFFFFF delimits the end of the references data for a function
Dim sym.references%(array.new%(sym.REFERENCES_SIZE_KB% * 1024 \ 8))
Const sym.P_REF_BASE% = Peek(VarAddr sym.references%())
Const sym.P_REF_LIMIT% = sym.P_REF_BASE + sym.REFERENCES_SIZE_KB% * 1024 - 4

' Offset of start of entries for the CURRENT function in the 'References' table.
Dim sym.ref_offset%

Sub sym.init(max_functions%, max_identifiers%, references_size_kb%)
  If max_functions% > 0 Then
    Erase sym.MAX_FUNCTIONS%
    Erase sym.functions$()
    Dim sym.MAX_FUNCTIONS% = max_functions%
    Dim sym.functions$(map2.new%(sym.MAX_FUNCTIONS%)) Length 80
  EndIf

  If max_identifiers% > 0 Then
    Erase sym.MAX_IDS%
    Erase sym.ids$()
    Dim sym.MAX_IDS% = max_identifiers%
    Dim sym.ids$(map2.new%(sym.MAX_IDS%)) Length sym.MAX_ID_LEN% + 8
  EndIf

  If references_size_kb% > 0 Then
    Erase sym.REFERENCES_SIZE_KB%
    Erase sym.references$
    Erase sym.P_REF_BASE%
    Erase sym.P_REF_LIMIT%
    Dim sym.REFERENCES_SIZE_KB% = references_size_kb%
    Dim sym.references%(array.new%(sym.REFERENCES_SIZE_KB% * 1024 \ 8))
    Dim sym.P_REF_BASE% = Peek(VarAddr sym.references%())
    Dim sym.P_REF_LIMIT% = sym.P_REF_BASE% + sym.REFERENCES_SIZE_KB% * 1024 - 4
  EndIf

  map2.init(sym.files$(), sym.MAX_PATH_LEN%)
  map2.init(sym.functions$(), sym.MAX_ID_LEN%)
  map2.init(sym.ids$(), sym.MAX_ID_LEN%)
  ' WARNING! I won't be surprised if this is overrunning.
  Memory Set sym.P_REF_BASE%, &hFF, sym.REFERENCES_SIZE_KB% * 1024
  sym.ref_offset% = 0
End Sub

' Adds a file to the 'Files' table.
'
'  - The same file$ may be aded multiple times,
'    subsequent calls just return the reference to the existing table entry.
'
' @param  file$  the file path.
' @return        sys.FAILURE on error, otherwise
'                'file index' for the new or existing table entry.
Function sym.add_file%(file$)
  If map2.is_full%(sym.files$()) Then
    Local msg$ = "Too many files, max " + Str$(sym.MAX_FILES%)
    sym.add_file% = sys.error%(sys.FAILURE, msg$)
    Exit Function
  EndIf

  If Len(file$) > sym.MAX_PATH_LEN% Then
    Local msg$ = "Path too long, max " + Str$(sym.MAX_PATH_LEN%) + " characters"
    sym.add_file% = sys.error%(sys.FAILURE, msg$)
    Exit Function
  EndIf

  Const sz% = map2.size%(sym.files$())
  sym.add_file% = Val(map2.put_if_absent$(sym.files$(), file$, Str$(sz%)))
End Function

' Adds a function (or subroutine) to the 'Functions' table.
'
'  - Also adds the name$ to the 'Identifiers' table and the file$ to the 'files'
'    table.
'  - Until the next call to add_function%() any calls to
'    add_reference%() will be adding references from this function.
'
' @param  name$  function name including type extension.
' @param  file$  the path to the file containing the function.
' @param  line%  the line on which the function starts in file$.
' @return        sys.FAILURE on error, otherwise
'                'identifier index' for the function.
Function sym.add_function%(name$, file$, line%)
  If map2.is_full%(sym.functions$()) Then
    Local msg$ = "Too many functions/subroutines, max " + Str$(sym.MAX_FUNCTIONS%)
    sym.add_function% = sys.error%(sys.FAILURE, msg$)
    Exit Function
  EndIf

  sym.add_function% = sym.add_identifier%(name$)
  If sym.add_function% < 0 Then Exit Function

  Const file_ref% = sym.add_file%(file$)
  If file_ref% < 0 Then sym.add_function% = file_ref% : Exit Function

  Local v$ = map2.get$(sym.functions$(), LCase$(name$))
  If v$ <> sys.NO_DATA$ Then
    sym.add_function% = sys.error%(sys.FAILURE, "Duplicate function/subroutine")
    Exit Function
  EndIf

  If map2.size%(sym.functions$()) > 0 Then
    Local p%
    For p% = sym.P_REF_BASE% + sym.ref_offset% To sym.P_REF_LIMIT% Step 4
      If Peek(Word p%) = &hFFFFFFFF Then Exit For
      Inc sym.ref_offset%, 4
    Next
    If p% > sym.P_REF_LIMIT% Then
      sym.add_function% = sys.error%(sys.FAILURE, "Too many references")
      Exit Function
    EndIf
    Inc sym.ref_offset%, 4
  EndIf

  v$ = name$ + "," + Str$(file_ref%) + "," + Str$(line%) + ","
  Cat v$, Str$(sym.ref_offset%) + "," + Str$(sym.add_function%)
  map2.put(sym.functions$(), LCase$(name$), v$)
End Function

' Adds an identifier to the 'Identifiers' table.
'
'  - The same id$ may be added multiple times,
'    subsequent calls just return the reference to the existing table entry.
'
' @param  id$  the identifier.
' @return      sys.FAILURE on error, otherwise
'              'identifier index' for the new or existing table entry.
Function sym.add_identifier%(id$)
  If map2.is_full%(sym.ids$()) Then
    Local msg$ = "Too many identifiers, max " + Str$(sym.MAX_IDS%)
    sym.add_identifier% = sys.error%(sys.FAILURE, msg$)
    Exit Function
  EndIf

  If Len(id$) > sym.MAX_ID_LEN% Then
    Local msg$ = "Identifier too long, max " + Str$(sym.MAX_ID_LEN%) + " characters"
    sym.add_identifier% = sys.error%(sys.FAILURE, msg$)
    Exit Function
  EndIf

  Const sz% = map2.size%(sym.ids$())
  sym.add_identifier% = Val(map2.put_if_absent$(sym.ids$(), LCase$(id$), Str$(sz%)))
End Function

' Adds an entry to the 'References' table for the last added function.
'
'  - Also adds the identifier to the 'Identifiers' table.
'  - Adding multiple references to the same identifier is a no-op.
'
' @param  id$  the identifier to add a reference to.
' @return      sys.FAILURE on error, otherwise the 'identifier index'.
Function sym.add_reference%(id$)
  sym.add_reference% = sym.add_identifier%(id$)
  If sym.add_reference% < 0 Then Exit Function

  Local p%
  For p% = sym.P_REF_BASE% + sym.ref_offset% To sym.P_REF_LIMIT% Step 4
    Select Case Peek(Word p%)
      Case &hFFFFFFFF : Exit For
      Case sym.add_reference% : Exit Function ' Already present.
    End Select
  Next

  If p% > sym.P_REF_LIMIT% Then
    sym.add_reference% = sys.error%(sys.FAILURE, "Too many references")
  Else
    Poke Word p%, sym.add_reference%
  EndIf
End Function

' Gets the idx'th reference from a function.
'
' @param  fn_name$  the name of the function.
' @param  idx%      the 0-based index of the reference to get.
' @return           sys.FAILURE on error,
'                   otherwise the 'identifier index' for the reference.
Function sym.get_reference%(fn_name$, idx%)
  Const fn$ = map2.get$(sym.functions$(), LCase$(fn_name$))
  If fn$ = sys.NO_DATA$ Then
    sym.get_reference% = sys.error%(sys.FAILURE, "Function/Subroutine not found")
    Exit Function
  EndIf

  Local p%, i%
  For p% = sym.P_REF_BASE% + Val(Field$(fn$, 4)) To sym.P_REF_LIMIT% Step 4
    sym.get_reference% = Peek(Word p%)
    If sym.get_reference% = &hFFFFFFFF Then Exit For
    If i% = idx% Then Exit Function
    Inc i%
  Next

  sym.get_reference% = sys.error%(sys.FAILURE, "Reference index out of bounds")
End Function

Sub sym.dump_references(start%, num%)
  Local i% = 1, p%
  For p% = sym.P_REF_BASE% + 4 * start% To sym.P_REF_LIMIT% Step 4
    Print "[" Str$(start% + i% - 1) "] " Hex$(Peek(Word p%))
    If i% = num% Then Exit For
    Inc i%
  Next
End Sub