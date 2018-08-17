CLASS zcl_path_serializer DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_path_serializer.

    ALIASES:
       get_instance             FOR zif_path_serializer~get_instance,
       build_ext_structure      FOR zif_path_serializer~build_ext_structure,
       serialize                FOR zif_path_serializer~serialize,
       serialize_from_data_obj  FOR zif_path_serializer~serialize_from_data_obj.

  PROTECTED SECTION.

    METHODS:
      extract_path
        IMPORTING
          iv_component_name TYPE string OPTIONAL
        CHANGING
          cs_data           TYPE any
          cs_path           TYPE zde_path DEFAULT space
          ct_path           TYPE zt_field,

      extract_path_structure
        IMPORTING
          iv_component_name TYPE string OPTIONAL
        CHANGING
          cs_data           TYPE any
          cs_path           TYPE zde_path
          ct_path           TYPE zt_field,

      extract_path_table
        IMPORTING
          iv_component_name TYPE string
        CHANGING
          ct_data           TYPE INDEX TABLE
          cs_path           TYPE zde_path
          ct_path           TYPE zt_field,

      extract_path_element
        IMPORTING
          iv_field TYPE zde_field
          iv_value TYPE string
        CHANGING
          cs_path  TYPE zde_path
          ct_path  TYPE zt_field.

    METHODS:

      build_structure
        IMPORTING
          is_path_line TYPE zs_field OPTIONAL
        CHANGING
          ct_path      TYPE string_table
          cs_data      TYPE any
        RAISING
          zcx_exception .

  PRIVATE SECTION.

    CONSTANTS cv_max_value_length TYPE i VALUE 50.

    CLASS-DATA:
      mi_path_serializer TYPE REF TO zcl_path_serializer.

    DATA:
      mv_path_prefix        TYPE zif_path_serializer~ty_path_prefix,
      mv_ignore_empty_value TYPE boolean VALUE abap_false.

ENDCLASS.



CLASS zcl_path_serializer IMPLEMENTATION.


  METHOD zif_path_serializer~build_ext_structure.
*   Get My Path
    DATA(ls_path_line) = is_path_line.
    REPLACE FIRST OCCURRENCE OF mv_path_prefix IN ls_path_line-path WITH ''.
    SPLIT ls_path_line-path AT '/' INTO TABLE DATA(lt_path).
    DELETE lt_path WHERE table_line IS INITIAL.
*   Build Deep STRUCTURE
    me->build_structure(
      EXPORTING
        is_path_line = ls_path_line
      CHANGING
        ct_path      = lt_path
        cs_data      = cs_data
    ).

  ENDMETHOD.


  METHOD zif_path_serializer~extract_path_to_table.
    me->extract_path(
      CHANGING
        cs_data = cs_data
        cs_path = cs_path
        ct_path = ct_path
    ).
  ENDMETHOD.


  METHOD zif_path_serializer~get_instance.
*   Singleton Instance
    IF mi_path_serializer IS NOT BOUND.
      mi_path_serializer = NEW zcl_path_serializer( ).
    ENDIF.
*   Set Parameter
    mi_path_serializer->mv_ignore_empty_value = iv_ignore_empty_value.
*   Return Instance
    ri_path_serializer = mi_path_serializer.
*   Set Prefix for Path
    CAST zcl_path_serializer( ri_path_serializer )->mv_path_prefix = iv_path_prefix.
  ENDMETHOD.

  METHOD zif_path_serializer~serialize.
    me->extract_path(
      CHANGING
        cs_data = is_data
        ct_path = et_path
    ).
  ENDMETHOD.


  METHOD zif_path_serializer~serialize_from_data_obj.

    FIELD-SYMBOLS <lv_data> TYPE any.

    ii_data->get_data_container(
      IMPORTING
        es_data           = <lv_data>
    ).

    me->zif_path_serializer~serialize(
      EXPORTING
        is_data           = <lv_data>
      IMPORTING
        et_path           = et_path
    ).

  ENDMETHOD.

  METHOD build_structure.
    IF ct_path IS INITIAL.
