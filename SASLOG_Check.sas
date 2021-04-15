%let saslog_dir = C:\Users\Desktop\path\;
%let report_dir = C:\Users\Desktop\path\;

%macro SASLOG_Check(saslog_dir=, report_dir=);
	data dirlist;
	    rc = filename("dir", "&saslog_dir.");
	    did = dopen("dir");
	    if did > 0 then do;
	        do n = 1 to dnum(did);
	            filename = dread(did, n);
	            if scan(upcase(filename), -1, '.') = 'LOG' then 
	                output;
	        end;
	    end;
	    rc = dclose(did);
	    drop rc did n;
	run;

	proc format;
	value ErrType 1 = 'ERROR'
				  2 = 'WARNING'
				  3 = 'Spec. NOTEs'
				  4 = 'NOTE';
	run;

	proc sql noprint;
		select count(distinct filename), filename
		into :filenum, :filename separated by " "
		from dirlist;
	quit;

	%put &filename. &filenum.;

	%do i=1 %to &filenum.;
		%let fname=%scan(%scan(&filename, &i., %str( )), 1, %str(.log));

		filename infl "&saslog_dir.&fname..log";
		options ls=80 ps=50 nodate nonumber;

		data temp_&fname.(keep= filename type text line_counter);
			filename="&fname..log";
			retain line_counter 0;
			length text $ 190;
			infile infl lrecl=200 pad;
			input @1 log $200.;
			line_counter + 1;

			if index(log, 'ERROR:')>0 then
				do;
					type = 1;
					pos = index(log, '2E0D'X);
					text = substr(log, 8, pos - 8);
					output;
				end;
			else if index(log, 'WARNING:')>0 then
				do;
					type = 2;
					text = substr(log, 10);
					output;
				end;
			else if index(log, 'NOTE:')>0 then
				do;
					if index(log, 'The data set')>0 and
						index(log, 'has 0 observations')>0 then
						do;
							type = 3;
							text = substr(log, 6);
							output;
						end;
				end;

			if index(log, 'NOTE:')>0 then
				do;
					if index(log, 'Invalid') > 0 or
						index(log, 'W.D format') > 0 or
						index(log, 'is uninitialized') > 0 or
						index(log, 'repeats of BY values') > 0 or
						index(log, 'Mathematical operations could not') > 0 or
						index(log, 'Missing values were') > 0 or
						index(log, 'Division by zero') > 0 or
						index(log, 'MERGE statement') > 0 or
						index(log, 'Character values have') > 0 or
						index(log, 'values have been converted') > 0 or
						index(log, 'Interactivity disabled with') > 0 or
						index(log, 'No observation') > 0 then
						do;
							type = 4;
							text = substr(log, 7);
							output;
						end;
				end;
		run;

		proc sort data=temp_&fname.;
			by type line_counter;
		run;
	%end;

	data summary;
		set temp_:;
	run;

	ods html file="&report_dir.\SASLOG_Summarizer.html";

	proc report data=summary nowindows split='~';
		title J=C "Report from SASLOG Check for:";
		title2 J=C "&filename.";
		column  filename type line_counter text;
		define filename / group order=internal 'Filename';
		define type / group order=internal f=ErrType. 'Type';
		define line_counter / display f=6. 'Line # in~SAS LOG';
		define text / display width=80 /*f=$90.*/
		flow 'Original SAS Log message';
	run;

	ods html close;
%mend SASLOG_Check;

%SASLOG_Check(saslog_dir=&saslog_dir., report_dir=&report_dir.);
