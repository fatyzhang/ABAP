Method for update move-in date in move-in doc and contract.
ISU_S_MOVE_IN_DATE_CHANGE

METHOD update_move_in.
* Update Actual Move in Date

  DATA: lt_eeinv TYPE TABLE OF eeinv,
        ls_eeinv TYPE eeinv,
        lt_contract    TYPE isu06_mi_t_vertrag,
        ls_contract    TYPE isu06_mi_vertrag.
  DATA: lv_newactmoveindate TYPE bezugsdat,
        lv_vstelle          TYPE vstelle,
        ls_v_eanl TYPE v_eanl,
        lv_moveindoc        TYPE eeinv-einzbeleg,
        ls_changed          TYPE isu06_mi_changed.
  DATA: lv_mtext TYPE string.

* new move-in date
  lv_newactmoveindate = is_pp_master-start_date.

* find move-in doc

  CALL FUNCTION 'ISU_DB_EANL_SELECT'
    EXPORTING
      x_anlage     = is_pp_master-anlage
    IMPORTING
      y_v_eanl     = ls_v_eanl
    EXCEPTIONS
      not_found    = 1
      system_error = 2
      invalid_date = 3.

  lv_vstelle = ls_v_eanl-vstelle. " Premise
*
  CALL FUNCTION 'ISU_FIND_MOVEINDOC'
    EXPORTING
      x_partner   = is_pp_master-partner
      x_vstelle   = lv_vstelle
      x_vertrag   = is_pp_master-vertrag
    IMPORTING
      y_einzbeleg = lv_moveindoc
    EXCEPTIONS
      OTHERS      = 0.

  IF sy-subrc <> 0.
    " raise exception
    MESSAGE e005(zmovein) INTO lv_mtext.        " move-in doc is not found, update failed.
    cr_proc_log->add_process_log( ).
    zcx_prepayment_error=>raise_exception_from_msg( ).
  ENDIF.

  CLEAR lt_eeinv.
  ls_eeinv-einzbeleg = lv_moveindoc.
  APPEND ls_eeinv TO lt_eeinv.

  CALL FUNCTION 'ISU_DB_EEINV_SELECT'
    EXPORTING
      x_actual         = space
      x_cancelled_also = 'X'
    TABLES
      t_eeinv          = lt_eeinv
    EXCEPTIONS
      not_found        = 1
      not_qualified    = 2
      OTHERS           = 3.
  IF sy-subrc NE 0.
      " raise exception
    cr_proc_log->add_process_log( ).   " add FM return message
    MESSAGE e005(zmovein) INTO lv_mtext.        " move-in doc is not found, update failed.
    cr_proc_log->add_process_log( ).
    zcx_prepayment_error=>raise_exception_from_msg( ).
  ENDIF.

  LOOP AT lt_eeinv INTO ls_eeinv.
    CLEAR ls_contract .
    MOVE-CORRESPONDING ls_eeinv TO ls_contract.
    ls_contract-einzdat = lv_newactmoveindate.

    APPEND ls_contract TO lt_contract.
  ENDLOOP.

  CALL FUNCTION 'ISU_S_MOVE_IN_DATE_CHANGE'
    EXPORTING
      x_einzbeleg            = lv_moveindoc
      x_bezugsdat            = lv_newactmoveindate
    IMPORTING
      y_changed              = ls_changed
    TABLES
      tx_vertrag             = lt_contract
    EXCEPTIONS
      not_found              = 1
      foreign_lock           = 2
      internal_error         = 3
      input_error            = 4
      action_failed          = 5
      not_authorized         = 6
      dont_delete_bbp        = 7
      reverse_docs_necessary = 8
      internal_crm_error     = 9
      OTHERS                 = 10.
  IF sy-subrc <> 0.
     cr_proc_log->add_process_log( ).
     MESSAGE e006(zmovein) into lv_mtext.
     cr_proc_log->add_process_log( ).
     zcx_prepayment_error=>raise_exception_from_msg( ).
  ELSE.
    COMMIT WORK.
  ENDIF.

ENDMETHOD.