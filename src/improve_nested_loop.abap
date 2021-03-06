* https://wiki.scn.sap.com/wiki/display/Community/Alternatives+for+Nested+Loops
* 1)                   Nested Loop

* 2)                   Indexed Loop

* 3)                   Parallel Cursor 
* Below is a sample program designed to demonstrate the alternative methods for nested looping in internal tables and the relative comparison for the above three methods. 

* Example: As I am a SAP ABAP CRM consultant, I have designed a program using CRM database tables. I have used two internal tables which will have data fetched from CRMD_ORDERADM_H (Business Transaction) and CRMD_ORDERADM_I. The first database table has a key field 'GUID' whereas the later database table will have multiple data against the key field 'GUID'.                                            Here, crmd_orderadm_h-guid = crmd_orderadm_i-header.

* Please note that there is no business logic related to the code. Also only 500 records are selected from the header table to demonstrate the performance of the above three methods. Sample Code:
 *->Global Variable Decleration
DATA: gv_stime  TYPE i,                  "Start Time
      gv_etime  TYPE i,                  "End Time
      gv_tdiff  TYPE i.                  "Time Difference

*->Internal Table Decleration
DATA:
*Header data internal table
      gt_orderh TYPE STANDARD TABLE OF crmd_orderadm_h,
*Item data internal table
      gt_orderi TYPE STANDARD TABLE OF crmd_orderadm_i.

START-OF-SELECTION.
  PERFORM data_select.
  IF NOT gt_orderh IS INITIAL AND
     NOT gt_orderi IS INITIAL.
    PERFORM nested_loop.
    PERFORM indexed_loop.
    PERFORM parallel_cursor.
  ENDIF.
*&---------------------------------------------------------------------*
*&      Form  data_select
*&---------------------------------------------------------------------*
FORM data_select.

  SELECT *
    FROM crmd_orderadm_h
    UP TO 1000 ROWS
    INTO TABLE gt_orderh.

  IF sy-subrc EQ 0.
    CHECK gt_orderh[] IS NOT INITIAL.

    SELECT *
      FROM crmd_orderadm_i
      INTO TABLE gt_orderi
      FOR ALL ENTRIES IN gt_orderh
      WHERE header = gt_orderh-guid.

    IF sy-subrc = 0.
      SORT gt_orderi BY header.
    ENDIF.

    SORT gt_orderh BY guid.
  ENDIF.
ENDFORM.                    " data_select

*&---------------------------------------------------------------------*
*&      Form  nested_loop
*&---------------------------------------------------------------------*
FORM nested_loop.

  DATA: lw_orderh     TYPE crmd_orderadm_h,
        lw_orderi     TYPE crmd_orderadm_i.

  GET RUN TIME FIELD gv_stime.

  LOOP AT gt_orderh INTO lw_orderh.

    LOOP AT gt_orderi INTO lw_orderi
                     WHERE header = lw_orderh-guid.

    ENDLOOP.

  ENDLOOP.

  GET RUN TIME FIELD gv_etime.
  gv_tdiff = gv_etime - gv_stime.
  WRITE:/1(61) sy-uline.
  WRITE: /1 sy-vline, 2(40) 'Time Lapsed Using Nested Loops:', gv_tdiff,
                      41 sy-vline,
                      50(10) gv_tdiff,
                      61 sy-vline.
ENDFORM.                    " nested_loop

*&---------------------------------------------------------------------*
*&      Form  indexed_loop
*&---------------------------------------------------------------------*
FORM indexed_loop.

  DATA: lw_orderh     TYPE crmd_orderadm_h,
        lw_orderi     TYPE crmd_orderadm_i,
        lv_orderi_idx TYPE sy-tabix.       "Item Table Index

  CLEAR: gv_tdiff,
         gv_etime,
         gv_stime.

  GET RUN TIME FIELD gv_stime.

  LOOP AT gt_orderh INTO lw_orderh.

    READ TABLE gt_orderi INTO lw_orderi
                     WITH KEY header = lw_orderh-guid
                     BINARY SEARCH.

    lv_orderi_idx = sy-tabix.

    WHILE sy-subrc = 0.
      lv_orderi_idx = lv_orderi_idx + 1.   "increment the index by one

      CLEAR lw_orderi.
      READ TABLE gt_orderi INTO lw_orderi
                          INDEX lv_orderi_idx.
      IF lw_orderh-guid <> lw_orderi-header.
        sy-subrc = 99.
      ENDIF.
    ENDWHILE.

  ENDLOOP.

  GET RUN TIME FIELD gv_etime.
  gv_tdiff = gv_etime - gv_stime.

  WRITE:/1(61) sy-uline.
  WRITE: /1 sy-vline, 2(40) 'Time Lapsed Using Indexed Method:', gv_tdiff,
                      41 sy-vline,
                      50(10) gv_tdiff,
                      61 sy-vline.
ENDFORM.                    " indexed_loop

*&---------------------------------------------------------------------*
*&      Form  parallel_cursor
*&---------------------------------------------------------------------*

FORM parallel_cursor.

  DATA: lw_orderh     TYPE crmd_orderadm_h,
        lw_orderi     TYPE crmd_orderadm_i,
        lv_orderi_idx TYPE sy-tabix.       ""Item Table Index

  CLEAR: gv_tdiff,
         gv_etime,
         gv_stime.

  GET RUN TIME FIELD gv_stime.

  LOOP AT gt_orderh INTO lw_orderh.

    READ TABLE gt_orderi INTO lw_orderi
                     WITH KEY header = lw_orderh-guid
                     BINARY SEARCH.
    IF sy-subrc = 0.
      lv_orderi_idx = sy-tabix.

      LOOP AT gt_orderi INTO lw_orderi FROM lv_orderi_idx.
        IF lw_orderh-guid <> lw_orderi-header.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDLOOP.

  GET RUN TIME FIELD gv_etime.
  gv_tdiff = gv_etime - gv_stime.

  WRITE:/1(61) sy-uline.
  WRITE: /1 sy-vline, 2(40) 'Time Lapsed Using Cursor Method:', gv_tdiff,
                      41 sy-vline,
                      50(10) gv_tdiff,
                      61 sy-vline.
  WRITE:/1(61) sy-uline.

ENDFORM.                    " parallel_cursor