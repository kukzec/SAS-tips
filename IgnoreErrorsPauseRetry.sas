%macro runquery(...);

  %do %until(&sqlrc=0);
    proc sql ...;
    quit;

    %if &sqlrc ne 0 %then %do;
      data _null_;
        x=sleep(60);  *Sleep 60 seconds on windows, 60 miliseconds on Linux;
      run;
    %end;
  %end;
%mend;
