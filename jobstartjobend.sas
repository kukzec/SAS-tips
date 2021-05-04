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
		put note '| JOB ID : ' jobid 4.
			' |';
		put note '| DATE : '
			jobdate mmddyy. ' |';
		put note '| START TIME: '
			startyme time. ' |';
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
		put note '| FINISH TIME : '
			fintyme time. ' |';
		put note '| JOB DURATION: '
			durtyme time. ' |';
		put note '|' contour @35 '|';
		options notes source source2;
%mend jobend;
