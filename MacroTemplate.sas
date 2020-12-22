/* ************************************************************************
*
* Refer: macros(xxxxxxxx)
*
* Function: xxx
* xxx
* xxx
*
* Notes: Change all occurrences of xxxxxxxx to lowercase macro name.
* and delete or replace these notes.
* xxx
*
* Globals: varname1 OUTPUT Usage...
* varname2 INPUT Usage...
*
*
* Revision history:
*
* Date Name Description of Change
* -------- -------------- --------------------------------------------------
* mm/dd/yy J Doe Initial version.
*
************************************************************************* */ 

%let k1 = %upcase(&k1 );

%if &debug > 0 %then
	%do;
		%put %str( );
		%put DEBUG: &sysmacroname: macro starting.;
		%put %str( );
	%end;

%if &debug > 2 %then
	%do;
		%put DEBUG: &sysmacroname: _USER_ macro variables and values at start:;
		%put _user_;
		%put %str( );
	%end;

%local errflag /* Error flag */
ts_start /* Date/time of start */
ts_end /* Date/time of end */
ts_elapsed /* Elapsed time in seconds */
now /* Date/time stamp for messages */
dsid /* Temp dataset ID from open/close */
num_obs /* Temp number of obs in output table */
rc /* Temp return code from sysfunc */
;
%let errflag = 0 ; /* Set error-found flag OFF */

%if %length(&p1 ) = 0 %then
	%do;
		%put ERROR: &sysmacroname: First positional parm cannot be missing.;
		%let errflag = 1;
	%end;

%if %length(&p2 ) = 0 %then
	%do;
		%let p2 = default-value;
		%put INFO: &sysmacroname: P2 is missing, defaulting to &p2..;
	%end;

%if %length(&out) = 0 %then
	%do;
		%put ERROR: &sysmacroname: OUT= parm cannot be missing.;
		%let errflag = 1;
	%end;

%if &p1 = m %then
	%do;
		* some statement;
	%end;
%else %if &p1 = n %then
	%do;
		* some statement;
	%end;
%else
	%do;
		%put ERROR: &sysmacroname: P1 =&p1 is invalid.;
		%let errflag = 1;
	%end;

%if %length(&mail_to) = 0 %then
	%do;
		%let mail_to = &sysuserid.@we-energies.com;
		%put WARNING: &sysmacroname: The MAIL_TO parameter is missing. %qcmpres(
			Set) to &mail_to..;
	%end;

%if &errflag ^= 0 %then
	%do;
		%put ERROR: &sysmacroname: Fatal error(s) encountered. %qcmpres(
			Macro) expansion aborted.;
		%goto exit;
	%end;
  
%let ts_start = %sysfunc( datetime(), 12. ) ;
%let now = %sysfunc( putn( &ts_start, datetime. ) ) ;
%put INFO: &sysmacroname: &now: Starting execution. ;

%let dsid = %sysfunc( open( &out ) ) ;
%let num_obs = %sysfunc( attrn( &dsid, nobs) ) ;
%let rc = %sysfunc( close( &dsid ) ) ; 

options
 mprint /* Enable macro printing */
 mprintnest /* Nest macro calls in MPRINT output */
/* mlogic /* Enable macro logic printing */
/* mlogicnest /* Nest macro logic in MPRINT output */
/* symbolgen /* Display resolved macro variable values */
 mexecnote /* Display macro execution information */
 mautolocdisplay /* Display source of macro when called */
;
%xxxxxxxx( p1= m
 , p2=
 , in= temp (obs=3)
 , out= temp
 , debug=2 ) ;
options nomprint nomprintnest nomlogic nomlogicnest nosymbolgen
 nomexecnote mcompilenote=none ;
/* New automatic macro variables with SAS 9.2 to show last error and warning:
%put Last Warning Message: &syswarningtext.. ;
%put Last Error Message: &syserrortext.. ;
/* ... end of comment block */ 
