FUNCTION /acidx/fm_sh_bp.
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
           partner         TYPE bu_partner,
           taxtype         TYPE bptaxtype,
           taxnum          TYPE bptaxnum,
           zz_service_prov TYPE service_prov,
           mc_city1        TYPE ad_mc_city,
           post_code1      TYPE ad_pstcd1,
           mc_street       TYPE ad_mc_strt,
           mc_county       TYPE ad_mc_county,
           pod             TYPE ext_ui,
         END OF ty_result.

  TYPES: BEGIN OF ty_service_prov,
           partner         TYPE bu_partner,
           zz_service_prov TYPE service_prov,
         END OF ty_service_prov.

  DATA: lt_result       TYPE STANDARD TABLE OF ty_result,
        lt_result_db    TYPE STANDARD TABLE OF ty_result,
        lt_result2      TYPE STANDARD TABLE OF ty_result,
        ls_result       TYPE ty_result,
        lt_service_prov TYPE STANDARD TABLE OF ty_service_prov.

  DATA: ls_selopt LIKE LINE OF shlp-selopt.

  DATA: lt_tax         TYPE STANDARD TABLE OF dfkkbptaxnum,
        lt_pod         TYPE STANDARD TABLE OF euitrans,
        lt_pod_db         TYPE STANDARD TABLE OF euitrans,
        lt_partner     TYPE STANDARD TABLE OF bapiisupodpartner,
        lt_partner_all TYPE STANDARD TABLE OF bapiisupodpartner.

  DATA: lt_partner_pod TYPE /idxpf/t_partner,
        lt_pod_ext     TYPE /acidx/tt_bupa_pod.

  FIELD-SYMBOLS: <fs_result>       TYPE ty_result,
                 <fs_tax>          TYPE dfkkbptaxnum,
                 <fs_pod>          TYPE euitrans,
                 <fs_shlp_tab>     TYPE shlp_descr,
                 <fs_interface>    TYPE ddshiface,
                 <fs_pod_ext>      TYPE /acidx/s_bupa_pod,
                 <fs_service_prov> TYPE ty_service_prov,
                 <fs_partner>      TYPE bapiisupodpartner.

  DATA: lv_dates(10).

  RANGES: lr_partner FOR but000-partner,
          lr_taxtype FOR dfkkbptaxnum-taxtype,
          lr_taxnum  FOR dfkkbptaxnum-taxnum,
          lr_valdt   FOR lv_dates,
          lr_service_prov FOR but000-zz_service_prov,
          lr_mc_city1   FOR adrc-mc_city1,
          lr_post_code1 FOR adrc-post_code1,
          lr_mc_street    FOR adrc-street,
          lr_mc_county  FOR adrc-county,
          lr_ext_ui  FOR euitrans-ext_ui.

  DATA: lv_ts_from        TYPE timestamp,
        lv_ts_init        TYPE timestamp,
        lv_ts_to          TYPE timestamp,
        lv_ts_from_but000 TYPE timestamp,
        lv_ts_to_but000   TYPE timestamp.

  CONSTANTS: lc_tzone   TYPE timezone             VALUE 'UTC',
             lc_time_to LIKE sy-uzeit             VALUE '235959',
             lc_date_to TYPE dats                 VALUE '99991231'.

  IF callcontrol-step = 'SELONE'.
