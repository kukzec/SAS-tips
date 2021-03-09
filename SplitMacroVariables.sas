
%let n_per_list=2000;
data _null_;
  length tidlist $32000;
  length macrolist $1000;
  retain macrolist;
  do i=1 to &n_per_list. until (eof);
    set tid_list end=eof;
    tidlist=catx(",",tidlist,tid);
  end;
  listno+1;
  call symputx(cats("tidlist",listno),tidlist);
  macrolist=catx(",",macrolist,cats("&","tidlist",listno));
  call symputx("nblist",max(listno));
run;
