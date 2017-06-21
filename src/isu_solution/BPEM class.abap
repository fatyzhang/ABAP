BPEM class 
CREATE_EXCEPTION
CLOSE_EXCEPTION
GET_EMMA_MAIN_OBJECT
GET_EMMA_CCAT_DETAILS
GET_OBJECT_KEY
GET_EMMA_SUB_OBJECTS
GET_EMMA_MESSAGES
METHOD /oneepp/if_badi_exception~create_exception.

*--------------------------------------------------------------------*
* Default implementation for Execption creation
*--------------------------------------------------------------------*

  DATA:
    lv_ccat TYPE emma_ccat ,
*    ls_acttyp TYPE /oneepp/acttyp,
    lv_error_ind TYPE flag,
    ls_update_input	TYPE /oneepp/s_update_input,

     ls_read_data   TYPE  /oneepp/s_search_input,
         ls_read_result TYPE  /oneepp/s_read_result,
         lv_read_type   TYPE /oneepp/de_readtype,



    ls_case_create             TYPE bapi_emma_case_create,
    lt_emma_msg                TYPE emma_msg_link_tab,
    lt_object                  TYPE emma_cobj_t,
    lt_return                  TYPE bapirettab,
    lt_return2                 TYPE bapirettab.

  FIELD-SYMBOLS:
   <fs_return>                TYPE bapiret2.

*--------------------------------------------------------------------*
* check input
*--------------------------------------------------------------------*
*  IF is_event IS INITIAL AND iv_ccat IS INITIAL .
*    MESSAGE e250(/oneepp/prepayment) INTO gv_mtext.
*    CALL METHOD /oneepp/cx_prepayment_error=>raise_exception_from_msg( ).
*  ENDIF.

*--------------------------------------------------------------------*
* determine BPEM case category
*--------------------------------------------------------------------*
  lv_ccat = iv_ccat.
  ls_update_input = is_update_input.

*--------------------------------------------------------------------*
* read PP Data Container
*--------------------------------------------------------------------*
  IF ls_update_input-pp_all_data-pp_master IS INITIAL.
    ls_read_data-ppoid = iv_ppoid.

    CALL METHOD /oneepp/cl_pp_api=>call_read_api
      EXPORTING
        iv_read_type   = /oneepp/if_constants=>gc_readtype_max
        is_read_data   = ls_read_data
      IMPORTING
        es_read_result = ls_read_result.

    ls_update_input-pp_all_data-pp_master = ls_read_result-pp_master.
  ENDIF.

*--------------------------------------------------------------------*
* Prepare Data for BPEM
*--------------------------------------------------------------------*

  ls_case_create-orig_date  = sy-datum.
  ls_case_create-orig_time  = sy-uzeit.
  ls_case_create-ccat = lv_ccat.

* Get EMMA Case Main Object
  me->get_emma_main_object(
   EXPORTING
     iv_ccat     = lv_ccat
     is_update_input = ls_update_input
   CHANGING
     cs_case_create        = ls_case_create ).

* Get EMMA Case Objects
  me->get_emma_sub_objects(
   EXPORTING
     iv_ccat        = lv_ccat
     is_update_input       = ls_update_input
     is_case_create        = ls_case_create
   CHANGING
     ct_objects            = lt_object ).

* Get EMMA Case messages
  me->get_emma_messages(
   EXPORTING
     iv_ccat        = lv_ccat
     is_update_input       = ls_update_input
     is_case_create        = ls_case_create
   CHANGING
     ct_emma_msg           = lt_emma_msg ).

*--------------------------------------------------------------------*
*   Create BPEM Case
*--------------------------------------------------------------------*

  CALL FUNCTION 'BAPI_EMMA_CASE_CREATE'
    EXPORTING
      case_create = ls_case_create
      forward     = abap_true
    IMPORTING
      case        = ev_bpemnr
    TABLES
      objects     = lt_object
      messages    = lt_emma_msg
      return      = lt_return.



*--------------------------------------------------------------------*
* Check if BPEM case has been created
*--------------------------------------------------------------------*

  LOOP AT lt_return ASSIGNING <fs_return>.
    IF <fs_return>-type = /oneepp/if_constants=>gc_msgtype_error   OR
       <fs_return>-type = /oneepp/if_constants=>gc_msgtype_exit    OR
       <fs_return>-type = /oneepp/if_constants=>gc_msgtype_abort  .


      MESSAGE ID <fs_return>-id TYPE <fs_return>-type NUMBER <fs_return>-number INTO <fs_return>-message
        WITH <fs_return>-message_v1
             <fs_return>-message_v2
             <fs_return>-message_v3
             <fs_return>-message_v4.
      lv_error_ind = abap_true.
      IF cr_data_log IS BOUND.
        CALL METHOD cr_data_log->add_process_log(
          EXPORTING
            iv_action_status = 'ERROR' ).
      ENDIF.

    ENDIF.
  ENDLOOP.

  IF lv_error_ind = abap_true.
    CALL METHOD /oneepp/cx_prepayment_error=>raise_exception_from_msg( ).
  ENDIF.

ENDMETHOD.

