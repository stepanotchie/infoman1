# Task 2 – Relational Schema: ToolShare

- **Member**(<u>member_id</u>, member_name, phone, join_date)
- **Storage_location**(<u>location_code</u>, description)
- **Certification**(<u>cert_id</u>, cert_name)
- **Tool**(<u>tool_id</u>, tool_name, category, purchase_date, location_code [FK])
- **Borrowing**(<u>borrow_id</u>, member_id [FK], tool_id [FK], borrow_date, return_date)
- **Tool_Requirement**(<u>tool_id</u> [FK], <u>cert_id</u> [FK])
- **Member_Certification**(<u>member_id</u> [FK], <u>cert_id</u> [FK], completion_date)

Borrowing, Tool_Requirement and Member_Certification are the junction tables that resolve the three many-to-many relationships.