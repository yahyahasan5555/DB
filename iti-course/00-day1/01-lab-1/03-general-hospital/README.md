# Lab Problem 3: General Hospital (ERD)

## Entities

| Entity         | Attributes                                                          |
| -------------- | ------------------------------------------------------------------- |
| **Ward**       | **Ward_id** (PK), Name                                              |
| **Patient**    | **Patient_id** (PK), Name, Date_Of_Birth                            |
| **Consultant** | **Consultant_id** (PK), Name                                        |
| **Nurse**      | **Nurse_number** (PK), Name, Address                                |
| **Drug**       | **Drug_code** (PK), Recommended_dosage, Brand_name _(multi-valued)_ |

## Relationships

| Relationship                                            | Cardinality | Participation                           | Relationship attributes  |
| ------------------------------------------------------- | ----------- | --------------------------------------- | ------------------------ |
| Ward **hosts** Patient                                  | 1:M         | Ward: **total**, Patient: **total**     | -                        |
| Consultant **is assigned** Patient (leading consultant) | 1:M         | Consultant: partial, Patient: **total** | -                        |
| Consultant **examines** Patient                         | **M:N**     | Consultant: partial, Patient: partial   | -                        |
| Nurse **supervises** Ward                               | 1:1         | Nurse: partial, Ward: **total**         | -                        |
| Nurse **serves in** Ward                                | 1:M         | Nurse: **total**, Ward: partial         | -                        |
| Nurse **gives** Drug to Patient _(ternary)_             | M:N:N       | partial on all three                    | `Dosage`, `Date`, `Time` |

### Why each participation?

| Relationship    | Reasoning (from the case)                                                                                             |
| --------------- | --------------------------------------------------------------------------------------------------------------------- |
| Hosts           | "hosts **one or more** patients" -> Ward total. "hosted by **only one** ward" -> Patient total.                       |
| Assigned        | "assigned to **one** leading consultant" -> Patient total. "**zero** or more patients" -> Consultant partial.         |
| Examines        | "**may** be examined", "**zero** or more" -> partial on both sides.                                                   |
| Supervises      | "Each ward is under supervision of one nurse" -> Ward total. "a nurse **may** supervise" -> Nurse partial.            |
| Serves in       | "Each nurse **must** serve in one ward" -> Nurse total. Nothing forces a ward to have serving nurses -> Ward partial. |
| Gives (ternary) | The case never says that every nurse, patient or drug must appear in a drug record -> partial on all three.           |

## Assumptions

1. All IDs and numbers are unique, so they are the primary keys.
2. `Brand_name` is **multi-valued** (a drug has more than one brand name).
3. The **Examines** relationship is M:N: a patient may be examined by several consultants, and a consultant may examine several patients.
4. The drug record is a **ternary** relationship between Nurse, Patient and Drug. Its attributes are `Dosage` (the dosage actually given, which may differ from the drug's _recommended_ dosage), `Date` and `Time`.
5. Participation in the ternary relationship is partial on all sides (a new patient, drug or nurse may have no record yet).
6. A nurse who supervises a ward is assumed to serve in it, but the case does not state this, so no extra rule is drawn.
7. The case does not say whether a patient's leading consultant can also examine him, so no rule is added.

## Mistakes I Made

| #   | Mistake                                                                   | Why it is wrong                                                                                                                                                                                         |
| --- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | I forgot the `Dosage` attribute on the **gives** relationship             | The case says "with specified dosage". This is the dosage given each time, not the drug's recommended dosage, so it belongs to the relationship.                                                        |
| 2   | I linked particiedpation in the ternary to "who is allowed to give drugs" | Participation asks: **must every** nurse / patient / drug appear in at least one record? The case does not say so, so the answer is **partial**. Who is allowed to give a drug is a different question. |
| 3   | I said I did not know why **Ward** is partial in _Serves in_              | Rule: unless the case says **must / always / one or more**, assume **partial** and write it as an assumption.                                                                                           |
