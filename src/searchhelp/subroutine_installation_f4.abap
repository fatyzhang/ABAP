*----------------------------------------------------------------------*
***INCLUDE /ACIDX/LPROC_MALFUNCTIONF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  INSTAL_SET_F4
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM instal_set_f4 .

DATA: lv_stepl      TYPE systepl,
      ls_shlp       TYPE shlp_descr,
      ls_inter      TYPE ddshiface,
      ls_dynp       TYPE   dynpread,
      lt_dynp       TYPE TABLE OF dynpread,
*      lt_dynp1     TYPE TABLE OF dynpread,
      ls_return     TYPE  ddshretval,
      lt_return     TYPE TABLE OF ddshretval.

CALL FUNCTION 'F4IF_GET_SHLP_DESCR'
  EXPORTING
    shlpname  = 'EANLB'
    shlptype  = 'SH'
  IMPORTING
    shlp      = ls_shlp.

  ls_dynp-fieldname  =  'GS_MALF-INSTAL'.
  APPEND ls_dynp TO lt_dynp.
  ls_dynp-fieldname  =  'GS_MALF-EXT_UI'.
  APPEND ls_dynp TO lt_dynp.

CALL FUNCTION 'DYNP_VALUES_READ'
  EXPORTING
    dyname                               = sy-repid
    dynumb                               = sy-dynnr
  TABLES
    dynpfields                           = lt_dynp
 EXCEPTIONS
   INVALID_ABAPWORKAREA                 = 1
   INVALID_DYNPROFIELD                  = 2
   INVALID_DYNPRONAME                   = 3
   INVALID_DYNPRONUMMER                 = 4
   INVALID_REQUEST                      = 5
   NO_FIELDDESCRIPTION                  = 6
   INVALID_PARAMETER                    = 7
   UNDEFIND_ERROR                       = 8
   DOUBLE_CONVERSION                    = 9
   STEPL_NOT_FOUND                      = 10
   OTHERS                               = 11  .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*  READ TABLE lt_dynp INTO ls_dynp WITH KEY fieldname  =  'GS_MALF-EXT_UI'.
  LOOP AT ls_shlp-interface INTO ls_inter.
    IF ls_inter-shlpfield = 'POINTOFDELIVERY' .
      ls_inter-valfield = 'X'.
      READ TABLE lt_dynp INTO ls_dynp WITH KEY fieldname  =  'GS_MALF-EXT_UI'.
      ls_inter-value = ls_dynp-fieldvalue.
      MODIFY ls_shlp-interface FROM ls_inter.
    ELSEIF ls_inter-shlpfield = 'INSTALLATION'."
      ls_inter-valfield = 'X'.
*      ls_inter-f4field = 'X'.
      READ TABLE lt_dynp INTO ls_dynp WITH KEY fieldname  =  'GS_MALF-INSTAL'.
      ls_inter-value = ls_dynp-fieldvalue.
      MODIFY ls_shlp-interface FROM ls_inter.
    ENDIF.
  ENDLOOP.

CALL FUNCTION 'F4IF_START_VALUE_REQUEST'
  EXPORTING
    shlp           = ls_shlp
    maxrecords     = 100
  TABLES
    return_values  = lt_return.
  CHECK lt_return IS NOT INITIAL.

  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl        = lv_stepl
    EXCEPTIONS
      stepl_not_found = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  CLEAR:   ls_dynp, lt_dynp.
  ls_dynp-fieldname  =  'GS_MALF-INSTAL'.
  READ TABLE lt_return INTO ls_return WITH KEY fieldname = 'INSTALLATION'.
  ls_dynp-fieldvalue = ls_return-fieldval.
  gs_malf-instal = ls_return-fieldval.
  ls_dynp-stepl      = lv_stepl.
  APPEND ls_dynp TO lt_dynp.
  ls_dynp-fieldname  =  'GS_MALF-EXT_UI'.
  PERFORM set_pod_by_instal .
  ls_dynp-fieldvalue = gs_malf-ext_ui.
  ls_dynp-stepl      = lv_stepl.
  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid    "Program name
      dynumb     = sy-dynnr    "Screen number
    TABLES
      dynpfields = lt_dynp
    EXCEPTIONS
     invalid_abapworkarea       = 1
     invalid_dynprofield        = 2
     invalid_dynproname         = 3
     invalid_dynpronummer       = 4
     invalid_request            = 5
     no_fielddescription        = 6
     undefind_error             = 7
     OTHERS                     = 8 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
ENDFORM.