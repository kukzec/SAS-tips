/* The “ExportExcelWithFormat” macro[3]: When using SAS to export data to excel, the formats got lost.
In this paper, we introduce the macro ““ExportExcelWithFormat” that can help you to export formatted
SAS data to excel files without losing the formats. The advantage of this macro is that it only requires you
to provide the input data set and the location and the name of the output excel file, it will then create the
excel file that preserves all the formats in the SAS data set for you. */


%macro ExportExcelWithFormat(libname=,dataname=,outputname=,sheetname=);

	proc sql noprint;
		create table tmp_vars as select name,format 
			from dictionary.columns where libname=upcase("&libname.") and
				memname=upcase("&dataname.");
	quit;

	data tmp_vars;
		set tmp_vars end=last;
		length formatcode $400.;

		if format ^="" then
			formatcode=catx(" ",cats("put","(",name,",",format,")"), "as",name,",");
		else formatcode=cats(name,",");

		if last then
			formatcode=substr(formatcode,1,length(formatcode)-1);
	run;

	%let formatcodes=;

	data _null_;
		set tmp_vars;
		call symput('formatcodes', trim(resolve('&formatcodes.')||' '||trim
			(formatcode)));
	run;

	proc sql;
		create view tmp_view as select &formatcodes. from &libname..&dataname.;
	quit;

	%let formatcodes=%str();

	PROC EXPORT DATA= tmp_view OUTFILE= "&outputname." DBMS=EXCEL REPLACE;
		SHEET="&sheetname.";
	RUN;

	proc sql;
		drop table tmp_vars;
		drop view tmp_view;
	quit;

%mend;

/* You can call the macro like this: */
%exportExcelWithFormat(libname=work,dataname=test,outputname=%str(C:\test.x
lsx), sheetname=sheet1);
