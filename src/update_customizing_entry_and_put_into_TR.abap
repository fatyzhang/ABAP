* sample codes to update a table field value (in this example it is key field)
* and import to an transport request.

REPORT zchange_source.

DATA: g_tabname TYPE dd02l-tabname.
SELECTION-SCREEN BEGIN OF BLOCK tab WITH FRAME TITLE text-001.
SELECT-OPTIONS: s_tname FOR g_tabname NO INTERVALS.
PARAMETERS p_reques TYPE e071-trkorr OBLIGATORY.
SELECTION-SCREEN END OF BLOCK tab.

TYPES: BEGIN OF st_tabname,
         tabname TYPE dd02l-tabname,
         status  TYPE string,
       END OF st_tabname.

DATA: ls_tname   TYPE rsdsselopt,
      gt_tabname TYPE STANDARD TABLE OF st_tabname.

DATA: ls_e070      TYPE e070,
      ls_e07t      TYPE e07t,
      lt_e071      TYPE STANDARD TABLE OF e071,
      lt_e071_tmp  TYPE STANDARD TABLE OF e071,
      ls_e071      TYPE e071,
      lt_e071k     TYPE STANDARD TABLE OF e071k,
      lt_e071k_tmp TYPE STANDARD TABLE OF e071k,
      ls_e071k     TYPE e071k,
      lv_as4pos    TYPE ddposition,
      lv_as4pos2   TYPE ddposition,
      lv_flag      TYPE char1.

DATA: lv_statement TYPE string,
      lv_err       TYPE string.

DATA: lv_dyn_tab    TYPE REF TO data,
      lv_name       TYPE string,
      lo_type_descr TYPE REF TO cl_abap_typedescr,
      lo_tab_descr  TYPE REF TO cl_abap_tabledescr,
      lt_keys       TYPE STANDARD TABLE OF cacs_s_cond_keyfields,
      ls_key        TYPE cacs_s_cond_keyfields.
FIELD-SYMBOLS: <fs_data> TYPE ANY TABLE.


START-OF-SELECTION.
*Read table information
  SELECT tabname FROM dd02l INTO TABLE gt_tabname WHERE tabname IN s_tname.

*Read TR information
  CALL FUNCTION 'TR_READ_COMM'
    EXPORTING
      wi_trkorr        = p_reques
      wi_dialog        = ' '
      wi_sel_e070      = 'X'
      wi_sel_e07t      = 'X'
      wi_sel_e071      = 'X'
      wi_sel_e071k     = 'X'
    IMPORTING
      we_e070          = ls_e070
      we_e07t          = ls_e07t
    TABLES
      wt_e071          = lt_e071
      wt_e071k         = lt_e071k
    EXCEPTIONS
      not_exist_e070   = 1
      no_authorization = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
    MESSAGE 'The TR does not exist' TYPE 'E'.
  ENDIF.

  SORT lt_e071 BY as4pos.
  READ TABLE lt_e071 INTO ls_e071 INDEX lines( lt_e071 ).
  lv_as4pos = ls_e071-as4pos. "get the next postion

  REFRESH lt_e071.
  REFRESH lt_e071k.

  LOOP AT gt_tabname ASSIGNING FIELD-SYMBOL(<fs_tabname>).
    REFRESH lt_e071_tmp.
    REFRESH lt_e071k_tmp.
*Select the data
    CREATE DATA lv_dyn_tab TYPE STANDARD TABLE OF (<fs_tabname>-tabname) .
    ASSIGN lv_dyn_tab->* TO <fs_data>.

    SELECT * FROM (<fs_tabname>-tabname) INTO TABLE @<fs_data> WHERE source = 'C'.
    IF <fs_data> IS INITIAL.
      CONTINUE.
    ENDIF.

    lv_as4pos = lv_as4pos + 1.
    ls_e071-trkorr = p_reques.
    ls_e071-as4pos = lv_as4pos.
    ls_e071-pgmid = 'R3TR'.
    ls_e071-object = 'TABU'.
    ls_e071-obj_name = <fs_tabname>-tabname.
    ls_e071-objfunc = 'K'.
    APPEND ls_e071 TO lt_e071_tmp.

    CALL FUNCTION 'CACS_GET_TABLE_FIELDS'
      EXPORTING
        i_tabname  = <fs_tabname>-tabname
      TABLES
        t_keyfield = lt_keys
