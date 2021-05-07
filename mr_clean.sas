https://blogs.sas.com/content/sgf/2018/07/17/delete-sas-logs-admin/

%macro mr_clean(dirpath=,dayskeep=30,ext=.log);
   data _null_;
      length memname $256;
      deldate = today() - &dayskeep;
      rc = filename('indir',"&dirpath");
      did = dopen('indir');
      if did then
      do i=1 to dnum(did);
         memname = dread(did,i);
         if reverse(trim(memname)) ^=: reverse("&ext") then continue;
         rc = filename('inmem',"&dirpath/"!!memname);
         fid = fopen('inmem');
         if fid then 
         do;
            moddate = input(finfo(fid,'Last Modified'),date9.); /* see WARNING below */
            rc = fclose(fid);
            if . < moddate <= deldate then rc = fdelete('inmem');
         end;
      end; 
      rc = dclose(did);
      rc = filename('inmem');
      rc = filename('indir');
   run;
%mend mr_clean;