*   PERFORM SELONE .........
    EXIT.
  ENDIF.
  IF callcontrol-step = 'PRESEL1'.

    EXIT.
  ENDIF.

  CALL FUNCTION 'F4UT_OPTIMIZE_COLWIDTH'
    TABLES
      shlp_tab    = shlp_tab
      record_tab  = record_tab
    CHANGING
      shlp        = shlp
      callcontrol = callcontrol.


  IF callcontrol-step = 'PRESEL'.
    CALL FUNCTION 'F4UT_SUPPRESS_SELECT_OPTIONS'
      EXPORTING
        parameter   = 'VALDT'
      TABLES
        shlp_tab    = shlp_tab
        record_tab  = record_tab
      CHANGING
        shlp        = shlp
        callcontrol = callcontrol
      EXCEPTIONS
        OTHERS      = 1.

    "DISPLAY

  ENDIF.

  IF callcontrol-step = 'SELECT'.

    "prepare selection options
    LOOP AT shlp-selopt INTO ls_selopt.
      CASE ls_selopt-shlpfield.
        WHEN 'PARTNER'.
          MOVE-CORRESPONDING ls_selopt TO lr_partner.
          APPEND lr_partner.
        WHEN 'TAXTYPE'.
          MOVE-CORRESPONDING ls_selopt TO lr_taxtype.
          APPEND lr_taxtype.
        WHEN 'TAXNUM'.
          MOVE-CORRESPONDING ls_selopt TO lr_taxnum.
          APPEND lr_taxnum.
        WHEN 'SERVICE_PROV'.
          MOVE-CORRESPONDING ls_selopt TO lr_service_prov.
          APPEND lr_service_prov.
        WHEN 'MC_CITY1'.
          MOVE-CORRESPONDING ls_selopt TO lr_mc_city1.
          APPEND lr_mc_city1.
        WHEN 'POST_CODE1'.
          MOVE-CORRESPONDING ls_selopt TO lr_post_code1.
          APPEND lr_post_code1.
        WHEN 'MC_STREET'.
          MOVE-CORRESPONDING ls_selopt TO lr_mc_street.
          APPEND lr_mc_street.
        WHEN 'MC_COUNTY'.
          MOVE-CORRESPONDING ls_selopt TO lr_mc_county.
          APPEND lr_mc_county.
        WHEN 'POD'.
          MOVE-CORRESPONDING ls_selopt TO lr_ext_ui.
          APPEND lr_ext_ui.
        when 'VALDT'.
          MOVE-CORRESPONDING ls_selopt TO lr_valdt.
          APPEND lr_valdt.
      ENDCASE.
    ENDLOOP.

    "get the date
    READ TABLE lr_valdt WITH KEY sign = 'I' option = 'EQ'.
    IF sy-subrc = 0.
      DELETE lr_valdt INDEX sy-tabix.
      CONVERT DATE lr_valdt-low
      INTO TIME STAMP lv_ts_from TIME ZONE lc_tzone.
      CONVERT DATE lr_valdt-low TIME lc_time_to
      INTO TIME STAMP lv_ts_to TIME ZONE lc_tzone.


      CONVERT DATE lr_valdt-low
      INTO TIME STAMP lv_ts_from_but000 TIME ZONE lc_tzone.

      CONVERT DATE lr_valdt-low
      INTO TIME STAMP lv_ts_to_but000 TIME ZONE lc_tzone.
    ELSE.
      CONVERT DATE lc_date_to TIME lc_time_to
      INTO TIME STAMP lv_ts_to TIME ZONE lc_tzone.

      CONVERT DATE lc_date_to TIME lc_time_to
      INTO TIME STAMP lv_ts_to_but000 TIME ZONE lc_tzone.
    ENDIF.

    "get bp from pod.
    IF lr_ext_ui[] IS NOT INITIAL .
      "get the pod
      SELECT *
        FROM euitrans
        INTO TABLE lt_pod_db
        WHERE ext_ui IN lr_ext_ui.
      IF sy-subrc = 0.
        lt_pod = lt_pod_db.
        SORT lt_pod.
        DELETE ADJACENT DUPLICATES FROM lt_pod.
      ENDIF.

      LOOP AT lt_pod ASSIGNING <fs_pod>.
        REFRESH lt_partner.
        CALL FUNCTION 'BAPI_ISUPOD_GETPARTNER'
          EXPORTING
            pointofdelivery = <fs_pod>-ext_ui
          TABLES
            partner         = lt_partner.
        IF sy-subrc = 0.
          APPEND LINES OF lt_partner TO lt_partner_all.
        ENDIF.
      ENDLOOP .
      SORT lt_partner_all.
      DELETE ADJACENT DUPLICATES FROM lt_partner_all.
      IF lt_partner_all IS INITIAL.
        callcontrol-step = 'DISP'.
        RETURN.
      ELSE.
        LOOP AT lt_partner_all ASSIGNING <fs_partner>.
          CLEAR lr_partner.
          lr_partner-low      = <fs_partner>-partner.
          lr_partner-option   = 'EQ'.
          lr_partner-sign     = 'I'.
          APPEND lr_partner.
        ENDLOOP.
      ENDIF.
    ENDIF.