*     Finally come to the end - Field and Value
      ASSIGN COMPONENT is_path_line-field OF STRUCTURE cs_data TO FIELD-SYMBOL(<lv_field>).
      IF sy-subrc = 0.
        TRY.
            <lv_field> = is_path_line-value.
          CATCH cx_root INTO DATA(lx_error).
            zcx_exception=>raise_exception(
                ix_previous       = lx_error
            ).
        ENDTRY.
      ENDIF.
    ELSE.
*     More deep structures...
*     Get line number
      DATA: lv_line_number TYPE i,
            lv_path_name   TYPE zde_field.
      FIELD-SYMBOLS:
        <l_data>  TYPE any,
        <lv_stru> TYPE INDEX TABLE.
      TRY.
*         ABAP Field does not allow "\"
*         Recover "\" to "/" (Name space)
          DATA(lv_path) = replace( val = ct_path[ 1 ] sub = '\' with = '/' occ = 0 ).
          lv_path_name   = substring_before( val = lv_path sub = '[' ).
          IF lv_path_name IS INITIAL.
            lv_path_name = lv_path.
          ENDIF.
          lv_line_number = substring_before( val = substring_after( val = lv_path sub = '[' ) sub = ']' ).
          IF lv_line_number = 0.
            lv_line_number = 1.
          ENDIF.
      ENDTRY.
*     Remove Current Path
      DELETE ct_path INDEX 1.
*     Get into deeper structure
*     2 possibilities: Structure or Table
      ASSIGN COMPONENT lv_path_name OF STRUCTURE cs_data TO <l_data>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      DATA(li_descr) = cl_abap_typedescr=>describe_by_data( p_data = <l_data> ).

      CASE li_descr->kind.
        WHEN cl_abap_typedescr=>kind_struct.
          me->build_structure(
            EXPORTING
              is_path_line      = is_path_line
            CHANGING
              ct_path           = ct_path
              cs_data           = <l_data> ).

        WHEN cl_abap_typedescr=>kind_table.
          ASSIGN COMPONENT lv_path_name OF STRUCTURE cs_data TO <lv_stru>.
          IF sy-subrc <> 0.
*           Stop Processing
            CLEAR ct_path[].
            EXIT.
          ENDIF.

*         Get Table Line
          DATA(lv_total_line) = lines( <lv_stru> ).
          IF lv_total_line < lv_line_number.
            WHILE lv_total_line < lv_line_number.
              lv_total_line = lv_total_line + 1.
              INSERT INITIAL LINE INTO TABLE <lv_stru>.
            ENDWHILE.
          ENDIF.

          IF sy-subrc = 0.
*           Go Deeper!
            me->build_structure(
              EXPORTING
                is_path_line      = is_path_line
              CHANGING
                ct_path           = ct_path
                cs_data           = <lv_stru>[ lv_line_number ]
            ).
          ELSE.
*           Stop Processing
            CLEAR ct_path[].
            EXIT.
          ENDIF.
      ENDCASE.
    ENDIF.
  ENDMETHOD.


  METHOD extract_path.

    DATA(li_descr) = cl_abap_typedescr=>describe_by_data( p_data = cs_data ).

    CASE li_descr->kind.
      WHEN cl_abap_typedescr=>kind_struct.
        me->extract_path_structure(
          EXPORTING
            iv_component_name = iv_component_name
          CHANGING
            cs_data = cs_data
            cs_path = cs_path
            ct_path = ct_path
        ).

      WHEN cl_abap_typedescr=>kind_table.
        me->extract_path_table(
          EXPORTING
            iv_component_name = iv_component_name
          CHANGING
            ct_data = cs_data
            cs_path = cs_path
            ct_path = ct_path
        ).

      WHEN cl_abap_typedescr=>kind_elem.
        me->extract_path_element(
          EXPORTING
            iv_field = CONV #( li_descr->absolute_name )
            iv_value = CONV #( cs_data )
          CHANGING
            cs_path = cs_path
            ct_path = ct_path
        ).
    ENDCASE.

  ENDMETHOD.


  METHOD extract_path_element.
    DATA li_descr_data TYPE REF TO cl_abap_elemdescr.
    DATA ls_path_info TYPE zs_field.

*   Check if Value is Empty
    IF mi_path_serializer->mv_ignore_empty_value = abap_true AND
       strlen( iv_value ) = 0.
      EXIT.
    ENDIF.

    ls_path_info-field = iv_field.
    ls_path_info-path = cs_path.
    ls_path_info-value = iv_value.
    INSERT ls_path_info INTO TABLE ct_path.

  ENDMETHOD.


  METHOD extract_path_structure.
    DATA(ls_path) = cs_path.
    IF iv_component_name IS NOT INITIAL.
      ls_path = cs_path && '/' && replace( val = iv_component_name sub = '/' with = '\' occ = 0 ).
    ENDIF.

    DATA li_descr_data TYPE REF TO cl_abap_structdescr.
    li_descr_data ?= cl_abap_typedescr=>describe_by_data( p_data = cs_data ).
    DATA(lt_comp) = li_descr_data->get_components( ).
*   Expand Include
    LOOP AT lt_comp ASSIGNING FIELD-SYMBOL(<ls_comp>) WHERE as_include = abap_true.
*     Append and Include Group Name may be empty
      DATA(li_stru_type) = CAST cl_abap_structdescr( <ls_comp>-type ).
      DATA(lt_comp_exp) = li_stru_type->get_components( ).
*     Must be append (not insert) in the loop
      APPEND LINES OF lt_comp_exp TO lt_comp.
    ENDLOOP.
*   Delete unnecessary entries
    DELETE lt_comp WHERE name IS INITIAL OR as_include = abap_true.

*   Start Process components
    LOOP AT lt_comp ASSIGNING <ls_comp>.

*     Get Field Data
      ASSIGN COMPONENT <ls_comp>-name OF STRUCTURE cs_data TO FIELD-SYMBOL(<ls_comp_data>).

      CASE <ls_comp>-type->kind.

        WHEN cl_abap_typedescr=>kind_table.
*           Table
          me->extract_path_table(
            EXPORTING
              iv_component_name = <ls_comp>-name
            CHANGING
              ct_data = <ls_comp_data>
              cs_path = ls_path
              ct_path = ct_path
          ).
        WHEN cl_abap_typedescr=>kind_elem.
*           Element
          me->extract_path_element(
            EXPORTING
              iv_field = CONV #( <ls_comp>-name )
              iv_value = CONV #( <ls_comp_data> )
            CHANGING
              cs_path = ls_path
              ct_path = ct_path
          ).
        WHEN cl_abap_typedescr=>kind_struct.
          me->extract_path_structure(
            EXPORTING
              iv_component_name = <ls_comp>-name
            CHANGING
              cs_data = <ls_comp_data>
              cs_path = ls_path
              ct_path = ct_path
          ).
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.


  METHOD extract_path_table.
*   Replace "/" in table name to "\".
*   TODO Replace -> all characters need to be transformed -> URL encode
*   1. To be different with the separator in PATH
*   2. ABAP Field Name does not allow "\", only allows "/" for name space
    DATA(ls_path) = cs_path.
    DATA(ls_path_with_index) = ls_path.
    IF iv_component_name IS NOT INITIAL.
      ls_path = cs_path && '/' && replace( val = iv_component_name sub = '/' with = '\' occ = 0 ).
    ENDIF.

    LOOP AT ct_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      ls_path_with_index = ls_path && '[' && sy-tabix &&']'.
      me->extract_path(
        CHANGING
          cs_data = <ls_data>
          cs_path = ls_path_with_index
          ct_path = ct_path
      ).
    ENDLOOP.

  ENDMETHOD.


ENDCLASS.