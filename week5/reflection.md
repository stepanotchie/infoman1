# Week 5 Reflection — Task 5

SELECT statements are safe to run freely because they only read data; they
never change what is stored in the database. A SELECT with a wrong filter
might return an empty or incorrect result set, but the tables themselves
stay untouched, and you can just fix the query and run it again. DDL
statements (CREATE, ALTER, DROP) and DML statements (INSERT, UPDATE, DELETE)
are different: they change the schema or the actual row data, and a mistake
can silently corrupt records, drop a table, or update far more rows than
intended, sometimes with no easy way back short of a backup.

For Task 4, I removed the quotes around the string literal in
`WHERE species = 'Cat'`, turning it into `WHERE species = Cat`. The actual
effect was not zero or wrong rows — it was a syntax-level failure:
`ERROR 1054 (42S22): Unknown column 'Cat' in 'where clause'`. MySQL parsed
the unquoted `Cat` as a column identifier rather than a string value, and
since `pet` has no such column, the query never executed. I diagnosed this
by running both versions side by side and checking the error code, which
confirmed 1054 specifically means "unknown column," not a data problem.