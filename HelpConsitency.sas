/* The “HelpConsistency“ macro[1]: Common tasks that we need to perform are merging or appending
SAS® data sets. During this process, we sometimes get error or warning messages saying that the same
fields in different SAS data sets have different lengths or different types. If the problems involve a lot of
fields and data sets, we need to spend a lot of time to identify those fields and write extra SAS codes to
solve the issues. However, if you use the macro “HelpConsistency“ in this paper, it can help you identify
the fields that have inconsistent data type or length issues. It also solves the length issues automatically
by finding the maximum field length among the current data sets and assigning that length to the field. An
html report is generated after running the macro that includes the information about which fields’ lengths
have been changed and which fields have inconsistent data type issues. */
%macro Help_Consistency(libnm=,datasets=%str());
	%let datasets=%sysfunc(upcase(&datasets.));

	proc sql noprint;
		*select all the variables from the data sets and save them in data set
		tmp1;
		%if &datasets.= %then
			%do;
				create table tmp1 as
					select libname,name,type,length,memname
						from dictionary.columns
							where libname=upcase("&libnm.") and memtype="DATA";
			%end;
		%else
			%do;
				create table tmp1 as
					select libname,name,type,length,memname
						from dictionary.columns
							where libname=upcase("&libnm.") and upcase(memname) in (&datasets.) and
								memtype="DATA";
			%end;

		*select all the variables that have different lengths for the same type;
		create table tmp2 as
			select * from tmp1 where name in
			(select distinct name from
			(select name,type,count(distinct length) as length_ct from tmp1
				group by name,type having calculated length_ct >1))
					and type ^="num" order by name,type,length,memname;

		*find the maximum length of a variable and save the result to tmp3;
		create table tmp3 as
			select t.*,max_length from tmp2 as t,(select name,type,max(length) as
				max_length from tmp2 group by name,type) as m
			where t.name=m.name and t.type=m.type and t.length ^=m.max_length;
	quit;

	*prepare the SAS codes to change the length to the maximum length;
	data tmp3;
		set tmp3;
		length codes $500.;
		codes=catx(" ","proc sql;alter table",cats(libname,".",memname),
			"modify",name,cats("char(",max_length,") format=$",max_length,".;quit;"));
	run;

	*execute the SAS codes to make the lengh consistent;
	data _null_;
		set tmp3;
		call execute(codes);
	run;

	*save the length change info to the data set tmp4;
	data tmp4;
		set tmp3;
		length comments $200.;
		comments=catx(" ","the length of data field '",name,"'
			in",libname,".",memname," has been changed from ",length,"to ",max_length);
		keep comments;
	run;

	proc sql;
		*find the varibles with different types;
		create table tmp5 as
			select * from tmp1 where name in
			(select distinct name from
			(select name,count(distinct type) as type_ct
				from tmp1 group by name
					having calculated type_ct >1))
						order by name,type,memname;
	quit;

	data tmp5;
		set tmp5;

		4
		dataset=cats(libname,".",memname);
		field_name=name;
		field_type=type;
		keep dataset--field_type;
	run;

	proc sort data=tmp5;
		by field_name dataset field_type;
		ods html;
		title "Data Fields that have different data types";

	proc print data=tmp5;
	run;

	title "Data Fields whose length have been modified";

	proc print data=tmp4;
	run;

	ods html close;
	ods listing;

	proc datasets;
		delete tmp1-tmp5;
	run;
	quit;
%mend;

/* You can use the following SAS codes to check the data length and data type inconsistencies among the 3
data sets: */
%help_consistency(libnm=work,datasets=%str('sample1','sample2','sample3'));
/* If you want to check all the data sets in a library, you don’t need to pass the values to the “datesets”
macro variable. For e.g, if you want to check all the data sets in the “work” library, you just need to call the
macro in this way: */
%help_consistency(libnm=work);
/* After running the macro, the macro will create an html report to summarize the field lengths that have
been changed and report the data type issues if there are any. See figure1 for a sample html report. */
