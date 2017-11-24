*&---------------------------------------------------------------------*
*& Report  ZTEST_CODE6
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT ZTEST_CODE6.

TABLES sscrfields.

DATA: excel TYPE ole2_object,
      word  TYPE ole2_object,
      book  TYPE ole2_object,
      rc    TYPE c LENGTH 8.

SELECTION-SCREEN:
  BEGIN OF SCREEN 100 AS WINDOW TITLE title,
    BEGIN OF LINE,
      PUSHBUTTON  2(12) button_1
                  USER-COMMAND word_start,
      PUSHBUTTON  20(12) button_2
                  USER-COMMAND excel_start,
    END OF LINE,
    BEGIN OF LINE,
      PUSHBUTTON  2(12) button_3
                  USER-COMMAND word_stop,
      PUSHBUTTON  20(12) button_4
                  USER-COMMAND excel_stop,
    END OF LINE,
  END OF SCREEN 100.

START-OF-SELECTION.
  button_1 = 'Start Word'.
  button_2 = 'Start Excel'.
  button_3 = 'Stop  Word'.
  button_4 = 'Stop  Excel'.
  CALL SELECTION-SCREEN 100 STARTING AT 10 10.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'WORD_START'.
      CHECK word-handle <> -1.
      CHECK word-header = space.
      CREATE OBJECT   word  'Word.Basic'.
      CALL METHOD  OF word  'AppShow'.
    WHEN 'EXCEL_START'.
      CHECK excel-handle = 0.
      CHECK excel-header = space.
      CREATE OBJECT   excel 'Excel.Application'.
      SET PROPERTY OF excel 'Visible' = 1.
      GET PROPERTY OF excel 'Workbooks' = book.
      CALL METHOD  OF book  'Open' = rc
        EXPORTING #1 = 'C:\temp\Table.xls'.
    WHEN 'WORD_STOP'.
      CALL METHOD OF word 'AppClose'.
      FREE OBJECT word.
      CLEAR: word-handle, word-header.
    WHEN 'EXCEL_STOP'.
      CALL METHOD OF  excel 'Quit'.
      FREE OBJECT excel.
      CLEAR: excel-handle, excel-header.
    WHEN OTHERS.
      LEAVE PROGRAM.
  ENDCASE.