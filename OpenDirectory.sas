data files;
    /* define a directory */
    rc = filename("dir", "&path.");
    /* open the directory */
    did = dopen("dir");
    /* check if it's opened */
    if did > 0 then do;
        /* itereate over objects in the directory */
        do n = 1 to dnum(did);
            /* read name of file */
            filename = dread(did, n);
            /* output files with *.LOG extension */
            if scan(upcase(filename), -1, '.') = 'LOG' then 
                output;
        end;
    end;
    /* close the directory */
    rc = dclose(did);

    drop rc did n;
run;
