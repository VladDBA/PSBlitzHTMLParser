IF OBJECT_ID(N'dbo.BlitzIndexFindings', N'U') IS NULL
  BEGIN
      CREATE TABLE [BlitzIndexFindings]
        (
           [Priority]         SMALLINT,
           [Finding]          VARCHAR(500),
           [URL]              NVARCHAR(500),
           [SanitizedFInding] VARCHAR(500),
           [Description]      NVARCHAR(MAX)
        );
  END; 

INSERT INTO
BlitzIndexFindings ([Priority], [Finding], [URL], [SanitizedFInding], [Description])
VALUES

(20, 'Multiple Index Personalities: Duplicate keys', N'https://www.brentozar.com/go/duplicateindex','Duplicate keys','
NonClustered indexes are very powerful in SQL Server. You want to have the right nonclustered indexes in place to help support queries reading table and make them faster - that has a lot of benefits, like reducing IO, CPU, and memory usage.
But on the flip side, you can easily have too much of a good thing. Duplicate indexes take up double the room in SQL Server - and even if indexes are COMPLETELY identical, SQL Server may choose to use both of them.
Duplicate indexes essentially cost you extra IO, CPU, and Memory, just the things you were trying to SAVE by adding nonclustered indexes! And that''s a little bit crazy.

Duplicate keys
Indexes diagnosed with duplicate keys have exactly that: completely duplicate keys. (Not sure what keys are? Watch How to Think Like the Engine.)

Duplicate keys are a red flag, but don''t jump into action too soon. Although indexes may have duplicate keys, there are important things to be aware about.

- Are the duplicates both nonclustered?
You may have a case where one of your duplicates is the clustered index - and that means that index is the data in the table itself. You clearly wouldn''t want to go dropping that index unless you want to lose the whole table.
You can identify a clustered index easily - it is always index id 1, and the index_definition column will contain a "[CX]". For example this index is a clustered index and a primary key: [CX] [PK] [KEYS]  BusinessEntityID
There are rare cases where it is useful to have a duplicate nonclustered index on the same column as the clustering key, but this is the exception rather than the rule.)
- Is one of the duplicates serving as a primary key? One of your duplicates may be a primary key, in which case it is also likely worthy of special treatment. If an index is a primary key, the index_definition column will contain a "[PK]" (check out the example above).
- Do the indexes have different included columns?  Included columns are listed in the index_definition column. They are prefixed by the term [INCLUDES]
- How much is each index being used?  Find this from the index_usage_summary column. Even if the indexes are completely identical, SQL Server may choose to use them both and you may see usage on them. If they have different included columns, you may see a very big variation in index usage, however.
Remember, index tuning is complicated! sp_BlitzIndex gives you a lot of information to help you see everything at once, but it''s up to you to decide the right thing to do.

If you''re not sure about the right course of action, step back and learn more. Don''t put together a change plan to move forward until you''re certain about the choices you''re making.'),

