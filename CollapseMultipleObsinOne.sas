

/* Collapse multiple lines in one single line (by variables) */

data have;
input FacilityID$      Contaminant$     ContA_conc     ContB_conc     ContC_conc     ContD_conc    ContE_conc ;
cards; 
1                      a                          10                    .                         .                          .                          .      
1                      c                           .                      .                          8                        .                           . 
2                      e                           .                       .                         .                         .                         50
3                      b                           .                      2                        .                         .                            .  
3                      d                           .                       .                          .                        12                          .  
4                      a                           75                   .                          .                           .                          . 
4                      b                            .                      5                        .                           .                           . 
4                      c                            .                      .                          1                         .                           .   
4                      d                            .                     .                            .                         25                        . 
4                      e                          .                       .                            .                           .                       40 
;

data want;
update have(obs=0) have;
by FacilityID;
run;

/* Note: It does keep the last contaminant instead of the first one. */
/* If needed, one can use the following */

data want;
   if 0 then set have;
   update have(obs=0 drop=Contaminant) have(drop=Contaminant);
   by FacilityID;
   if first.FacilityID then set have(keep=Contaminant) point=_n_;
run;
