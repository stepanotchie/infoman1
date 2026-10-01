# Prelim Lab Answers – ToolShare

## Task 3 – Data Type Justifications

1. **`phone` is `VARCHAR(20)`, not `INT`.** A phone number is an identifier, not a quantity, so we never do arithmetic on it. An integer would drop leading zeros (`0917...` becomes `917...`) and cannot hold `+63`, dashes or spaces.
2. **`return_date` is `DATE NULL`.** NULL is meaningful: it means the tool is still on loan, and it can be tested with `IS NULL`. Using a fake date such as `'0000-00-00'` would break date comparisons and hide the "on loan" state.
3. **`location_code` is `VARCHAR(10)` and used directly as the primary key (natural key).** Codes like `Shelf A3` or `Pegboard B1` are short, unique and already meaningful to staff, so a surrogate `INT` would add a column and force a join just to read where a tool is. The same type and length are used in `tool.location_code`, because a foreign key must match its parent column's type exactly.
4. **`purchase_date`, `join_date`, `borrow_date`, `return_date` and `completion_date` are `DATE`, not `DATETIME`.** The spec only records the day, so storing a time of day would add meaningless precision and make equality checks such as `= '2025-09-12'` fail unexpectedly.

## Task 3 – Foreign Key Enforcement

Foreign keys use `InnoDB`, which enforces them. Inserting a tool with a storage location that does not exist is rejected (see the end of `task3_describe_output.txt`):

    ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails

## Business Rule Not Enforced by Keys

The spec says a member cannot borrow a tool that requires a certification they have not completed. Primary and foreign keys cannot express this, because it depends on data across `borrowing`, `tool_requirement` and `member_certification`. In a real system it would be enforced with a `BEFORE INSERT` trigger on `borrowing` or in application logic. The schema stores the data needed to check it, but does not enforce it on its own.

## Task 5 – Debug

**Original (broken) query:**

    SELECT borrow_date, return_date
    FROM borrowing
    WHERE member_name = 'Maria Santos';

**Error produced:**

    ERROR 1054 (42S22): Unknown column 'member_name' in 'where clause'

**Why it fails:** the `borrowing` table has no `member_name` column.
- **Week 3 (relational schema):** `Borrowing` is a junction table that resolves the Member–Tool many-to-many relationship. It stores only the foreign key `member_id`, and the member's name lives in `Member`. Storing the name in both places would duplicate data and risk inconsistency.
- **Week 4 (DDL):** `CREATE TABLE borrowing` defines only `borrow_id`, `member_id`, `tool_id`, `borrow_date` and `return_date`, so MySQL has no such column to filter on.

**Corrected queries (single-table, run in order):**

Step 1 – find the member ID in `member`:

    SELECT member_id FROM member WHERE member_name = 'Maria Santos';

    +-----------+
    | member_id |
    +-----------+
    |         1 |
    +-----------+

Step 2 – filter `borrowing` on that ID:

    SELECT borrow_date, return_date FROM borrowing WHERE member_id = 1;

    +-------------+-------------+
    | borrow_date | return_date |
    +-------------+-------------+
    | 2025-09-01  | 2025-09-10  |
    | 2025-09-12  | NULL        |
    +-------------+-------------+

The second row has a NULL `return_date`, so that tool is still on loan. This matches Task 4 Q3 and Q4.

**Caveat:** `member_name` is not unique, so step 1 could return several IDs if two members share a name. In that case step 2 must be run for each ID, or the person identified by another column such as `phone`.

**Week 5 concepts illustrated:**
- `WHERE` can only filter on columns of the table named in `FROM`. A column that lives in another table is not visible to it.
- Without a JOIN (not used in this task), the workaround is to look up the key in one table and then filter the other table with it. This shows how the primary key / foreign key link from Week 3 is what connects the two queries. A single `JOIN` on `member_id` would do it in one step.