(30, 'Multiple Index Personalities: Borderline duplicate keys', N'https://www.brentozar.com/go/duplicateindex', 'Approximate duplicate keys','
Approximate duplicate keys start with the same key column, but do not have completely identical keys.
In many cases, indexes with borderline duplicate keys are very easy to combine into a single index. However, before you assume this is the right course of action, look closely at the index types and usage as we describe above. It may change your decisions.'),

(70, 'Aggressive Under-Indexing: Total lock wait time > 5 minutes (row + page)', N'https://www.brentozar.com/go/AggressiveIndexes', 'Potential Under-Indexing: Total lock wait time > 5 minutes (row + page)', '
If you''re diagnosed with this, check the details column returned by sp_BlitzIndex - for information on how many lock waits have been happening, what type they were, and the total and average duration.
When you see these waits, you should look at the table in more detail. Are there missing indexes that may be causing scans of the clustered index, and that''s where the blocking is?'),

(70, 'Aggressive Indexes: Total lock wait time > 5 minutes (row + page)', N'https://www.brentozar.com/go/AggressiveIndexes','Total lock wait time > 5 minutes (row + page)','
If you''re diagnosed with this, check the details column returned by sp_BlitzIndex - for information on how many lock waits have been happening, what type they were, and the total and average duration.
When you see these waits, you should look at the table in more detail. Are there missing indexes that may be causing scans of the clustered index, and that''s where the blocking is?'),

(70, 'Aggressive Over-Indexing: Total lock wait time > 5 minutes (row + page)', N'https://www.brentozar.com/go/AggressiveIndexes','Potential Over-Indexing: Total lock wait time > 5 minutes (row + page)' ,'
If you''re diagnosed with this, check the details column returned by sp_BlitzIndex - for information on how many lock waits have been happening, what type they were, and the total and average duration.
When you see these waits, you should look at the table in more detail. Are there missing indexes that may be causing scans of the clustered index, and that''s where the blocking is?'),

(10, 'Index Hoarder: Many NC Indexes on a Single Table', N'https://www.brentozar.com/go/IndexHoarder','Many NC Indexes on a Single Table','
There are lots of special cases in index configuration. We look for signs of over-inflated indexes that are indicative of a larger pattern. You take these indicators and use deeper analysis to find out if it really is a problem.
How many nonclustered indexes is too many indexes? This varies by database usage and design, so we had to draw an arbitrary number in the sand.
If you get this diagnosis, you have a table that has 10 or more nonclustered indexes on it. 10 is very likely too many indexes for read-write tables in most databases.'),

(10, 'Index Hoarder: Unused NC Index with High Writes', N'https://www.brentozar.com/go/IndexHoarder','Unused NC Index with High Writes','
There are lots of special cases in index configuration. We look for signs of over-inflated indexes that are indicative of a larger pattern. You take these indicators and use deeper analysis to find out if it really is a problem.
How many nonclustered indexes is too many indexes? This varies by database usage and design, so we had to draw an arbitrary number in the sand.
If you get this diagnosis, you have a table that has 10 or more nonclustered indexes on it. 10 is very likely too many indexes for read-write tables in most databases.'),

(80, 'Abnormal Psychology: Filter Columns Not In Index Definition', N'https://www.brentozar.com/go/IndexFeatures','Filter Columns Not In Index Definition','
When you create a filtered index, it''s important that the columns in the filter definition make it into the index definition. 
If you don''t, the optimizer may skip using them for queries where they could be really useful.'),

(100, 'Self Loathing Indexes: Low Fill Factor on Nonclustered Index', N'https://www.brentozar.com/go/SelfLoathing','Low Fill Factor on Nonclustered Index', '
We look for any index where the fill factor is 80% or less. Fill factor is a measure of how full SQL Server fills index pages. 
If fill factor is at 75%, then when SQL Server rebuilds an index it''s going to write out all those beautiful, clean pages and leave 25% free on each and every page.

There''s no single "right" setting for fill factor. On many indexes, 80% is fine.

However, people frequently make the mistake of setting fill factor to low values like 80% across the board - even on indexes that do not fragment frequently. 
The best practice is to ONLY use a low fill factor on indexes where you know you need it. Setting a low fill factor on too many indexes will hurt your performance:
- Wasted space in storage
- Wasted space in memory (and therefore greater memory churn)
- More IO, and with it higher CPU usage

Review all indexes diagnosed with low fillfactor. Check how much they''re written to. Look at the keys and determine whether insert and update patterns are likely to cause page splits.
[Learn more about fillfactor and best practices her](https://www.brentozar.com/archive/2013/04/five-things-about-fillfactor/)'),
(100, 'Self Loathing Indexes: Low Fill Factor on Clustered Index', N'https://www.brentozar.com/go/SelfLoathing','Low Fill Factor on Clustered Index', '
We look for any index where the fill factor is 80% or less. Fill factor is a measure of how full SQL Server fills index pages. 
If fill factor is at 75%, then when SQL Server rebuilds an index it''s going to write out all those beautiful, clean pages and leave 25% free on each and every page.

There''s no single "right" setting for fill factor. On many indexes, 80% is fine.

However, people frequently make the mistake of setting fill factor to low values like 80% across the board - even on indexes that do not fragment frequently. 
The best practice is to ONLY use a low fill factor on indexes where you know you need it. Setting a low fill factor on too many indexes will hurt your performance:
- Wasted space in storage
- Wasted space in memory (and therefore greater memory churn)
- More IO, and with it higher CPU usage

Review all indexes diagnosed with low fillfactor. Check how much they''re written to. Look at the keys and determine whether insert and update patterns are likely to cause page splits.
[Learn more about fillfactor and best practices her](https://www.brentozar.com/archive/2013/04/five-things-about-fillfactor/)'),
(100, 'Self Loathing Indexes: Heaps with Forwarded Fetches', N'https://www.brentozar.com/go/SelfLoathing','Heaps with Forwarded Fetches', '
Imagine I''m updating a variable length field from something very short to something very long. There''s not enough room on the page holding that row for the new value. 
In a heap, that row gets moved off to a new page and a "forwarding record pointer" is left in its place. 
Every time I need to read that row, I have to go to its original address and then follow the forwarding record pointer to the new address. 
Over time, lots of forwarded records create lots of random IO - and reads become both resource-intensive and time-intensive

The short-term solution for this is to rebuild the heaps more often. 
Note that [Ola Hallengren''s Maintenance Solution](https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html) does not rebuild heaps, so you''ll have to address those separately.
Just be aware that when you rebuild heaps, it''s a logged operation, and can slow things down while you work. 
Only rebuild heaps while keeping a close eye on other activity on the server, doing frequent log backups as necessary.

The long-term solution is to look into turning these heaps into clustered indexes.
The rule of thumb for SQL Server is to always create a clustered index on a table unless you can prove there is a performance improvement for you application by using a heap. 
(If you can prove there''s a benefit, that''s great! Use it! But you''re the exception, not the norm.)'),

(100, 'Self Loathing Indexes: Large Active Heap', N'https://www.brentozar.com/go/SelfLoathing','Active Heap(s)', '
This diagnosis is for active heaps - they''re being read from or written to - but they haven''t had forwarded records read or deletes occur since restart.

If you''ve got active heaps, give them a close look. 

Active heaps tend to lead to forwarded fetches and/or captive pages bogging down your queries and hogging resources.

The short-term solution for this is to rebuild the heaps more often. 
Note that [Ola Hallengren''s Maintenance Solution](https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html) does not rebuild heaps, so you''ll have to address those separately.
Just be aware that when you rebuild heaps, it''s a logged operation, and can slow things down while you work. 
Only rebuild heapss while keeping a close eye on other activity on the server, doing frequent log backups as necessary.

The long-term solution is to look into turning these heaps into clustered indexes.
The rule of thumb for SQL Server is to always create a clustered index on a table unless you can prove there is a performance improvement for you application by using a heap. 
(If you can prove there''s a benefit, that''s great! Use it! But you''re the exception, not the norm.)'),

(100, 'Self Loathing Indexes: Medium Active Heap',N'https://www.brentozar.com/go/SelfLoathing','Active Heap(s)', '
This diagnosis is for active heaps - they''re being read from or written to - but they haven''t had forwarded records read or deletes occur since restart.

If you''ve got active heaps, give them a close look. 

Active heaps tend to lead to forwarded fetches and/or captive pages bogging down your queries and hogging resources.

The short-term solution for this is to rebuild the heaps more often. 
Note that [Ola Hallengren''s Maintenance Solution](https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html) does not rebuild heaps, so you''ll have to address those separately.
Just be aware that when you rebuild heaps, it''s a logged operation, and can slow things down while you work. 
Only rebuild heapss while keeping a close eye on other activity on the server, doing frequent log backups as necessary.

The long-term solution is to look into turning these heaps into clustered indexes.
The rule of thumb for SQL Server is to always create a clustered index on a table unless you can prove there is a performance improvement for you application by using a heap. 
(If you can prove there''s a benefit, that''s great! Use it! But you''re the exception, not the norm.)'),

(100, 'Self Loathing Indexes: Small Active Heap',N'https://www.brentozar.com/go/SelfLoathing','Active Heap(s)', '
This diagnosis is for active heaps - they''re being read from or written to - but they haven''t had forwarded records read or deletes occur since restart.

If you''ve got active heaps, give them a close look. 

Active heaps tend to lead to forwarded fetches and/or captive pages bogging down your queries and hogging resources.

The short-term solution for this is to rebuild the heaps more often. 
Note that [Ola Hallengren''s Maintenance Solution](https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html) does not rebuild heaps, so you''ll have to address those separately.
Just be aware that when you rebuild heaps, it''s a logged operation, and can slow things down while you work. 
Only rebuild heapss while keeping a close eye on other activity on the server, doing frequent log backups as necessary.

The long-term solution is to look into turning these heaps into clustered indexes.
The rule of thumb for SQL Server is to always create a clustered index on a table unless you can prove there is a performance improvement for you application by using a heap. 
(If you can prove there''s a benefit, that''s great! Use it! But you''re the exception, not the norm.)'),

(100, 'Self Loathing Indexes: Heap with a Nonclustered Primary Key',N'https://www.brentozar.com/go/SelfLoathing','Heap with a Nonclustered Primary Key','
If you have a viable candidate for a clustered index (primary keys, are almost always good candidates for clustered indexes), why make it a nonclustered index instead of a clustered index?

The rule of thumb for SQL Server is to always create a clustered index on a table unless you can prove there is a performance improvement for you application by using a heap. 
(If you can prove there''s a benefit, that''s great! Use it! But you''re the exception, not the norm.)'),

(100, 'Index Hoarder: NC index with High Writes:Reads',N'https://www.brentozar.com/go/IndexHoarder','NC Index with High Writes:Reads','
This looks at nonclustered indexes that have 10x more writes than reads associated with them. 
This means that you''re doing a lot of work to maintain an index, and it isn''t necessarily helping a lot of read queries. 
This warning should be used alongside other warnings about duplicate, unused, and wide indexes when determining which to keep and which to disable. 
It could also be that someone just made a bad index all by its lonesome.'),

(50, 'Indexaphobia: High Value Missing Index',N'https://www.brentozar.com/go/Indexaphobia','High Value Missing Index','
This is at least one (maybe more) indexes that SQL Server thinks could really speed up queries.

Now, before we get too far into this, let''s start with a warning. 
Just like advice from people, you don''t want to take SQL Server''s indexing advice TOO literally. 
You want to take it as a starting point and then decide: is this good advice? What''s the best way I could use this.

Here are some of the gotchas that come with missing index recommendations:

They''re super specific - and they don''t consider each other. If you follow the missing index recommendations exactly, you''re very likely to create indexes with duplicate keys and /or duplicate include values.
They don''t consider existing indexes on the tables. There may be an existing index which is just like the missing index, but it needs one added included column. 
The missing index recommendations will just tell you the exact index that would be perfect for them.
Sometimes it will recommend an index that already exists.
So, in short, missing index information is super valuable! But it''s not the whole story.
Compare these findings with themselves (if you get more for one table), with existing indexes (in case you can add one or more columns to an existing index to help other queries).
And always test to make sure the execution plan uses it and the performance gain is actually there.

Note that the index names are auto-generated and you might have to adapt them to match your index naming convention.'),

(80,'Abnormal Psychology: Identity Column Within xx Percent End of Range',N'https://www.brentozar.com/go/AbnormalPsychology','',''),

(80, 'Abnormal Psychology: Columnstore Indexes with Trace Flag 834', N'https://support.microsoft.com/en-us/kb/3210239','Columnstore Indexes with Trace Flag 834','
The combination of columnstore indexes and trace flag 834 is known to cause issues, please see [this link](https://learn.microsoft.com/en-US/troubleshoot/sql/database-engine/performance/batch-mode-with-large-page-memory-issues) for more info'),

(90,'Functioning Statistaholics: Statistics Not Updated Recently','https://www.brentozar.com/go/stats','Statistics Not Updated Recently','
As a rule of thumg, statistics should generally be updated on a weekly basis on active tables or after data loads and/or archiving on ETL tables.
On very active tables you might need to do this more often.'),

(90, 'Functioning Statistaholics: Low Sampling Rates','https://www.brentozar.com/go/stats','Low Sampling Rates','
These indexes have had statistics updated with low sampling rates. 
In most cases, a low sample size isn''t really a good enough indicator of the data distribution in your tables, this leads to incorrect cardinality estimates which impacts query performance.'),
(90, 'Functioning Statistaholics: Statistics With NO RECOMPUTE','https://www.brentozar.com/go/stats','',''),
(100, 'Serial Forcer: Check Constraint with Scalar UDF', 'https://www.brentozar.com/go/computedscalar','Check Constraint with Scalar UDF', '
You have one or more check constraints based on scalar UDF. This causes SQL Server to go single-threaded when working with those constraints.
Read more [here](https://www.brentozar.com/archive/2016/01/another-reason-why-scalar-functions-in-computed-columns-is-a-bad-idea/).'),
(100, 'Serial Forcer: Computed Column with Scalar UDFs', 'https://www.brentozar.com/go/computedscalar','Computed Column with Scalar UDF', '
You have one or more computed columns based on scalar UDFs. This causes SQL Server to go single-threaded when working with those columns.
Read more [here](https://www.brentozar.com/archive/2016/01/another-reason-why-scalar-functions-in-computed-columns-is-a-bad-idea/).'),

(150,'Index Hoarder: More Than 5 Percent NC Indexes Are Unused',N'https://www.brentozar.com/go/IndexHoarder','More Than 5 Percent NC Indexes Are Unused','
# More than 5% of indexes are unused

If 5% or more of your nonclustered indexes show as unused, this diagnosis is made.
If you get this diagnosis, look carefully at all the indexes that have 0 reads. To make that easy, those indexes are listed in the _Unused NC index_ section'),

(150, 'Index Hoarder: Borderline: Wide Indexes (7 or More Columns)',N'https://www.brentozar.com/go/IndexHoarder','Wide Indexes (7 or More Columns)','
Are indexes measured by weight, or by volume? I think weight is the amount of GB the pages take up, and volume is the rowcount, so I guess they''re measured by both.

The more columns you add to an index, the "heavier" that index gets. This is particularly important if writing to the table happens. 
The more indexes I add, the more work my writes have to do. The more columns are in each index, the more that gets magnified.

One important thing to note for this check is that we add up the key and include columns and look for any index with a total of seven or more.

Are there cases where it''s just fine to have indexes this wide or wider? Certainly. 
But generally speaking if you make a practice of this, your database is going to be bogged down by all the index data it''s dragging around.'),

(150, 'Index Hoarder: Wide Clustered Index (> 3 columns OR > 16 bytes)',N'https://www.brentozar.com/go/IndexHoarder','Wide Clustered Index (> 3 columns OR > 16 bytes)','
Your nonclustered indexes have a secret: they''re hiding the clustering key of the table as a special type of included column! 
This is functionally necessary so that you can quickly use a nonclustered index to look up related index in the clustered index.  
(The one exception to this is if your table does not have a clustered index - in that case the nonclustered indexes hide something called a RID, or row identifier instead.)

This means that if you create a wide clustering key on a table with many columns, every nonclustered index you create on that table is going to contain every column that is in the clustering key.

Wide clustering keys add up to database bloat. While we''re not arguing that composite keys are always wrong, always be aware if you have multiple columns in your clustered index and keep track of the impact.
Also keep in mind that the wider the clustered index key the more overhead for SQL Server to maintain it.
Variable width columns in the clustering keys cause even bigger issues if they''re hot columns (columns that get updated), and they get updated with values slightly wider than the initial value, let''s say NULL gets updated to xyz (8 bytes), or xyz gets updated to abcdefgh (18 bytes), 
SQL Server will have to shuffle data around pages to make room for the new value which increases fragmentation really fast and adds additional overhead.

 Recommendations
- Analyze the clustering keys used in the index, make sure they respect the SUN-E (Static, Unique, Narrow, Ever-increasing) principle as much as possible. 
- There shouldn''t be a valid reason that would warrant a varchar or an nvarchar column as a clustering key column.
- Avoid using NULLable columns as clustering keys
'),

(200, 'Index Hoarder: Addicted to Nulls',N'https://www.brentozar.com/go/IndexHoarder','Tables with a high NULLable column ratio','
These are tables where the ratio between the total number of columns and the number of NULLable columns is very high.
This might be indicative of potentially unused columns and/or insufficient data normalization, especially if some of the columns store repetitive data that could benefit from being stored in a lookup table.'),
(150, 'Index Hoarder: Wide Tables: 35+ cols or > 2000 non-LOB bytes',N'https://www.brentozar.com/go/IndexHoarder','Wide Tables: 35+ cols or > 2000 non-LOB bytes','
This might be indicative of a table design issue caused by improper/insufficient data normalization or simply adding lots of columns to a table and forgetting about them.
Tables where max possible bytes per row >= 8000 (one 8KB data page) will also hinder you from implementing page compression (which reduces space usage by a factor of 5 as well as speeds up queries due to fewer pages being accessed).
Besides the compression aspect, rows split across multiple pages also make SQL Server work harder to insert/update/delete and read the data.
Analyze the tables in this list and decide if all the columns are actually used and/or if one "wide" tabel can be split into multiple "narrower" tables.'),

(200, 'Index Hoarder: Addicted to strings',N'https://www.brentozar.com/go/IndexHoarder','',''),
(150, 'Index Hoarder: Non-Unique Clustered Index',N'https://www.brentozar.com/go/IndexHoarder','Non-Unique Clustered Index','
You don''t have to make your clustered index unique. But if you don''t, SQL Server has to do it for you. 
When you create a non-unique clustered index, SQL Server needs to check if a row is a duplicate. When duplicates exist, a four byte uniquifier (plus extra bytes on the row for the overhead of describing what''s on the row and where it is) comes may be written. 
If a key doesn''t have a duplicate value then the uniquifier is left null.

Don''t think about this just in terms of space used on the row. 
The process of figuring out when you need to have a uniquifier and then applying it to the all the rows doesn''t come free! 
Plus, since the clustered index sneaks into those "secret columns" in your nonclustered index, this uniquifier can really get around.

The best practice for a clustered index in SQL Server is that it be unique, as well as narrow, unchanging, and supporting healthy insert patterns. 
If your clustered indexes aren''t unique, take a very close look at why that''s the case.'),

(150, 'Index Hoarder: Unused NC index with Low Writes',N'https://www.brentozar.com/go/IndexHoarder','Unused NC index with Low Writes','
# Unused NC index

An unused NC index is a sad thing. Or is it?
To interpret this information, you need to know how usage is calculated. Index usage information is persisted since SQL Server''s restart (there''s a gotcha on SQL Server 2012 - see below).  But of course,  if I create a new index, its usage is only going to be persisted after the time it was created.
You may also have cases where indexes are only used at special times, but are still very important. (Think end-of-quarter and end-of-year reports  run by the CFO, CTO, and other acronyms.)
Unused indexes may also be performing other important functions, like serving as primary keys. If an index is a primary key, the index_definition column will contain a "[PK]", like the index in this example: [PK] [KEYS]  BusinessEntityID'),

(250,'Feature-Phobic Indexes: No Indexes Use Includes','https://www.brentozar.com/go/IndexFeatures','', '
"Included columns" were introduced as a feature in SQL Server 2005. An included column exists in the "leaf" of an index, but isn''t present in the key columns. 
Using included columns can help you "cover" queries with an index - without inflating the key of that index.

Like any good thing, you don''t want to overuse included columns. That just leads you to tons of wide indexes, which is another disorder in itself.

But index tuning and management is all about balance. And if you''re not using included columns at all by now (hey, it''s been HOW MANY years since 2005?), then I''m guessing you don''t even know what you''re missing.'),

(250,'Feature-Phobic Indexes: Few Indexes Use Includes','https://www.brentozar.com/go/IndexFeatures','Few Indexes Use Includes','
There''s no hard and fast rule that I should use includes on 3% or more of my indexes  - not at all!

However, I might have a database that has 700 indexes, and one has includes. It wouldn''t be diagnosed as "no indexes use includes," but are the databases'' indexes quite possibly out of balance? 
When this comes up, take a look at your indexing practices and make sure you''re taking advantage of all the options.'),

(250,'Feature-Phobic Indexes: No Filtered Indexes or Indexed Views','https://www.brentozar.com/go/IndexFeatures','No Filtered Indexes or Indexed Views','
First, let''s make one thing clear: you absolutely do not need to use filtered indexes or indexed views in every database. 
In fact, if you made it a practice to always use these features in EVERY database, that would be a little ridiculous.

However, don''t you want to know if you''re NEVER using these features? 
If you have a fair amount of SQL Server databases, there''s very likely a scenario or two when one of these will come in handy, and you''re not taking advantage of it.

 Gotchas
Think creating a filtered index or indexed view is super-low risk? Think again!
If you research these features and find a great use case, be careful when you implement them against a database for the first time. 
When you create either a filtered index or an indexed view, writes to the table may fail if the application is using different SET options than were in place when the filtered index or indexed view was created. 
See [SET Options That Affect Results](https://learn.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms175088(v=sql.105)) for more information. 
For this reason we recommend always creating indexes in a development environment and testing applications first when possible - especially with filtered indexes or indexed views.'),

(250,'Feature-Phobic Indexes: Potential Filtered Index (Based on Column Name)','https://www.brentozar.com/go/IndexFeatures','Potential Filtered Index (Based on Column Name)', '
This diagnosis outlines that the identified index could be a potential candidate to be a filtered index based on key column names (is%, %archive%, %active%, %flag%) '),

(150, 'Self Loathing Indexes: Hypothetical Index', N'https://www.brentozar.com/go/SelfLoathing','',''),
(150, 'Self Loathing Indexes: Disabled Index', N'https://www.brentozar.com/go/SelfLoathing','Disabled Index','
If if indexes have been disabled for a while, then do you really still need them to be in the database?
If you didn''t intend to have them disabled permanently then this is your chance to re-enable them.'),

(200, 'Self Loathing Indexes: Heaps with Deletes', N'https://www.brentozar.com/go/SelfLoathing','Heaps with Deletes', '
When you delete data from a heap it does not work the same was as if you deleted the data from an index (either clustered or nonclustered). 
Let''s say that I have a 2 GB heap and I delete half the rows in it - which coincidentally were on exactly half of the pages allocated to the index. 
If I do not use a special high level lock, those pages still stay allocated to the heap. They can be reused by that heap, but they have to hang around empty, just in case. Captive.

This leads to SQL Server having to unnecessarily read empty pages to retrieve actual data from said heap(s). 
Increasing the amount of time and resources SQL Server has to spend to retrieve the data required by a query.

The short-term solution for this is to rebuild the heaps more often. 
Note that [Ola Hallengren''s Maintenance Solution](https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html) does not rebuild heaps, so you''ll have to address those separately.
Just be aware that when you rebuild heaps, it''s a logged operation, and can slow things down while you work. 
Only rebuild heapss while keeping a close eye on other activity on the server, doing frequent log backups as necessary.

The long-term solution is to look into turning these heaps into clustered indexes.
The rule of thumb for SQL Server is to always create a clustered index on a table unless you can prove there is a performance improvement for you application by using a heap. 
(If you can prove there''s a benefit, that''s great! Use it! But you''re the exception, not the norm.)'),

(150, 'Abnormal Psychology: XML Index', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(150, 'Abnormal Psychology: NC Columnstore Index', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(150, 'Abnormal Psychology: Clustered Columnstore Index', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(150, 'Abnormal Psychology: Spatial Index', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(150, 'Abnormal Psychology: Compressed Index', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(150, 'Abnormal Psychology: Partitioned Index', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(150, 'Abnormal Psychology: Non-Aligned Index on a Partitioned Table', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(200, 'Abnormal Psychology: Recently Created Tables/Indexes (1 week)', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(200, 'Abnormal Psychology: Recently Modified Tables/Indexes (2 days)', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(150, 'Abnormal Psychology: Column Collation Does Not Match Database Collation', N'https://www.brentozar.com/go/AbnormalPsychology','Column Collation Does Not Match Database Collation','
Collation mismatches can potentially lead to undesired behavior in string comparison and sorting.
Make sure you''re aware of this and that this is the intended design, otherwise address it.'),
(200, 'Abnormal Psychology: Replicated Columns', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(150, 'Abnormal Psychology: Cascading Updates or Deletes', N'https://www.brentozar.com/go/AbnormalPsychology','',''),

(150, 'Abnormal Psychology: Unindexed Foreign Keys', N'https://www.brentozar.com/go/AbnormalPsychology','Unindexed Foreign Keys','
This one''s self-explanatory, JOINs are usually based on foreign keys, so you would want to have a supporting nonclustered index on the column that''s defined as the foreign key.
If you join based on these foreign keys, create a nonclustered index on them.'),

(150, 'Abnormal Psychology: In-Memory OLTP', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(200, 'Abnormal Psychology: Identity Column Using a Negative Seed or Increment Other Than 1', N'https://www.brentozar.com/go/AbnormalPsychology','',''),
(200, 'Workaholics: Scan-a-lots (index-usage-stats)',N'https://www.brentozar.com/go/Workaholics','',''),
(200, 'Workaholics: Top Recent Accesses (index-op-stats)',N'https://www.brentozar.com/go/Workaholics','',''),
(200, 'Functioning Statistaholics: Filter Fixation',N'https://www.brentozar.com/go/stats','',''),
(200, 'Cold Calculators: Definition Defeatists',N'','',''),
(200, 'Abnormal Psychology: Temporal Tables',N'','',''),
(200, 'Medicated Indexes: Optimized For Sequential Keys',N'','','');