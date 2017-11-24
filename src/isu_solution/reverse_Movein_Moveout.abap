 Rollback move_in and move_out.
    
    DATA: "lv_vertrag          TYPE vertrag,
          lv_e_update         TYPE e_update,
          ls_eausv            TYPE eausv,
          ls_eeinv            TYPE eeinv,
          lv_string           TYPE string,
          ls_process_step_key TYPE /idxpf/s_proc_step_key,
          ls_ever             TYPE ever.

    MOVE-CORRESPONDING cs_process_step_data TO ls_process_step_key.

    IF cs_process_step_data-contract IS INITIAL."has to be there -> Error
* error message
      MESSAGE ID zaidx_if_constants=>gc_mc_proc
        TYPE zaidx_if_constants=>gc_mt_error
        NUMBER 065
        WITH cs_process_step_data-proc_ref
        INTO lv_string.
* message to PDoc
      IF cr_process_log IS BOUND.
        CALL METHOD cr_process_log->add_message_to_process_log
          EXPORTING
            is_process_step_key = ls_process_step_key.
      ENDIF.
*exception
      CALL METHOD /acidx/cx_utility_error=>raise_util_exception.
    ENDIF.

    SELECT SINGLE * FROM ever INTO ls_ever
      WHERE vertrag EQ cs_process_step_data-contract.


* 1. ROLLBACK of MOVE_OUT
    IF NOT ls_ever-auszdat IS INITIAL or ls_ever-auszdat = '99991231'.

      SELECT SINGLE * FROM eausv INTO ls_eausv
        WHERE vertrag EQ ls_ever-vertrag
        AND storausz EQ space.
      if sy-subrc = 0.
        CALL FUNCTION 'ISU_S_MOVE_OUT_CANCEL'
          EXPORTING
            x_auszbeleg       = ls_eausv-auszbeleg
            x_upd_online      = 'X'
            x_no_dialog       = 'X'
            x_suppress_dialog = 'X'
          IMPORTING
            y_db_update       = lv_e_update
          EXCEPTIONS
            not_found         = 1
            foreign_lock      = 2
            cancelled         = 3
            general_fault     = 4
            input_error       = 5
            action_failed     = 6
            not_authorized    = 7
            param_error       = 8
            billed            = 9
            dpp               = 10
            OTHERS            = 11.

        IF sy-subrc EQ 0
          AND lv_e_update EQ 'X'.
*   success message
          MESSAGE ID zaidx_if_constants=>gc_mc_proc
            TYPE zaidx_if_constants=>gc_mt_success
            NUMBER 064
            WITH ls_eausv-auszbeleg cs_process_step_data-contract
            INTO lv_string.
*   message to PDoc
          IF cr_process_log IS BOUND.
            CALL METHOD cr_process_log->add_message_to_process_log
              EXPORTING
                is_process_step_key = ls_process_step_key.
          ENDIF.
        ELSE.
*   system message to PDoc
          IF cr_process_log IS BOUND.
            CALL METHOD cr_process_log->add_message_to_process_log
              EXPORTING
                is_process_step_key = ls_process_step_key.
          ENDIF.
*  exception
          CALL METHOD /acidx/cx_utility_error=>raise_util_exception.
        ENDIF.
     endif.
   endif.


* 2. Rollback of MOVE-IN
   IF NOT ls_ever-einzdat IS INITIAL.
      SELECT SINGLE * FROM eeinv INTO ls_eeinv
        WHERE vertrag EQ ls_ever-vertrag.
      if sy-subrc = 0.
        CALL FUNCTION 'ISU_S_MOVE_IN_CANCEL'
          EXPORTING
            x_einzbeleg            = ls_eeinv-einzbeleg
            x_no_dialog            = 'X'
            x_suppress_dialog      = 'X'
          IMPORTING
            y_db_update            = lv_e_update
          EXCEPTIONS
            not_found              = 1
            foreign_lock           = 2
            number_error           = 3
            input_error            = 4
            action_failed          = 5
            not_authorized         = 6
            internal_error         = 7
            invalid_key            = 8
            metdoctab_inconsistent = 9
            reverse_docs_necessary = 10
            dont_delete_bbp        = 11
            clear_docs_necessary   = 12
            dpp                    = 13
            OTHERS                 = 14.

        IF sy-subrc EQ 0
          AND lv_e_update EQ 'X'.
*   success message
          MESSAGE ID zaidx_if_constants=>gc_mc_proc
            TYPE zaidx_if_constants=>gc_mt_success
            NUMBER 063
            WITH ls_eeinv-einzbeleg cs_process_step_data-contract
            INTO lv_string.
*   message to PDoc
          IF cr_process_log IS BOUND.
            CALL METHOD cr_process_log->add_message_to_process_log
              EXPORTING
                is_process_step_key = ls_process_step_key.
          ENDIF.
        ELSE.
*   system message to PDoc
          IF cr_process_log IS BOUND.
            CALL METHOD cr_process_log->add_message_to_process_log
              EXPORTING
                is_process_step_key = ls_process_step_key.
          ENDIF.
*  exception
          CALL METHOD /acidx/cx_utility_error=>raise_util_exception.
        ENDIF.
      endif.
    ENDIF.