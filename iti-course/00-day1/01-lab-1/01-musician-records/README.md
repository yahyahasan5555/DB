# Lab Problem 1: Musicana Records (ERD)


## Entities

|Entity|Attributes|
|---|---|
|**Musician**|**Id** (PK), Name, Phone, Address _(composite: Street, City)_|
|**Instrument**|**Name** (PK), Musical_key|
|**Album**|**Album_id** (PK), Title _(alternate key)_, Copyright_date|
|**Song**|**Title** (PK), Author|

## Relationships

|Relationship|Cardinality|Participation|
|---|---|---|
|Musician **plays** Instrument|M:N|Musician: partial, Instrument: partial|
|Musician **performs** Song|M:N|Musician: partial, Song: **total**|
|Album **has** Song|1:M|Album: **total**, Song: **total**|
|Musician **produces** Album|1:M|Musician: partial, Album: **total**|

## Assumptions

1. I chose `Album_id` as the album's PK because comparing integers is simpler. `Title` is also unique, so it is an alternate key.