*       T_NONKEYFIELD       =
      .

    ls_e071k-trkorr = p_reques.
*        ls_e071k-as4pos = 1.
    ls_e071k-pgmid = 'R3TR'.
    ls_e071k-object = 'TABU'.
    ls_e071k-objname = <fs_tabname>-tabname.
    ls_e071k-mastertype = 'TABU'.
    ls_e071k-mastername = <fs_tabname>-tabname.
*construct the key
    lv_as4pos2 = 0.
    LOOP AT <fs_data> ASSIGNING FIELD-SYMBOL(<fs_line>).
      LOOP AT lt_keys INTO ls_key.
        ASSIGN COMPONENT ls_key-fieldname OF STRUCTURE <fs_line> TO FIELD-SYMBOL(<fs_key>).
        CONCATENATE ls_e071k-tabkey <fs_key> INTO ls_e071k-tabkey.
      ENDLOOP.
      lv_as4pos2 = lv_as4pos2 + 1.
      ls_e071k-as4pos = lv_as4pos2.
      APPEND ls_e071k TO lt_e071k_tmp.
      CLEAR ls_e071k-tabkey.

    ENDLOOP.

    lv_statement = |update { <fs_tabname>-tabname } set source = 'S' where source = 'C'|.
    TRY.
        NEW cl_sql_statement( )->execute_update( lv_statement ).

        APPEND LINES OF lt_e071_tmp TO lt_e071.
        APPEND LINES OF lt_e071k_tmp TO lt_e071k.
        <fs_tabname>-status = 'Sucess'.
      CATCH cx_sql_exception.
        <fs_tabname>-status = 'Failed'.
      CATCH cx_parameter_invalid.
        <fs_tabname>-status = 'Failed'.
    ENDTRY.
  ENDLOOP.


  IF lt_e071 IS NOT INITIAL AND lt_e071k IS NOT INITIAL.
    CALL FUNCTION 'TRINT_APPEND_COMM'
      EXPORTING
        wi_exclusive       = 'X'
        wi_sel_e071        = 'X'
        wi_sel_e071k       = 'X'
        wi_trkorr          = p_reques
*       IT_E071K_STR       =
*     IMPORTING
*       WE_KEYS_PHYSICAL_APPENDED          =
*       WE_OBJECTS_PHYSICAL_APPENDED       =
      TABLES
        wt_e071            = lt_e071
        wt_e071k           = lt_e071k
      EXCEPTIONS
        e071k_append_error = 1
        e071_append_error  = 2
        trkorr_empty       = 3
        OTHERS             = 4.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
    ELSE.
      COMMIT WORK.
    ENDIF.

  ENDIF.

  PERFORM display_result.
*&---------------------------------------------------------------------*
*& Form DISPLAY_RESULT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_result .
  DATA lt_fcat TYPE TABLE OF slis_fieldcat_alv.
  DATA ls_fcat TYPE slis_fieldcat_alv.

  ls_fcat-fieldname = 'TABNAME'.
  ls_fcat-tabname = 'GT_TABNAME'.
  ls_fcat-seltext_l = 'Table Name'.

  APPEND ls_fcat TO lt_fcat.

  CLEAR ls_fcat.

  ls_fcat-fieldname = 'STATUS'.
  ls_fcat-tabname = 'GT_TABNAME'.
  ls_fcat-seltext_l = 'Update Status'.

  APPEND ls_fcat TO lt_fcat.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     i_callback_program = sy-repid
      it_fieldcat   = lt_fcat
*     IT_EVENTS     = lt_event
*     I_callback_user_command = 'ON_CLICK'
    TABLES
      t_outtab      = gt_tabname
    EXCEPTIONS
      program_error = 1
      OTHERS        = 2.
  .
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM.