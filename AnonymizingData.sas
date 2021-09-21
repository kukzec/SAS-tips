* Create a dummy salt key table. Replace this in real use. Also, I had to
   break the hex value show here across multiple lines go get it to render
   properly in WordPress - it should all be one long string with no
   whitespace or line breaks;
data salt_keys;
 format salt_value $128.;
 
 salt_value = '9d91d63b23db252eb9ad7efe9a6e7120
               8c139aec1e721635e9ef8d39df7d5af5
               5e707ad54e03631f130d3f87ea62ac8b
               04209ed276317e12d17de3cf9578d1b9';
 is_current = 1;
 output;
run;
%let _INPUT=salt_keys;
 
* Get the current salt key from an input table.
 This is part of a feature of the application which
 allows the salt key to be changed every few months.;
proc sql noprint;
 select SALT_VALUE into :salt_key
 from &_INPUT.
 where IS_CURRENT = 1;
quit;
 
%let salt_key = %trim(&salt_key);
%put &salt_key; * DO NOT DO THIS IN REAL CODE!
                  The salt key should be kept secret!;
 
/* The %hash macro below is used in data step code later to hash
 several columns in each incoming data file, where those columns
 contain sensitive data. It creates and formats the hashed column,
 and also caluculates the value for that column for
 each row of the input dataset.
 
 Usage: to create a column called PHONE_NUMBER_HASHED,
 you would just insert the line:
 %hash(PHONE_NUMBER);
 into a datastep which had a column called PHONE_NUMBER. */
 
%macro hash(column=);
 format &column._HASHED $64.;
 retain &column._HASHED;
 
 &column._HASHED=%trim(put(sha256(cat("&salt_key.",strip(&column.))),hex64.));
%mend;
 

/* Usage example for the hash macro, hashing the 'name' column
   in the sashelp.class dataset. */
data class_anon;
 set sashelp.class;
 %hash(column=name);
run;
