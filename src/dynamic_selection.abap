*&---------------------------------------------------------------------*
*& Report  ZTEST_SELECTION
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT ztest_selection.

PARAMETERS dbtab TYPE tabname DEFAULT 'XXXXXX'.
DATA selid         TYPE  rsdynsel-selid.
DATA field_tab     TYPE TABLE OF rsdsfields.
DATA table_tab     TYPE TABLE OF rsdstabs.
DATA table         LIKE LINE OF table_tab.
DATA cond_tab      TYPE rsds_twhere.
DATA dref          TYPE REF TO data.
DATA alv           TYPE REF TO cl_salv_table.
FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
FIELD-SYMBOLS <cond>  LIKE LINE OF cond_tab.

DATA checked_dbtab TYPE tabname.

TRY.
    checked_dbtab = cl_abap_dyn_prg=>check_table_name_str(
                    val = dbtab
                    packages = 'XXXXXXX' ).
  CATCH cx_abap_not_a_table.
    MESSAGE 'Database table not found' TYPE 'I' DISPLAY LIKE 'E'.
    LEAVE PROGRAM.
  CATCH cx_abap_not_in_package.
    MESSAGE 'only table under packag XXX is allowed'
             TYPE 'I' DISPLAY LIKE 'E'.
    LEAVE PROGRAM.
ENDTRY.



table-prim_tab = dbtab.
APPEND table TO table_tab.

CALL FUNCTION 'FREE_SELECTIONS_INIT'
  EXPORTING
    kind         = 'T'
  IMPORTING
    selection_id = selid
  TABLES
    tables_tab   = table_tab
  EXCEPTIONS
    OTHERS       = 4.
IF sy-subrc <> 0.
  MESSAGE 'Error in initialization' TYPE 'I' DISPLAY LIKE 'E'.
  LEAVE PROGRAM.
ENDIF.


CALL FUNCTION 'FREE_SELECTIONS_DIALOG'
  EXPORTING
    selection_id  = selid
    title         = 'Free Selection'
    as_window     = ' '
  IMPORTING
    where_clauses = cond_tab
  TABLES
    fields_tab    = field_tab
  EXCEPTIONS
    OTHERS        = 4.
IF sy-subrc <> 0.
  MESSAGE 'No free selection created' TYPE 'I'.
  LEAVE PROGRAM.
ENDIF.

READ TABLE cond_tab WITH KEY tablename = dbtab ASSIGNING <cond>.
IF sy-subrc <> 0.
  MESSAGE 'Error in condition' TYPE 'I' DISPLAY LIKE 'E'.
  LEAVE PROGRAM.
ENDIF.


CREATE DATA dref TYPE TABLE OF (checked_dbtab).
ASSIGN dref->* TO <table>.

TRY.
    SELECT *
           FROM (checked_dbtab)
           INTO TABLE <table>
           WHERE (<cond>-where_tab).
  CATCH cx_sy_dynamic_osql_error.
    MESSAGE 'Error in dynamic Open SQL' TYPE 'I' DISPLAY LIKE 'E'.
    LEAVE PROGRAM.
ENDTRY.

TRY.
    cl_salv_table=>factory(
      IMPORTING r_salv_table = alv
      CHANGING  t_table      = <table> ).
    alv->display( ).
  CATCH cx_salv_msg.
    MESSAGE 'Error in ALV display' TYPE 'I' DISPLAY LIKE 'E'.
ENDTRY.