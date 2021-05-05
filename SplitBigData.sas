%macro split (SRC_DATASET=, OUT_PREFIX=, SPLIT_NUM=, SPLIT_DEF=);
/* Parameters:
/*   SRC_DATASET - name of the source data set     */
/*   OUT_PREFIX - prefix of the output data sets   */
/*   SPLIT_NUM - split number                      */
/*   SPLIT_DEF - split definition (=SETS or =NOBS) */
 
   %local I K S TLIST;
 
   /* number of observations &K, number of smaller datasets &S */
   data _null_;
      if 0 then set &SRC_DATASET nobs=N;
      if upcase("&SPLIT_DEF")='NOBS' then
         do;
            call symputx('K',&SPLIT_NUM); 
            call symputx('S',ceil(N/&SPLIT_NUM));
            put "***MACRO SPLIT: Splitting into datasets of no more than &SPLIT_NUM observations";
         end;
         else if upcase("&SPLIT_DEF")='SETS' then
         do;
            call symputx('S',&SPLIT_NUM); 
            call symputx('K',ceil(N/&SPLIT_NUM));
            put "***MACRO SPLIT: Splitting into &SPLIT_NUM datasets";
        end;
         else put "***MACRO SPLIT: Incorrect SPLIT_DEF=&SPLIT_DEF value. Must be either SETS or NOBS.";
      stop; 
   run;
 
   /* terminate macro if nothing to split */
   %if (&K le 0) or (&S le 0) %then %return;
 
    /* generate list of smaller dataset names */
   %do I=1 %to &S;
      %let TLIST = &TLIST &OUT_PREFIX._&I;
   %end;
 
   /* split source dataset into smaller datasets */
   data &TLIST;
      set &SRC_DATASET;
      select;
         %do I=1 %to &S;
            when(_n_ <= &K * &I) output &OUT_PREFIX._&I; 
         %end;
      end;
   run;
 
%mend split;
