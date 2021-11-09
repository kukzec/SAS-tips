/* To put at the beginning of the first program of the project */

%macro jobstart;
	options nonotes nosource nosource2;

	%global s_t_a_rt d_a_t_e;

	data _null_;
		startyme = time();
		length jobid $4;
		startymc = put(startyme, 5.);
		jobid = startymc;
		jobdate = date();
		stardate = put(jobdate, 10.);
		contour = '~~~~~~~~~~~~~~~~~~~~~~';
		note = '%JOBSTART: ';
		put note '|' contour @35 '|';
		put note '| JOB ID : ^' jobid 4.
			'^ |';
		put note '| DATE : ^'
			jobdate mmddyy. '^ |';
		put note '| START TIME: ^'
			startyme time. '^ |';
		put note '|' contour @35 '|';
		call symput ('s_t_a_rt', startymc);
		call symput ('d_a_t_e', stardate);
	run;

	options notes source source2;
%mend jobstart;

%macro jobend (sendto=);
	options nonotes nosource nosource2;

	/* %jobstart must be run before. */
	data _null_;
		fintyme = time();
		durtyme = fintyme - &s_t_a_rt;

		/* if job spans days, add */
		/* 86400 seconds per day */
		/* correct the duration */
		findate = date();
		numdays = findate - &d_a_t_e;

		if durtyme < 0 then
			durtyme = durtyme + numdays * 86400;
		contour = '~~~~~~~~~~~~~~~~~~~~~~~~';
		note = '%JOBEND: ';
		put note '|' contour @35 '|';
		put note '| FINISH TIME : ^'
			fintyme time. '^ |';
		put note '| JOB DURATION: ^'
			durtyme time. '^ |';
		put note '|' contour @35 '|';
		options notes source source2;
%mend jobend;
		
%macro setlogfile(projectname);
	%let i = 1;
	%let logfile = F:\SAS_Content\SUBA_User\Published\SAS_Scheduler\Logs\&projectname._%sysfunc(inputn(&sysdate9.,date9.),yymmddd10.)_&i..log;
	%do %while(%sysfunc(fileexist(&logfile)));
		%let i = %eval(&i+1);
		%let logfile = F:\SAS_Content\SUBA_Admin\Workspace\SAS_Scheduler\Logs\&projectname._%sysfunc(inputn(&sysdate9.,date9.),yymmddd10.)_&i..log;
	%end;
	%put INFO: &=logfile;
	filename tmp "&logfile.";
	proc printto log = tmp new; 
	run;
	%jobstart;
%mend;

/* to put at the end of the last program of the project */

%macro endlogfile();
	%jobend;
	proc printto;run;
	data _null_;
	  infile tmp;
	  input;
	  putlog "*>" _infile_;
	run;
	filename tmp clear;	
%mend;


/* SAS Macro to parse the log file */


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
