  DATA:
      gcl_cust_cont_recharge_history TYPE REF TO cl_gui_custom_container,
      gcl_cust_cont_rech_hist_items TYPE REF TO cl_gui_custom_container,
      gv_container_recharge_history TYPE scrfname VALUE 'ALV_CONTAINER_RECHARGE_HISTORY',
      gv_container_rech_hist_items TYPE scrfname VALUE 'ALV_CONTAINER_RECH_ITEMS'.
      
  IF gcl_cust_cont_recharge_history IS INITIAL.

* create container for recharge history
    CREATE OBJECT gcl_cust_cont_recharge_history
      EXPORTING
        container_name = gv_container_recharge_history.

* create ALV grid
    CREATE OBJECT gcl_grid_recharge_history
      EXPORTING
        i_parent = gcl_cust_cont_recharge_history.

* build fieldcatalog
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name = '/ONEEPP/S_PP_MON_RECH_HIST_SCR'
      CHANGING
        ct_fieldcat      = gt_fieldcat_recharge_history[].

* change fieldcatalog so that only the fields remain that the user
* should see
* the texts are exported because the heading should not be 'Description of
* [Technical field lable] but only [Technical field lable]
    CALL METHOD /oneepp/cl_pp_monitor_display=>adjust_fieldcatalog_central
      EXPORTING
        iv_structure_name          = '/ONEEPP/S_PP_MON_RECH_HIST_SCR'
        iv_coltext_ta_type_descr   = text-201
        iv_coltext_stat_desc       = text-202
        iv_coltext_paymethod_descr = text-203
        iv_coltext_payment_1       = text-208
        iv_coltext_payment_2       = text-204
        iv_coltext_cancel_date     = text-205
        iv_coltext_cancel_payment1 = text-206
        iv_coltext_cancel_payment2 = text-207
        iv_coltext_mix_payment     = text-209
      CHANGING
        ct_fieldcat                = gt_fieldcat_recharge_history[].


* set Layout
    CALL METHOD /oneepp/cl_pp_monitor_display=>make_layout
      EXPORTING
        iv_structure_name = '/ONEEPP/S_PP_MON_RECH_HIST_SCR'
      IMPORTING
        es_alv_layout     = gs_layout_recharge_history.

* Eventhandling for Hotspot in ALV
*set HANDLER
* create Object to receive events and link them to handler methods.
* When the ALV Control raises the event for the specified instance
* the corresponding method is automatically called.
    CREATE OBJECT gref_rech_hist_event_receiver.
    SET HANDLER gref_rech_hist_event_receiver->handle_hotspot_click
                FOR gcl_grid_recharge_history.
    "Toolbar
    SET HANDLER gref_rech_hist_event_receiver->handle_toolbar
                FOR gcl_grid_recharge_history.
    "cancel transaction
    SET HANDLER gref_rech_hist_event_receiver->handle_user_command
                FOR gcl_grid_recharge_history.

* prepare first display
    CALL METHOD gcl_grid_recharge_history->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layout_recharge_history
      CHANGING
        it_fieldcatalog = gt_fieldcat_recharge_history[]
        it_outtab       = gt_recharge_history.

  ENDIF.