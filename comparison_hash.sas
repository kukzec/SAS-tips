
proc sql;
  select name into :varnames separated by ","
  from dictionary.columns
  where libname = "lib"
    and memname "table";
quit;

data check(keep=checksum);
  length concat $2000.; /* make sure this is long enough to fit all the variables concatenated */
  set table end=last;
  format checksum $hex32.;
  retain checksum;
  concat = cats(&varnames.);
  checksum = mdp5(concat); /* Could use sha256 for better hashing */
run;
