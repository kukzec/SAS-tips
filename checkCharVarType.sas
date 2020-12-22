/* The “checkCharVarType” macro[6]: The “checkCharVarType” macro can provide more information
about a character variable, like if the variable only contains numeric values, or contains no values or
contains date and datetime values. Based on the information we get, we can do things in batches, like
convert character values to numeric values, delete those character variables with no values, make date
and datetime variables be consistent across the data sets. */


%macro checkCharVarType(libname=,datasets=%str(),filedir=);

%macro checkcharvars(libnm=,datanm=,varnm=,tno=);

	proc sql;
		create table tchar_&tno. as
			select distinct "&libnm." as libnm length=32,
				"&datanm." as datanm length=32,
				"&varnm." as varnm length=32,
				&varnm. as value length=1000
			from &libnm..&datanm.(keep=&varnm.);
	quit;

%mend;

%let datasets=%sysfunc(upcase(&datasets.));

proc sql noprint;
	*select all the char variables from the data sets and save them in data set
	tmp1;
	create table tmp1 as
		select libname,memname,memtype,name
			from dictionary.columns
				where libname=upcase("&libname.") and memtype="DATA" and type="char"
					%if &datasets.^= %then

		%do;
			and upcase(memname) in (&datasets.)
		%end;
	;
quit;

data tmp2;
	length libnm datanm varnm $32.;
	set tmp1;
	keep libnm datanm varnm;
	libnm=libname;
	datanm=memname;
	varnm=name;
	attrib _all_ label='';
run;

proc sort data=tmp2;
	by libnm datanm varnm;
run;

data tmp2;
	set tmp2;
	length sascodes $500.;
	sascodes=cats('%checkcharvars(libnm=',libnm,',datanm=',datanm,',varnm=',varnm
		,',tno=',_n_,');');
run;

data _null_;
	set tmp2;
	call execute(sascodes);
run;

data tmp3;
	set tchar_:;
run;

proc sort data=tmp3;
	by value;
run;

data tmp4;
	set tmp3;
	length chartype $50.;

	if value="" then
		chartype="missing";
	else
		do;
			value1=compress(value,'0123456789');

			if value1 in ("") or (substr(value,1,1) in ("+","-") and value1 in ("+","-")) then
				chartype="integer";
			else if value1 in (".") or (substr(value,1,1) in ("+","-") and value1 in ("+.","-.")) then
				chartype="decimal";
			else if value1="--" and length(value) in (8,10) then
				chartype="date_hyphen";
			else if value1="//" and length(value) in (8,10) then
				chartype="date_slash";
			else if lowcase(value1) in ('jan','feb','mar','apr','may','jun',
				'jul','aug','sep','oct','nov','dec') and
				length(value) in (7,9) then
				chartype="date_dateM";
			else if value1 in ("--::","--:::") then
				chartype="datetime_hyphen";
			else if value1 in ("//::","//:::") then
				chartype="datetime_slash";
			else if lowcase(value1) in ('jan::','feb::','mar::','apr::','may::','jun::',
				'jul::','aug::','sep::','oct::','nov::','dec::',
				'jan:::','feb:::','mar:::','apr:::','may:::',
				'jun:::', 'jul:::','aug:::','sep:::','oct:::', 'nov:::','dec:::')
				then
				chartype="datetime_dateM";
			else chartype="undefined";
		end;

	keep libnm datanm varnm value value1 chartype;
run;

proc sort data=tmp4 out=tmp5 nodupkey;
	by libnm datanm varnm chartype;
run;

proc transpose data=tmp5 out=tmp5(drop=_name_) prefix=type;
	by libnm datanm
		varnm;
	var chartype;
run;

data tmp5;
	length libnm datanm varnm $32.;
	set tmp5;
	alltype=catx(";",of type:);
	drop type:;
run;

data tmp1;
	set tmp1;
	rowno=_n_;
	rename name=varnm;
run;

proc sort data=tmp1;
	by varnm;
run;

proc sort data=tmp5;
	by varnm;
run;

data tmp1;
	merge tmp1 tmp5;
	by varnm;

	if chartype="" then
		chartype="missing";
	label libname="library" memname="Data Name" varnm="Variable Name"
		alltype="Character Info";
run;

proc sort data=tmp1;
	by rowno;
run;

PROC EXPORT DATA= tmp1(drop=memtype rowno libnm datanm chartype)
	OUTFILE= "&filedir."
	DBMS=EXCEL REPLACE label;
	SHEET="charinfo";
RUN;

proc datasets noprint;
	delete tchar: tmp:;
run;

quit;

%mend;

- The “libname” is used to indicate the library name for the input dataset.
- The “datasets” is used to indicate the input SAS dataset names. If you don’t pass a value to it, the
macro will check all the data sets in the library.
- The “filedir” is used to indicate the file location you want

%checkCharVarType(libname=work,datasets=%str('sample1','sample2'),
filedir=%str(C:\charinfo.xlsx));
