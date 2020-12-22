%macro attrDiff(lib=, compare=tsl, msg=yes, out=); /* [U01] */
	/*Since we said run in open code in the header comment, we need to test it here.
	Branch to the last statement rather than the termination section. */

	/* ---------- Be sure we're running in open code ---------- */
	/* Knowledge of automatic macro variables makes open code test straightforward. */
	%if &sysprocname. NE %then
		%do;
			%put attrDiff-> Must run in open code. Execution terminating.;
			%goto lastStmt; /* <<<< <<< << < <<<< <<< << < <<<< <<< << < */
		%end;

	/* Begin initialization section */
	/* ---------- Housekeeping and initial messages ---------- */

	/* Take explicit control of variable scope. You can place the %LOCAL statement near the
	statements creating the variables. */
	%local opts star;

	/* Save initial option values before resetting. */
	%let opts = %sysfunc(getoption(mprint)) %sysfunc(getoption(notes));
	options nomprint nonotes;

	%if &msg. = NO %then
		%let star = *;

	/* Begin writing messages to Log. */
	%&star.put;
	%&star.put attrDiff-> Begin. Examine library [&lib.] compare [&compare.] create [&out.];

	/* Standardization of values makes evaluation easier later on (code is less cluttered due
	to lack of %upcase function references). */

	/* ---------- Upper case some parameters ---------- */
	/* Use built-in macro functions */
	%let lib = %upcase(&lib.);
	%let compare = %upcase(&compare.);
	%let msg = %upcase(&msg.);

	/* Create error flag OK. As we find problems, set OK to f and write a message. This lets
	us accumulate errors and report more than one problem at a time. */

	/* ---------- Check for parameter errors ---------- */

	/* Take explicit control of variable scope. You can place the %LOCAL statement near the
	statements creating the variables. */
	%local ok outLib;

	%if &lib. = %then
		%do;
			%let ok = f;
			%put attrDiff-> LIB cannot be null;
		%end;

	/* Use %sysfunc as much as possible to reduce code volume. */
	%else %if %sysfunc(libref(&lib.)) ^= 0 %then
		%do;
			%let ok = f;
			%put attrDiff-> Input LIBNAME [&lib.] not found.;
		%end;

	/* Reference to revision code [U01] */
	%if &out. = %then
		%do;
			/* [U01] */
			%let ok = f;
			%put attrDiff-> OUT cannot be null;
		%end;
	%else
		%do;
			%if %index(&out., .) %then
				%let outLIB = %upcase(%scan(&out., 1, .));
			%else %let outLIB = WORK;

			%if &outLIB. = &lib. %then
				%do;
					%let ok = f;
					%put attrDiff-> OUT and LIB libraries cannot be identical;
				%end;
			%else %if %sysfunc(libref(&outLIB.)) ^= 0 %then
				%do;
					%let ok = f;
					%put attrDiff-> Output LIBNAME [&outLIB.] not found.;
				%end;
		%end;

	%if &compare. = %then
		%do;
			%let ok = f;
			%put attrDiff-> COMPARE cannot be null;
		%end;
	%else %if %sysfunc(verify(&compare., TSL)) > 0 %then
		%do;
			%let ok = f;
			%put attrDiff-> COMPARE can only contain T, S, or L;
		%end;

	/* This is a simple way to avoid bulky macro coding. The alternative would have
	been: %if &msg. ^= NO & &msg. ^= YES %then %do; The benefit of this technique
	grows as the number of comparisons increases. */
	%if %sysfunc(indexW(NO YES, &msg.)) = 0 %then
		%do;
			%let ok = f;
			%put attrDiff-> MSG can only contain YES or NO. Found [&msg.];
		%end;

	/* Branch to termination and print message if we found any error conditions. */
	/* If anything was amiss, print a message and branch to bottom */
	%if &ok. = f %then
		%do;
			/*We keep the user informed about what's happening and why. */
			%put attrDiff-> Execution terminating due to error(s) noted above;
			%put attrDiff-> Output dataset [&out.] will NOT be created;

			/* Execution is forced to the termination section. This guarantees that any clean up
			that is required will, in fact, get done. We do not use %return or %abort! */
			%goto bottom; /* <<<< <<< << < <<<< <<< << < <<<< <<< << < <<<< <<< << < */
		%end;

	/* Initialization section is complete. Begin core processing. */
	/* ---------- Create SQL statement fragments based on COMPARE value ---------- */

	/* Take explicit control of variable scope. You can place the %LOCAL statement near the
	statements creating the variables. */
	%local sumOps tf sf lf;

	%if %index(&compare., T) %then
		%do;
			%let tf = type, count(distinct type) > 1 as typeFlag,;
			%let sumOps = , typeFlag;
		%end;

	%if %index(&compare., S) %then
		%do;
			%let sf = length, count(distinct length) > 1 as lengthFlag,;
			%let sumOps = &sumOps., lengthFlag;
		%end;

	%if %index(&compare., L) %then
		%do;
			%let lf = label, (count(distinct label) > 1 |
				(count(distinct label) = 1 & sum(missing(label) > 0)))
				as labelFlag;
			%let sumOps = &sumOps., labelFlag;
		%end;

	/* If this were a longer, more complicated program, we might have a %put statement saying
	"Step 1: read COLUMNS table, collect variable attributes"
	Since the core processing is basically just a single step, this message is probably not
	necessary. */
	proc sql noprint;
		/* Reference to revision code [U01] */
		create table &out. /* [U01] */
		as
			select &tf. &sf. &lf., upcase(name) as name, memname as dataSet
				/* Knowledge of SAS metadata (dictionary tables) makes creation of &OUT possible in
				a single statement. */
		from dictionary.columns
			where catt(libname, memType) = "&lib.DATA"
				group by name
					having sum(0 &sumOps.) > 0
						order by name, dataSet
		;
		%&star.put attrDiff-> &SQLobs. variables with mismatches.;
	quit;

	/* Code processing section is complete. Execution drops into termination section. */
%bottom:
	%&star.put attrDiff-> Done.;
	%&star.put;

	/* Only clean up required is setting some options to their original values.
	More complex macros might require deletion of temporary data sets, temporary
	global macro variables, etc. */

	/* ---------- Revert to orginal MPRINT and NOTES values ---------- */
	options &opts.;

%lastStmt:
%mend attrDiff;
