
proc sql noprint;
  select quote(strip(name))
  into :var separated by ","
  from dictionary.columns
   where libname = "WORK"
    and  memname = "TABLE";
quit;


data _null_;
  if 0 then set work.table;
  if _n_ = 1 then do;
    declare hash hashSort(ordered:'a');
                 hashSort.definekey(&var.);
                 hashSort.definedata(&var.);
                 hashSort.definedone();
   end;
   set work.table end=last;
   hashSort.add();
   if last then hashSort.output(dataset:'table_sorted');
run;
