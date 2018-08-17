* Checksum and Cyclic Redundancy Check
* CRC Cyclic Redundancy Check[1]  
* ABAP Code Sample:
Data:  lv_frame type ZHEXA128,
       lv_checksum(2) TYPE x,
       lv_offset      TYPE i.

select single xtrame from ** into lv_frame.

if lv_frame is not initial.
  DO 52 TIMES.
    ADD lv_frame+lv_offset(1) TO lv_checksum.
    ADD 1 TO lv_offset.
  ENDDO.
  if  lv_checksum <> lv_frame+53(2).
*         return error.
  endif.

endif.