FUNCTION /acidx/fm_sh_pod.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCT
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     VALUE(SHLP) TYPE  SHLP_DESCR
*"     VALUE(CALLCONTROL) LIKE  DDSHF4CTRL STRUCTURE  DDSHF4CTRL
*"----------------------------------------------------------------------

  TYPES: BEGIN OF ty_result,
           pod     TYPE ext_ui,
           partner TYPE bu_partner,

         END OF ty_result.

  TYPES: BEGIN OF ty_pod_ext,
           int_ui TYPE int_ui,
           ext_ui TYPE ext_ui,
         END OF ty_pod_ext.

  DATA: lt_result     TYPE STANDARD TABLE OF ty_result,
        ls_result     TYPE ty_result,
        lt_partner    TYPE /idxpf/t_partner,
        lt_partner_db TYPE /idxpf/t_partner,
        lt_pod        TYPE /acidx/tt_bupa_pod,
        ls_pod        TYPE /acidx/s_bupa_pod,
        lt_pod_ext    TYPE STANDARD TABLE OF ty_pod_ext,
        lt_pod_ext_db TYPE STANDARD TABLE OF ty_pod_ext,
        ls_pod_ext    TYPE ty_pod_ext.

  DATA: ls_selopt LIKE LINE OF shlp-selopt.

  RANGES: lr_partner FOR but000-partner,
          lr_ext_ui  FOR euitrans-ext_ui.

  IF callcontrol-step = 'SELONE'.
*   PERFORM SELONE .........
    EXIT.
  ENDIF.
  IF callcontrol-step = 'PRESEL1'.
    EXIT.
  ENDIF.

  IF callcontrol-step = 'SELECT'.

    "prepare selection options
    LOOP AT shlp-selopt INTO ls_selopt.
      CASE ls_selopt-shlpfield.
        WHEN 'PARTNER'.
          MOVE-CORRESPONDING ls_selopt TO lr_partner.
          APPEND lr_partner.
        WHEN 'POD'.
          MOVE-CORRESPONDING ls_selopt TO lr_ext_ui.
          APPEND lr_ext_ui.
      ENDCASE.
    ENDLOOP.

    "get BP
    IF lr_partner IS NOT INITIAL.
      SELECT partner
        FROM but000
        INTO TABLE lt_partner_db
        WHERE partner IN lr_partner.
      IF sy-subrc = 0.
        lt_partner = lt_partner_db.
        SORT lt_partner.
        DELETE ADJACENT DUPLICATES FROM lt_partner.
      ENDIF.

      "get pod from bp
      CALL METHOD /acidx/cl_utility_service_isu=>get_pod_from_bps
        EXPORTING
          it_bpartner = lt_partner
        RECEIVING
          et_pod_ext  = lt_pod.


      "Get pod
*      SELECT int_ui
*             ext_ui
*        FROM euitrans
*        INTO TABLE lt_pod_ext_db UP TO callcontrol-maxrecords ROWS
*        WHERE ext_ui IN lr_ext_ui.
*      IF sy-subrc = 0.
*        lt_pod_ext = lt_pod_ext_db.
*        SORT lt_pod_ext.
*        DELETE ADJACENT DUPLICATES FROM lt_pod_ext.
*      ENDIF.

      LOOP AT lt_pod INTO ls_pod.
        CLEAR ls_result.
        ls_result-pod = ls_pod-pod.
        ls_result-partner = ls_pod-partner.
*        READ TABLE lt_pod_ext
*             WITH KEY ext_ui = ls_pod-pod TRANSPORTING NO FIELDS .
*        IF sy-subrc = 0.
          APPEND ls_result TO lt_result.
*        ENDIF.
      ENDLOOP.
    ELSE.

      "Get pod
      SELECT int_ui
             ext_ui
        FROM euitrans
        INTO TABLE lt_pod_ext UP TO callcontrol-maxrecords ROWS
        WHERE ext_ui IN lr_ext_ui .


      LOOP AT lt_pod_ext INTO ls_pod_ext.
        CLEAR ls_result.
        ls_result-pod = ls_pod_ext-ext_ui.
        APPEND ls_result TO lt_result.
      ENDLOOP.

    ENDIF.


    CALL FUNCTION 'F4UT_RESULTS_MAP'
      TABLES
        shlp_tab          = shlp_tab
        record_tab        = record_tab
        source_tab        = lt_result
      CHANGING
        shlp              = shlp
        callcontrol       = callcontrol
      EXCEPTIONS
        illegal_structure = 1
        OTHERS            = 2.
    IF sy-subrc = 0.
      callcontrol-step = 'DISP'.
    ENDIF.

  ENDIF.

ENDFUNCTION.