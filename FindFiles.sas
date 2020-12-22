/* The “FindFiles” macro[4]: The “FindFiles” macro can help users find and access their folders and files
very easily. By providing a path to the macro and letting the macro know which folders and files you are
looking for under this path, the macro creates an HTML report that lists the matched folders and files. The
best part of this HTML report is that it also creates a hyperlink for each folder and file so that when a user
clicks the hyperlink, it directly opens the folder or file. Users can also ask the macro to find certain folders
or files by providing part of the folder or file name as the search criterion. The results shown in the report
can be sorted in different ways so that it can further help users quickly find and access their folders and
files. */

%macro FindFiles(dirnm=,outhtml=,filetype=%str(),sortvars=%str(),
			browser_type=iexplore);
	filename DIRLIST pipe "dir /-c /q /s /t:w ""&dirnm""";

	data tmp1;
		length path filename $255 line $1024 owner $17 temp $16;
		retain path;
		infile DIRLIST length=reclen;
		input line $varying1024. reclen;

		if reclen = 0 then
			delete;

		if scan(line,1," ")='Volume' or scan(line,1," ")='Total' or
			scan(line,2," ")='File(s)' or scan(line,2," ")='Dir(s)' then
			delete;
		dir_rec=upcase(scan(line,1," "))='DIRECTORY';

		if dir_rec then
			path=left(substr(line,length("Directory of")+2));
		else
			do;
				date=input(scan(line,1," "),mmddyy10.);
				time=input(scan(line,2," "),time5.);
				post_meridian=(scan(line,3," ")='PM');

				if post_meridian then
					time=time+'12:00:00'T;
				temp = scan(line,4," ");

				if temp='<DIR>' then
					size=0;
				else size=input(temp,best.);
				owner=scan(line,5," ");
				filename=scan(line,6," ");

				if filename in ('.' '..') then
					delete;
				ndx=index(line,scan(filename,1));
				filename=substr(line,ndx);
			end;
	run;

	data tmp2;
		set tmp1;
		length Type $20.;

		if index(filename,".")=0 then
			Type="Folder";
		else Type=propcase(scan(filename,2,"."));

		if filename ^="" then
			src=cats(path,"\",filename);
		else src=path;
		location=cats("<a href='",src,"'>",src,"</a><br>");
		date_modified=catx(" ",put(date,yymmdd10.),put(time,time5.));

		%if &filetype NE %str() %then
			%do;
				if index(upcase(filename),upcase("&filetype."))>0 or index(upcase(type),upcase("&filetype."))>0;
			%end;

		keep Type location date_modified;
		label location="Location" date_modified="Date Modified";
	run;

	data tmp2;
		set tmp2;

		if index(lowcase(location),"service")>0 then
			delete;
	run;

	proc sort data=tmp2 nodupkey;
		by Location;
	run;

	%if &sortvars NE %str() %then
		%do;

			proc sort data=tmp2;
				by &sortvars.;
			run;

		%end;

	ods html file="&outhtml.";

	proc print data=tmp2 noobs label;
	run;

	ods html close;
	options NOXWAIT NOXSYNC;

	%if &browser_type.=iexplore %then
		%do;
			x "start iexplore &outhtml.";
		%end;
	%else %if &browser_type.=chrome %then
		%do;
			%let newhtml=%sysfunc(tranwrd(&outhtml.,\,//));
			x "start &browser_type. file://&newhtml.";
		%end;
%mend;

*/ - The “dirnm” is used to indicate the directory you want the macro to search for files and folders.
- The “outhtml” is used to indicate the location and the filename for the output html report.
- The “filetype” is used to indicate the type of the files you want to find, you can pass any values that
are available for the column “Type” on the output html report. For e.g, if you want to find the folders,
you can pass “folder” to the “filetype” parameter. The parameter “filetype” value is case-insensitive.
By default, if you don’t pass any value to it, it will list all the folders and files.
- The “Sortvars” is used to indicate how you want to sort your results. To sort the results by column
“Type”, pass “type” value to the macro variable “Sortvars”. To sort the results by column “Location”,
pass “location” value to the macro variable “Sortvars”. To sort the results by column “Date Modified”,
pass “date_modified” value to the macro variable “Sortvars”. For example, if you want to sort the
results by type and descending modified date, you can pass “type descending modified_date” to the
“sortvars” macro parameter. By default, if you don’t pass any value to it, it will sort the results by
location.
- The “browser_type” is used to indicate which browser you want to use to open your html report. By
default, it will use the internet explorer to open the report. You can also pass “chrome” to it to open
the file in Google Chrome. /*
/* Below are some examples showing you how to call the macro to find different files and sort the results. */
	/* - 1. To Find all the files and folders inside the “C:\generate_html” folder and sort the results by type
and descending modified date. The result will be saved into the “result.html” file on the C: drive.
and Google Chrome will be used to open the report. You can call the macro in this way: */
%Findfiles(dirnm=%str(C:\generate_html),sortvars=%str(type descending date_modified),outhtml=%str(C:\result.html),browser_type=chrome);
	/* - 2. To find all the html files inside the “C:\generate_html” folder and sort the results by location and
type. The result will be saved into the “C:\result.html” file and the file will be opened by internet
explorer by default. You can call the macro in this way: */
%Findfiles(dirnm=%str(C:\generate_html),filetype=%str(.html),sortvars=%
str(loca tion type),outhtml=%str(C:\result.html));
	/* - 3. To find the “test.pdf” file inside the “C:\generate_html” folder, you can call the macro in this way: */
%Findfiles(dirnm=%str(C:\generate_html),filetype=%str(test.pdf),
outhtml=%str(C:\result.html));
	/* - 4. To find the folders inside the “C:\generate_html” folder, you can call the macro in this way: */
%Findfiles(dirnm=%str(C:\generate_html),filetype=%str(folder),
outhtml=%str(C:\result.html));
