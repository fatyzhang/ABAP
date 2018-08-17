method /IDXPF/IF_UI_COMPONENT_MGR~FREE_CONTROLS.

  IF NOT gs_ui_component_details-alv_table IS INITIAL.
    CALL METHOD gs_ui_component_details-alv_table->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 0.

    IF sy-subrc <> 0.
      MESSAGE e004(/IDXPF/ui) INTO gv_mtext.
      CALL METHOD /IDXPF/CX_UI_ERROR=>raise_ui_exception_from_msg.
    ENDIF.

    CLEAR gs_ui_component_details-alv_table.
  ENDIF.

*--------------------------------------------------------------------*
  IF NOT gs_ui_component_details-container IS INITIAL.
    CALL METHOD gs_ui_component_details-container->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 0.

    IF sy-subrc <> 0.
      MESSAGE e004(/IDXPF/ui) INTO gv_mtext.
      CALL METHOD /IDXPF/CX_UI_ERROR=>raise_ui_exception_from_msg.
    ENDIF.

    CLEAR gs_ui_component_details-container.
  ENDIF.

endmethod.