METHOD /oneepp/if_badi_exception~close_exception.
*--------------------------------------------------------------------*

  DATA:
   lr_previous   TYPE REF TO cx_root.


  TRY.
      CALL FUNCTION 'BAPI_EMMA_CASE_COMPLETE'
        EXPORTING
          case = iv_bpemnr.

    CATCH cx_root INTO lr_previous.                      "#EC CATCH_ALL
      MESSAGE e219(emma) WITH iv_bpemnr INTO gv_mtext.
      IF cr_data_log IS BOUND.
        cr_data_log->add_process_log(
        EXPORTING
          iv_action_status = 'ERROR' ).
      ENDIF.
      /oneepp/cx_prepayment_error=>raise_exception_from_msg( ).
  ENDTRY.



ENDMETHOD.

method CLASS_CONSTRUCTOR.
   gr_emma_dbl = cl_emma_dbl=>create_dblayer( ).
endmethod.

method GET_EMMA_MAIN_OBJECT.

  DATA:
   ls_case_cat_details TYPE emma_ccat_complete.

*--------------------------------------------------------------------*
  IF cs_case_create-mainobjtype IS INITIAL.
    me->get_emma_ccat_details(
      EXPORTING
        iv_ccat = IV_CCAT
      IMPORTING
        es_emma_ccat_details = ls_case_cat_details  ).

    gr_emma_dbl->read_bpcode(
    EXPORTING
      iv_bpcode  = ls_case_cat_details-bpcode
    IMPORTING
*     ev_bparea  = lv_bparea
      ev_objtype = cs_case_create-mainobjtype
    EXCEPTIONS
      not_found  = 1
      OTHERS     = 2 ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno INTO gv_mtext
         WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      CALL METHOD /ONEEPP/CX_PREPAYMENT_ERROR=>RAISE_EXCEPTION_FROM_MSG( ).
    ENDIF.
  ENDIF.

* Get Object Key
  cs_case_create-mainobjkey = me->get_object_key(
                                    iv_object_type        = cs_case_create-mainobjtype
                                    IS_UPDATE_INPUT = IS_UPDATE_INPUT ).


endmethod.

method GET_EMMA_CCAT_DETAILS.

  READ TABLE gt_emma_details INTO es_emma_ccat_details
   WITH KEY ccat = iv_ccat.

  IF sy-subrc <> 0.
    gr_emma_dbl->readc_ccat_complete(
      EXPORTING
        iv_ccat         = iv_ccat
*       iv_bpcode       = iv_bpcode
*       iv_get_inactive = ''
        iv_get_manual   = abap_true
*       iv_get_sop      = ' '
*       iv_get_text     = ' '
      IMPORTING
*       et_ccat         = et_ccat
        es_ccat         = es_emma_ccat_details
      EXCEPTIONS
        not_found       = 1
        input_error     = 2
        OTHERS          = 3  ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno INTO gv_mtext
         WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
     call METHOD /ONEEPP/CX_PREPAYMENT_ERROR=>RAISE_EXCEPTION_FROM_MSG( ).
    ENDIF.

    INSERT es_emma_ccat_details INTO TABLE gt_emma_details.
  ENDIF.
endmethod.

METHOD get_object_key.



*--------------------------------------------------------------------*
  CASE iv_object_type.
    WHEN /oneepp/if_constants=>gc_object_pp_bor   .  " PP Object
*
      rv_object_key = is_update_input-ppoid .

    WHEN /oneepp/if_constants=>gc_object_bp_bor . " Business partner
      rv_object_key = is_update_input-pp_all_data-pp_master-partner.

    WHEN /oneepp/if_constants=>gc_object_in_bor . "'Installation
      rv_object_key = is_update_input-pp_all_data-pp_master-anlage.

    WHEN /oneepp/if_constants=>gc_object_ct_bor . "'contract
      rv_object_key = is_update_input-pp_all_data-pp_master-vertrag.

    WHEN /oneepp/if_constants=>gc_object_ca_bor . "contract account
      rv_object_key = is_update_input-pp_all_data-pp_master-vkont.

    WHEN OTHERS.



  ENDCASE.


ENDMETHOD.

METHOD get_emma_sub_objects.

  DATA:
   ls_case_cat_details TYPE emma_ccat_complete,
   ls_emma_ccat_cob    TYPE emma_ccat_cob,
   ls_object           TYPE bapi_emma_case_object.

*--------------------------------------------------------------------*
  me->get_emma_ccat_details(
    EXPORTING
      iv_ccat = iv_ccat
    IMPORTING
      es_emma_ccat_details = ls_case_cat_details ).

  LOOP AT ls_case_cat_details-cob INTO ls_emma_ccat_cob.
    CLEAR ls_object.

    ls_object-celemname = ls_emma_ccat_cob-celemname.

    CASE ls_object-celemname.
*     EVENT_ID
      WHEN /oneepp/if_constants=>gc_bor_param_eventid.
        ls_object-refstruct = /oneepp/if_constants=>gc_table_event.
        ls_object-reffield  = /oneepp/if_constants=>gc_field_eventid.
        ls_object-id        = is_update_input-event_input-eventid.
*     Action COde
      WHEN /oneepp/if_constants=>gc_bor_param_action_code.
        ls_object-refstruct = /oneepp/if_constants=>gc_table_eventpos.
        ls_object-reffield  = /oneepp/if_constants=>gc_field_action_code.
        ls_object-id        = is_update_input-event_input-action_code.
    ENDCASE.

    CHECK ls_object-id IS NOT INITIAL.
    APPEND ls_object TO ct_objects.
  ENDLOOP.


ENDMETHOD.

