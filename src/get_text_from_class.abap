REPORT ztest_text.

PARAMETERS: p_cnam TYPE char32 DEFAULT 'zcl_XXXXX'.
PARAMETERS: p_tid TYPE textpoolky.

DATA : lv_text TYPE char200.
DATA: lv_class_inc TYPE char32.

DATA: lt_text TYPE TABLE OF textpool,
      ls_text LIKE LINE OF lt_text.

lv_class_inc = p_cnam.
lv_class_inc+30(2) = 'CP'.
TRANSLATE lv_class_inc USING ' ='.

READ TEXTPOOL lv_class_inc INTO lt_text LANGUAGE sy-langu.
SORT lt_text BY id.

IF p_tid IS NOT INITIAL.
  READ TABLE lt_text INTO ls_text
   WITH KEY key = p_tid.

  IF sy-subrc = 0.
    lv_text = ls_text-entry.
    WRITE: ls_text-key, lv_text.
  ENDIF.

ELSE.
  LOOP AT lt_text INTO ls_text.
    lv_text = ls_text-entry.
    WRITE: / ls_text-key, lv_text.

  ENDLOOP.

ENDIF.