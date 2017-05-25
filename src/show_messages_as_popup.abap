METHOD show_message_popup.
  " IT_MESSAGES TYPE BAPIRET2_T

  DATA:  lo_msg_list TYPE REF TO if_reca_message_list.
  DATA:  ls_log_disp_prof TYPE bal_s_prof,
         lv_handle   TYPE balloghndl.

  IF it_messages IS INITIAL.
     RETURN.
  ENDIF.
*

  lo_msg_list = cf_reca_message_list=>create( ).

  lo_msg_list->add_from_bapi( it_bapiret = it_messages ).

  CALL FUNCTION 'BAL_DSP_PROFILE_POPUP_GET'
*   EXPORTING
*     START_COL                 = 5
*     START_ROW                 = 5
*     END_COL                   = 87
*     END_ROW                   = 25
   IMPORTING
     e_s_display_profile       = ls_log_disp_prof
            .

  lv_handle = lo_msg_list->get_handle( ).
  ls_log_disp_prof-use_grid   = abap_true.
  ls_log_disp_prof-disvariant-handle = lv_handle.
  ls_log_disp_prof-disvariant-report = sy-repid.

  CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
   EXPORTING
     i_s_display_profile          = ls_log_disp_prof
*     I_T_LOG_HANDLE               =
*     I_T_MSG_HANDLE               =
*     I_S_LOG_FILTER               =
*     I_S_MSG_FILTER               =
*     I_T_LOG_CONTEXT_FILTER       =
*     I_T_MSG_CONTEXT_FILTER       =
*     I_AMODAL                     = ' '
*     I_SRT_BY_TIMSTMP             = ' '
*   IMPORTING
*     E_S_EXIT_COMMAND             =
   EXCEPTIONS
     profile_inconsistent         = 1
     internal_error               = 2
     no_data_available            = 3
     no_authority                 = 4
     OTHERS                       = 5
            .
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDMETHOD.


By FM: 

  CALL FUNCTION 'FINB_BAPIRET2_DISPLAY'
    EXPORTING
      it_message = it_messages.

or: 

CALL FUNCTION 'MESSAGES_INITIALIZE'.
  CLEAR :L_R_RETURN,P_G_F_ERROR.
  LOOP AT P_G_T_RETURN  INTO L_R_RETURN .
    CALL FUNCTION 'MESSAGE_STORE'
      EXPORTING
        ARBGB = L_R_RETURN-ID
        MSGTY = L_R_RETURN-TYPE
        TXTNR = L_R_RETURN-NUMBER
        MSGV1 = L_R_RETURN-MESSAGE_V1
        MSGV2 = L_R_RETURN-MESSAGE_V2
        MSGV3 = L_R_RETURN-MESSAGE_V3
        MSGV4 = L_R_RETURN-MESSAGE_V4
        ZEILE = L_R_RETURN-ROW.
  ENDLOOP.
  IF P_G_F_ERROR EQ G_C_X.
    CALL FUNCTION 'MESSAGES_SHOW'.
  ENDIF.
  CALL FUNCTION 'MESSAGES_INITIALIZE'.