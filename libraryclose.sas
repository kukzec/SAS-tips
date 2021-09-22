
/* ERROR :Unable to clear or re-assign the library DATA1 because it is still in use in SAS */
/* Try running it in a fresh session. 
Also ensure if you have it open in a viewer then it is closed. Ensure no other users or processes are using it. */
/* Sometimes code will error at some point and prevent the close() statement from running.
When this happens it is necessary to run the close() manually. 
While developing sometimes it is convenient just to clear any file handles you have open. */

/* You can use a macro like the one below to do so: */

%macro close_all_dsid;
  %local i rc;
  %do i=1 %to 1000;
    %let rc=%sysfunc(close(&i));
  %end;
%mend;
%close_all_dsid
