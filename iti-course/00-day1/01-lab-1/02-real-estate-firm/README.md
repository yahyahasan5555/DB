# Lab Problem 2: Real Estate Firm (ERD)

## Entities

|Entity|Attributes|
|---|---|
|**Sales_Office**|**Office_Number** (PK), Location|
|**Employee**|**Employee_ID** (PK), Employee_Name|
|**Property**|**Property_ID** (PK), Location _(composite: Address, City, State, Zip_Code)_|
|**Owner**|**Owner_ID** (PK), Owner_Name|

## Relationships

|Relationship|Cardinality|Participation|Relationship attribute|
|---|---|---|---|
|Sales_Office **is assigned** Employee|1:M|Office: **total**, Employee: **total**|-|
|Sales_Office **is managed by** Employee|1:1|Office: **total**, Employee: partial|-|
|Sales_Office **lists** Property|1:M|Office: partial, Property: **total**|-|
|Owner **owns** Property|M:N|Owner: **total**, Property: partial|`Percent_owned`|

### Why each participation?

|Relationship|Reasoning (from the case)|
|---|---|
|Assigned (Office side)|"Each office is assigned **one or more** employees" -> total|
|Assigned (Employee side)|"An employee **must** be assigned to only one office" -> total|
|Managed by (Office side)|"there is **always** one employee assigned to manage that office" -> total|
|Managed by (Employee side)|Not every employee is a manager -> partial|
|Lists (Property side)|"Each property **must** be listed with one and only one office" -> total|
|Lists (Office side)|"may have no properties listed" -> partial|
|Owns (Owner side)|"An owner may own **one or more** properties" -> an owner owns at least one -> total|
|Owns (Property side)|"**zero** or more owners" -> partial|

## Assumptions

1. All IDs are unique (given), so they are the primary keys.
2. An employee manages **at most one** office (an employee belongs to only one office, so managing several offices is not expected). That makes **Managed by** 1:1.
3. `Percent_owned` belongs to the **relationship**, not to the owner or the property, because it depends on both.
