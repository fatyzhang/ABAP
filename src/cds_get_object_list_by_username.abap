@AbapCatalog.sqlViewName: 'ZCDSOBJLIST'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Object List for Team 1'
define view ZCDS_OBJECT_LIST
  as select from    zteam1 as z1
  left outer join tadir  as ta on z1.uname = ta.author
 // left outer join trdirt as tr on ta.obj_name = tr.name
  association [1..1] to tadir as _tadir
  on z1.uname = _tadir.author
{
  key z1.uname as User_Name,
  full_name as Full_Name,
  count ( * ) as Object_num,
  _tadir
}
group by uname, full_name
  
  
  
  
  
  
  
  
  
  
 