*    IF lt_partner_all IS NOT INITIAL.
    "select values
    IF callcontrol-maxrecords IS INITIAL.


      SELECT
             c~mc_street,
             c~post_code1,
             c~mc_city1,
              a~partner,
              c~mc_county,
              a~zz_service_prov,
              d~taxtype,
              d~taxnum
        FROM but000 AS a
        INNER JOIN but020 AS b
        ON a~partner = b~partner
        INNER JOIN adrc AS c
        ON c~addrnumber = b~addrnumber AND c~date_from = b~date_from AND c~nation = b~nation
        LEFT OUTER JOIN dfkkbptaxnum AS d
        ON a~partner = d~partner
        INTO CORRESPONDING FIELDS OF TABLE @lt_result_db
                                 WHERE a~partner    IN @lr_partner
                                 AND   d~taxtype    IN @lr_taxtype
                                 AND   d~taxnum     IN @lr_taxnum
                                 AND   c~post_code1 IN @lr_post_code1
                                 AND   c~mc_street  IN @lr_mc_street
                                 AND   c~mc_city1   IN @lr_mc_city1
                                 AND   c~mc_county  IN @lr_mc_county
                                 AND   a~zz_service_prov IN @lr_service_prov
                                 AND ( b~addr_valid_from LE @lv_ts_to
                                   OR b~addr_valid_from = @lv_ts_init
                                   OR b~addr_valid_from IS NULL )
                                AND ( b~addr_valid_to   GE @lv_ts_from
                                   OR b~addr_valid_to   = @lv_ts_init
                                   OR b~addr_valid_to   IS NULL ) .


    ELSE.


      SELECT
             c~mc_street,
             c~post_code1,
             c~mc_city1,
              a~partner,
              c~mc_county,
              a~zz_service_prov,
              d~taxtype,
              d~taxnum
        UP TO @callcontrol-maxrecords ROWS
        FROM but000 AS a
        INNER JOIN but020 AS b
        ON a~partner = b~partner
        INNER JOIN adrc AS c
        ON c~addrnumber = b~addrnumber AND c~date_from = b~date_from AND c~nation = b~nation
        LEFT OUTER JOIN dfkkbptaxnum AS d
        ON a~partner = d~partner
        INTO CORRESPONDING FIELDS OF TABLE @lt_result_db
                                 WHERE a~partner    IN @lr_partner
                                 AND   d~taxtype    IN @lr_taxtype
                                 AND   d~taxnum     IN @lr_taxnum
                                 AND   c~post_code1 IN @lr_post_code1
                                 AND   c~mc_street  IN @lr_mc_street
                                 AND   c~mc_city1   IN @lr_mc_city1
                                 AND   c~mc_county  IN @lr_mc_county
                                 AND   a~zz_service_prov IN @lr_service_prov
                                 AND ( b~addr_valid_from LE @lv_ts_to
                                   OR b~addr_valid_from = @lv_ts_init
                                   OR b~addr_valid_from IS NULL )
                                AND ( b~addr_valid_to   GE @lv_ts_from
                                   OR b~addr_valid_to   = @lv_ts_init
                                   OR b~addr_valid_to   IS NULL ) .


    ENDIF.

    lt_result = lt_result_db.
    SORT lt_result.
    DELETE ADJACENT DUPLICATES FROM lt_result.

    "get pod from bp
    LOOP AT lt_result ASSIGNING <fs_result>.
      APPEND <fs_result>-partner TO lt_partner_pod.
    ENDLOOP.

    CALL METHOD /acidx/cl_utility_service_isu=>get_pod_from_bps
      EXPORTING
        it_bpartner = lt_partner_pod
      RECEIVING
        et_pod_ext  = lt_pod_ext.


    LOOP AT lt_result ASSIGNING <fs_result>.
      CLEAR ls_result.
      MOVE-CORRESPONDING <fs_result> TO ls_result.
      READ TABLE lt_pod_ext
           WITH KEY partner = <fs_result>-partner TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        LOOP AT lt_pod_ext ASSIGNING <fs_pod_ext>
          WHERE partner = <fs_result>-partner.
          ls_result-pod = <fs_pod_ext>-pod.
          APPEND ls_result TO lt_result2.
        ENDLOOP.
      ELSE.
        APPEND ls_result TO lt_result2.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION 'F4UT_RESULTS_MAP'
      TABLES
        shlp_tab          = shlp_tab
        record_tab        = record_tab
        source_tab        = lt_result2
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