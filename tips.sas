/* This program is a collection of small functions and macro which make 
   common patterns shorter and easier. */

Dates:

The default separator for the YYMMDD format is the dash or hyphen.

Possible separators for the extended version of the format are:
    - n no separator (YYYYMMDD10.)
    - b blank (YYYYMMDDB10.)
    - d dash (YYYYMMDDD10.)
    - s slash (YYYYMMDDS10.)
    - p period (YYYYMMDDP10.)
    - c colon (YYYYMMDDC10.)
   

/* output all characters variables's values in uppercase */
%macro upcase_CharVar(lib,ds);
proc sql noprint;
	select strip(NAME)||" = UPCASE( "||STRIP(NAME) || ");"
	into :code_str separated by ' '
	from dictionary.columns
	where libname = upcase("&lib") and memname = upcase("&ds") 
		  and type = 'char';
	quit;

data &ds;
	set &ds;
	&code_str
run;
%mend;

/* output the variable names in uppercase */
%macro upcase_VarNames(dsn); 
%let dsid=%sysfunc(open(&dsn)); 
%let num=%sysfunc(attrn(&dsid,nvars)); 
%put &num;
data &dsn; 
	set &dsn
		(rename=( 
        	%do i = 1 %to &num; 
        	/* function of varname returns the name of a SAS data set variable*/
        		%let var&i=%sysfunc(varname(&dsid,&i));
       			&&var&i=%sysfunc(upcase(&&var&i)) /*rename all variables*/ 
        	%end;)); 
%let close=%sysfunc(close(&dsid)); 
run; 
%mend; 

/* macro to test macro parameters */
/* returns 1 if the tested parameter is blank */
/* 0 otherwise, blank means all characters are,*/
/* or are macro variables that resolve to a  */
/* blank */
/* param can be up to 65,531 characters long */
/* if numeric and several 1000 digits long may*/
/* hang the session. (Windows 32 bit OS) */
/* NOT a test for a NULL (zero length string) */
/* though may work for some of those as well */
 
%macro isBlank(param);
  %sysevalf(%superq(param)=,boolean)
%mend isBlank;

/* Check if there is duplicates, return a warning if true */
%macro check_duplicates(dup_table);
%local dsid nobs;

%let dsid=%sysfunc(open(work.&dup_table.));
%let nobs=%sysfunc(attrn(&dsid,nlobs));
%let dsid=%sysfunc(close(&dsid));

%if &nobs. = 0 %then %do;
	data _null_;
	putlog "NOTE: No duplicates in the input file.";
	run;

	proc datasets lib=work nodetails nolist; delete &dup_table.; run;
%end;
%else %do;
	data _null_;
	putlog "WARNING: Duplicates found in the input file. Plese check &dup_table.";
	run;
%end;
%mend;


/**************************************************************************/
/* expo_round.sas -- */
/* This macro performs a form of expoential rounding. */
/* It rounds numbers to increasingly larger values as their value */
/* It can be used for reporting sales when an exact number is not needed */
/* or when giving an exact number might be more confusing. */
/* This is a FUNCTION-type macro. */
/* USAGE: */
/* approx_sales = %expo_rounded(sales); */
/**************************************************************************/
%macro expo_round(what_var);
 ifn(&what_var lt 1000,round(&what_var, 100),
 ifn(&what_var lt 10000,round(&what_var, 1000),
 ifn(&what_var lt 100000,round(&what_var, 10000),
 ifn(&what_var lt 1000000,round(&what_var, 100000),
 ifn(&what_var lt 10000000,round(&what_var, 1000000),
 round(&what_var,10000000),.)))))
%mend;


/**************************************************************************/
/* file_date.sas -- */
/* This is a "function" macro to easily determine the update date of any */
/* file. It can be used to test the age of an imported spreadsheet to */
/* make sure it is a reasonably-recent version. */
/* USAGE: my_file_date = %file_date("fully_qualified_path_and_name"); */
/* The path and file may or may not be quoted. */
/**************************************************************************/
%macro file_date(file_path_and_name);
 ((filename("_fd&sysjobid","%bquote(&file_path_and_name)")*0) +
 input(finfo(fopen ("_fd&sysjobid"), "Last modified"),anydtdte18.))
%mend;

/**************************************************************************/
/* make_var.sas -- */
/* This routine creates a unique macro variable name that can be used in */
/* any routine without fear of colliding with other variables of the same */
/* name. */
/**************************************************************************/
%macro make_var(var,len,logoption);
%global &var;
%let &var = _%substr(%sysfunc(compress(%sysfunc(uuidgen()),'-')),1,31);
%if "&len" ne "" %then %do;
 %let &var = %substr(&&&var,1,&len);
 %end;
%if %upcase("&logoption") ne "NOLOG" %then %do;
 %put NOTE: New macro variable &var created as &&&var;
 %end;
%mend;


/**************************************************************************/
/* progress.sas -- */
/**************************************************************************/
%macro progress;
 %make_var(progcntr);
 %make_var(recocntr);
 %make_var(datstrng);
 drop
 &progcntr
 &recocntr
 &datstrng
 ;
 length &datstrng $ 21;
 &progcntr + 1;
 &recocntr + 1;
 if &progcntr = 100000 then do;
 &datstrng = put(datetime(),datetime21.);
 file log;
 put &datstrng ' RecordCounter=' &recocntr comma13.;
 &progcntr = 0;
 end;
%mend;


