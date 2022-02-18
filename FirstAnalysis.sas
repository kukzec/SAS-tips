/* Adapted from https://blogs.sas.com/content/iml/2011/09/19/count-the-number-of-missing-values-for-each-variable.html */

proc format;
  value $missfmt ' ' = 'Missing' other = 'Not Missing';
  value missfmt . = 'Missing' other = 'Not Missing';
run;

/* Capture the output. */
ods output OneWayFreqs = want;
/* Count missing and not missing. */
proc freq data=have;
  format _char_ $missfmt. _numeric_ missfmt.;
  tables _all_ / missing nocum nopercent;
run;

data want;
  set want;
  array f {*} f_:;
  /* Extract column name. */
  do i = 1 to dim(f);
    if not missing(f[i]) then
      column = substr(vname(f[i]), 3);
  end;
  /* Extract column type. */
  type = vtypex(column);
  /* Get value, i. e. missing or not missing. */
  value = cats(of f_:);
run;

proc sort data=want;
  by column type value;
run;

/* Transpose the missing and not missing rows into two columns. */
proc transpose data=want out=want(drop=_:);
  by column type;
  id value;
  var frequency;
run;
