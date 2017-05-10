METHOD get_current_timestamp.
* Note: The below command for getting time stamp field is more exact
*       than the conversion as it considers milliseconds,
*       which is essential for the process (step) execution.

    DATA:
      lv_timezone     TYPE tznzone,
      lv_timestamp    TYPE timestamp,
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