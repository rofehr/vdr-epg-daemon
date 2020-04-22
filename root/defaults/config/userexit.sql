CREATE PROCEDURE userexit ()
BEGIN
/*
* fix tvm/tvsp duration = 0
*/
update
  events
set
  duration = 1
where
  source in('tvm','tvsp') and
  duration = 0;
END
