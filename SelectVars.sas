/* The “SelectVars” macro[2]: Often we need to select a subset of variables from a dataset. SAS®
software has provided the “SAS variable list” from which we can select the variables without typing their
names individually. However, the “SAS variable list” cannot be used in all SAS procedures, such as the
SELECT statement in the SQL procedure. Also, there is no “SAS variable list” available to select
variables that share a common suffix or middle part in their names. In this paper, the ““SelectVars” macro
is introduced that not only incorporates the “SAS variable list” to select a subset of variables, but also can
be used to select variables that share common patterns in their names. Additionally, the results from the
macro can be applied to all SAS procedures. */


%macro SelectVars(libname=,datanm=,range=_ALL_,pattern=%,separateby=%str());
	data tmp;
		set &libname..&datanm.;
	run;

	%if "&range." ^=%str() %then
		%do;

			data tmp;
				set tmp;
				keep &range.;
			run;

		%end;

	%global lstVars;
	%let lstVars=%str();

	*reset the macro variable lstVars;
	proc sql noprint;
		select name into :lstVars separated by "&separateby."
			from dictionary.columns where libname="WORK" and
				memname = upcase("tmp") and name like "&pattern." escape '#';
		drop table tmp;
	quit;

%mend;

/* - The macro parameter “libname” is used to identify the library name for the dataset from which you
want to select the variables.
- The macro parameter “datanm” is used to identify the dataset name from which you want to select the
variables.
- The macro parameter “range” is used to identify the range in the dataset from which you want to
select the variables. The values that are accepted by the “range” parameter are those that you can
use for the “SAS variable list”.
Examples of acceptable “range” parameter values:
	- 1. To select the variables a1, a2, a3, simply pass “a1-a3” to the parameter “range”
	- 2. To select the variables from a1 to b2 based on the variable order in the dataset, simply pass “a1--
b2” to the parameter “range” 
	- 3. To select the numerical variables from a1 to b2, simply pass a1-numeric-b2 to the parameter
		 “range”
	- 4. To select variables whose name is prefixed with “a,” simply pass “a:” to the parameter “range”
	- 5. Likewise, the keywords “_CHARACTER_”, “_NUMERICAL_”, “_ALL_” could also be passed to the
		 parameter “range”.

By default, the value for the “range” parameter is _ALL_, if you want to define the variable range as
all the variables, you don’t need to pass a value to the “range” parameter.
- The macro parameter “patterns” is used to identify the naming patterns of the variables you want to
select. In this paper, we use the “like” condition and the wildcard characters “%” and “_” in PROC SQL
to help us identify the naming patterns. The wildcard character “_” could be used as a substitute for a
single character, and the wildcard character “%” could be used as a substitute for zero or more
characters.

The sample code below illustrates how to use the wildcard characters. In this example, we want to
select those variables whose names have the suffix “_abc” from the dataset “test” saved in the “work”
library.
proc sql;
select name from dictionary.columns
where libname= upcase("work") and memname = upcase("test") and
name like "%#_abc" escape '#';
quit;
The “escape” clause is used to search for literal instances of the percent (%) and underscore (_)
characters, which are usually used for pattern matching. SAS® allows for variable names beginning
with “_,” and it happens that “_” is a wildcard character. Thus, to select variables that contain the “_” in
their names, we could use an ESCAPE character and add this ESCAPE character before the “_” to tell
SAS® the “_” is not a wildcard character. In the above syntax, the “#” is used as the ESCAPE
character.
Suppose you want to select those variables whose names start with an “a,” followed by a character,
then followed by “_123” in the middle, and end with “b.” To accomplish this, you could pass
“a_#_123%b” to the parameter “pattern.”
The default value for the “pattern” parameter is %, which means to select all the patterns. If you want
to select all the patterns, you don’t need to pass a value to the “pattern” parameter.
- The macro parameter “separateby” instructs SAS® to separate the selected variables by a space or by
a comma. By default, the variables are separated by a space. If you want to separate by comma, you
could pass “%str(,)” to the “separateby.” */
