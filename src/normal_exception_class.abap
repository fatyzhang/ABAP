* super class       CX_STATIC_CHECK
* interface IF_T100_MESSAGE
* 
METHOD raise_exception_from_msg.
*IR_PREVIOUS	TYPE REF TO CX_ROOT OPTIONAL
*IV_MSGID	TYPE SYMSGID OPTIONAL
*IV_MSGNO	TYPE SYMSGNO OPTIONAL
*IV_MSGV1	TYPE SYMSGV OPTIONAL
*IV_MSGV2	TYPE SYMSGV OPTIONAL
*IV_MSGV3	TYPE SYMSGV OPTIONAL
*IV_MSGV4	TYPE SYMSGV OPTIONAL
*IS_TEXTID	TYPE SCX_T100KEY OPTIONAL
*IT_BAPIRET	TYPE BAPIRET2_T OPTIONAL
*IR_DATA	TYPE REF TO DATA OPTIONAL

* Do not call this method within TRY..ENDTRY block
* This method is used to raise exceptions only

  DATA:
   lv_timestamp  TYPE /oneepp/de_timestamp,
   lx_previous   TYPE REF TO zcx_oneepp_error.              "#EC NEEDED


*--------------------------------------------------------------------*
* Local Variables
  DATA:
     ls_textid TYPE scx_t100key.

  IF is_textid IS INITIAL.
    ls_textid-msgid = iv_msgid.
    ls_textid-msgno = iv_msgno.
  ELSE.
    ls_textid = is_textid.
  ENDIF.

  IF ls_textid-attr1 IS INITIAL.
    ls_textid-attr1 = iv_msgv1.
    ls_textid-attr2 = iv_msgv2.
    ls_textid-attr3 = iv_msgv3.
    ls_textid-attr4 = iv_msgv4.
  ENDIF.

  lv_timestamp = get_current_timestamp( ).

*--------------------------------------------------------------------*
  RAISE EXCEPTION TYPE zcx_error
    EXPORTING
      previous    = ir_previous
      textid      = ls_textid
      timestamp   = lv_timestamp
      bapi_return = it_bapiret
      data        = ir_data.

ENDMETHOD.

  METHOD get_current_timestamp.
* Note: The below command for getting time stamp field is more exact
*       than the conversion as it considers milliseconds,
*       which is essential for the process (step) execution.

    DATA:
      lv_timezone     TYPE tznzone,
      lv_timestamp    TYPE /oneepp/de_timestamp,
      lv_time         TYPE syuzeit,
      lv_date         TYPE sydatum,
      lv_millisec(9)  TYPE p DECIMALS 7.

*--------------------------------------------------------------------*
    CLEAR rv_timestamp.

    IF iv_time_zone IS INITIAL.
      lv_timezone = gv_timezone.
    ELSE.
      lv_timezone = iv_time_zone.
    ENDIF.

    GET TIME STAMP FIELD lv_timestamp.

    CONVERT TIME STAMP lv_timestamp TIME ZONE lv_timezone
    INTO DATE lv_date
         TIME lv_time.

* Replace date and time pending on timezone
    CONVERT DATE lv_date TIME lv_time
      INTO TIME STAMP rv_timestamp TIME ZONE lv_timezone.

    lv_millisec = frac( lv_timestamp ).

    rv_timestamp = rv_timestamp + lv_millisec.

  ENDMETHOD.                    "get_current_timestamp