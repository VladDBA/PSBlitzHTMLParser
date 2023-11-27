DECLARE @XMLContent XML,
        @FileName   NVARCHAR(512);

IF OBJECT_ID(N'tempdb.dbo.##PSBlitzIndexUsage', N'U') IS NOT NULL
  BEGIN
      DROP TABLE ##PSBlitzIndexUsage;
  END;

SELECT @XMLContent = CONVERT (XML, REPLACE(REPLACE(REPLACE([BulkColumn], '<a href="#top">Jump to top</a>', ''), '<br>', ''), '<td></td>', '<td>x</td>'), 2)
FROM   OPENROWSET (BULK 'E:\VSQL\Backup\BlitzIndex_2.html', SINGLE_BLOB) AS [HTMLData];

WITH XMLToTableCTE
     AS (SELECT xx.value('(./td/text())[1]', 'NVARCHAR(200)')  AS [Database],
                xx.value('(./td/text())[2]', 'NVARCHAR(200)')  AS [Schema],
                xx.value('(./td/text())[3]', 'NVARCHAR(128)')  AS [Object],
                xx.value('(./td/text())[4]', 'NVARCHAR(200)')  AS [Index],
                xx.value('(./td/text())[5]', 'INT')            AS [IndexID],
                xx.value('(./td/text())[6]', 'NVARCHAR(500)')  AS [Details: schema.table.index(indexid)],
                xx.value('(./td/text())[7]', 'NVARCHAR(200)')  AS [ObjectType],
                xx.value('(./td/text())[8]', 'NVARCHAR(MAX)')  AS [Definition: Property ColumnName {datatype maxbytes}],
                xx.value('(./td/text())[9]', 'NVARCHAR(MAX)')  AS [Key Column Names With Sort],
                xx.value('(./td/text())[10]', 'INT')           AS [Count Key Columns],
                xx.value('(./td/text())[11]', 'NVARCHAR(MAX)') AS [Include Column Names],
                xx.value('(./td/text())[12]', 'INT')           AS [Count Included Columns],
                xx.value('(./td/text())[13]', 'NVARCHAR(MAX)') AS [Secret Column Names],
                xx.value('(./td/text())[14]', 'INT')           AS [Count Secret Columns],
                xx.value('(./td/text())[15]', 'NVARCHAR(200)') AS [Partition key column name],
                xx.value('(./td/text())[16]', 'NVARCHAR(MAX)') AS [Filter Definition],
                xx.value('(./td/text())[17]', 'NVARCHAR(30)')  AS [Is Indexed View],
                xx.value('(./td/text())[18]', 'NVARCHAR(30)')  AS [Is PK],
                xx.value('(./td/text())[19]', 'NVARCHAR(30)')  AS [Is XML],
                xx.value('(./td/text())[20]', 'NVARCHAR(30)')  AS [Is Spatial],
                xx.value('(./td/text())[21]', 'NVARCHAR(30)')  AS [Is NC Columnstore],
                xx.value('(./td/text())[22]', 'NVARCHAR(30)')  AS [Is CX Columnstore],
                xx.value('(./td/text())[23]', 'NVARCHAR(30)')  AS [Is Disabled],
                xx.value('(./td/text())[24]', 'NVARCHAR(30)')  AS [Is Hypothetical],
                xx.value('(./td/text())[25]', 'NVARCHAR(30)')  AS [Is Padded],
                xx.value('(./td/text())[26]', 'INT')           AS [Fill Factor],
                xx.value('(./td/text())[27]', 'NVARCHAR(30)')  AS [Is Reference by Foreign Key],
                xx.value('(./td/text())[28]', 'NVARCHAR(30)')  AS [Last User Seek],
                xx.value('(./td/text())[29]', 'NVARCHAR(30)')  AS [Last User Scan],
                xx.value('(./td/text())[30]', 'NVARCHAR(30)')  AS [Last User Lookup],
                xx.value('(./td/text())[31]', 'NVARCHAR(30)')  AS [Last User Update],
                xx.value('(./td/text())[32]', 'INT')           AS [Total Reads],
                xx.value('(./td/text())[33]', 'INT')           AS [User Updates],
                xx.value('(./td/text())[34]', 'NVARCHAR(30)')  AS [Reads Per Write],
                xx.value('(./td/text())[35]', 'NVARCHAR(300)') AS [Index Usage],
                xx.value('(./td/text())[36]', 'NVARCHAR(30)')  AS [Partition Count], 
                xx.value('(./td/text())[37]', 'NVARCHAR(30)')  AS [Rows], 
                xx.value('(./td/text())[38]', 'NVARCHAR(30)')  AS [Reserved MB], 
                xx.value('(./td/text())[39]', 'NVARCHAR(30)')  AS [Reserved LOB MB], 
                xx.value('(./td/text())[40]', 'NVARCHAR(30)')  AS [Reserved Row Overflow MB], 
                xx.value('(./td/text())[41]', 'NVARCHAR(300)') AS [Index Size],
                xx.value('(./td/text())[42]', 'NVARCHAR(30)')  AS [Row Lock Count], 
                xx.value('(./td/text())[43]', 'NVARCHAR(30)')  AS [Row Lock Wait Count], 
                xx.value('(./td/text())[44]', 'NVARCHAR(30)')  AS [Row Lock Wait ms], 
                xx.value('(./td/text())[45]', 'NVARCHAR(30)')  AS [Avg Row Lock Wait ms], 
                xx.value('(./td/text())[46]', 'NVARCHAR(30)')  AS [Page Lock Count], 
                xx.value('(./td/text())[47]', 'NVARCHAR(30)')  AS [Page Lock Wait Count], 
                xx.value('(./td/text())[48]', 'NVARCHAR(30)')  AS [Page Lock Wait ms], 
                xx.value('(./td/text())[49]', 'NVARCHAR(30)')  AS [Avg Page Lock Wait ms], 
                xx.value('(./td/text())[50]', 'NVARCHAR(30)')  AS [Lock Escalation Attempts], 
                xx.value('(./td/text())[51]', 'NVARCHAR(30)')  AS [Lock Escalations], 
                xx.value('(./td/text())[52]', 'NVARCHAR(30)')  AS [Page Latch Wait Count], 
                xx.value('(./td/text())[53]', 'NVARCHAR(30)')  AS [Page Latch Wait ms], 
                xx.value('(./td/text())[54]', 'NVARCHAR(30)')  AS [Page IO Latch Wait Count], 
                xx.value('(./td/text())[55]', 'NVARCHAR(30)')  AS [Page IO Latch Wait ms], 
                xx.value('(./td/text())[56]', 'NVARCHAR(100)') AS [Data Compression],
                xx.value('(./td/text())[57]', 'DATETIME')      AS [Create Date],
                xx.value('(./td/text())[58]', 'DATETIME')      AS [Modify Date]
         FROM   (VALUES(@XMLContent)) [t1](x)
                CROSS APPLY x.nodes('//table[1]/tr[position()>1]') [t2](xx))
SELECT [Database],
       [Schema],
       [Object],
       [Index],
       [IndexID],
       [Details: schema.table.index(indexid)],
       [ObjectType],
       [Definition: Property ColumnName {datatype maxbytes}],
       [Key Column Names With Sort],
       [Count Key Columns],
       [Include Column Names],
       [Count Included Columns],
       [Secret Column Names],
       [Count Secret Columns],
       [Partition key column name],
       [Filter Definition],
       [Is Indexed View],
       [Is PK],
       [Is XML],
       [Is Spatial],
       [Is NC Columnstore],
       [Is CX Columnstore],
       [Is Disabled],
       [Is Hypothetical],
       [Is Padded],
       [Fill Factor],
       [Is Reference by Foreign Key],
       CAST(CASE
              WHEN [Last User Seek] = 'x' THEN NULL
              ELSE [Last User Seek]
            END AS DATETIME)       AS [Last User Seek],
       CAST(CASE
              WHEN [Last User Scan] = 'x' THEN NULL
              ELSE [Last User Scan]
            END AS DATETIME)       AS [Last User Scan],
       CAST(CASE
              WHEN [Last User Lookup] = 'x' THEN NULL
              ELSE [Last User Lookup]
            END AS DATETIME)       AS [Last User Lookup],
       CAST(CASE
              WHEN [Last User Update] = 'x' THEN NULL
              ELSE [Last User Update]
            END AS DATETIME)       AS [Last User Update],
       [Total Reads],
       [User Updates],
       [Reads Per Write],
       [Index Usage],
       CAST(CASE
              WHEN [Partition Count] = 'x' THEN NULL
              ELSE [Partition Count]
            END AS INT)            AS [Partition Count],
       CAST(CASE
              WHEN [Rows] = 'x' THEN NULL
              ELSE [Rows]
            END AS BIGINT)         AS [Rows],
       CAST(CASE
              WHEN [Reserved MB] = 'x' THEN NULL
              ELSE [Reserved MB]
            END AS NUMERIC(18, 2)) AS [Reserved MB],
       CAST(CASE
              WHEN [Reserved LOB MB] = 'x' THEN NULL
              ELSE [Reserved LOB MB]
            END AS NUMERIC(18, 2)) AS [Reserved LOB MB],
       CAST(CASE
              WHEN [Reserved Row Overflow MB] = 'x' THEN NULL
              ELSE [Reserved Row Overflow MB]
            END AS NUMERIC(18, 2)) AS [Reserved Row Overflow MB],
       [Index Size],
       CAST(CASE
              WHEN [Row Lock Count] = 'x' THEN NULL
              ELSE [Row Lock Count]
            END AS BIGINT)         AS [Row Lock Count],
       CAST(CASE
              WHEN [Row Lock Wait Count] = 'x' THEN NULL
              ELSE [Row Lock Wait Count]
            END AS BIGINT)         AS [Row Lock Wait Count],
       CAST(CASE
              WHEN [Row Lock Wait ms] = 'x' THEN NULL
              ELSE [Row Lock Wait ms]
            END AS BIGINT)         AS [Row Lock Wait ms],
       CAST(CASE
              WHEN [Avg Row Lock Wait ms] = 'x' THEN NULL
              ELSE [Avg Row Lock Wait ms]
            END AS BIGINT)         AS [Avg Row Lock Wait ms],
       CAST(CASE
              WHEN [Page Lock Count] = 'x' THEN NULL
              ELSE [Page Lock Count]
            END AS BIGINT)         AS [Page Lock Count],
       CAST(CASE
              WHEN [Page Lock Wait Count] = 'x' THEN NULL
              ELSE [Page Lock Wait Count]
            END AS BIGINT)         AS [Page Lock Wait Count],
       CAST(CASE
              WHEN [Page Lock Wait ms] = 'x' THEN NULL
              ELSE [Page Lock Wait ms]
            END AS BIGINT)         AS [Page Lock Wait ms],
       CAST(CASE
              WHEN [Avg Page Lock Wait ms] = 'x' THEN NULL
              ELSE [Avg Page Lock Wait ms]
            END AS BIGINT)         AS [Avg Page Lock Wait ms],
       CAST(CASE
              WHEN [Lock Escalation Attempts] = 'x' THEN NULL
              ELSE [Lock Escalation Attempts]
            END AS BIGINT)         AS [Lock Escalation Attempts],
       CAST(CASE
              WHEN [Lock Escalations] = 'x' THEN NULL
              ELSE [Lock Escalations]
            END AS BIGINT)         AS [Lock Escalations],
       CAST(CASE
              WHEN [Page Latch Wait Count] = 'x' THEN NULL
              ELSE [Page Latch Wait Count]
            END AS BIGINT)         AS [Page Latch Wait Count],
       CAST(CASE
              WHEN [Page Latch Wait ms] = 'x' THEN NULL
              ELSE [Page Latch Wait ms]
            END AS BIGINT)         AS [Page Latch Wait ms],
       CAST(CASE
              WHEN [Page IO Latch Wait Count] = 'x' THEN NULL
              ELSE [Page IO Latch Wait Count]
            END AS BIGINT)         AS [Page IO Latch Wait Count],
       CAST(CASE
              WHEN [Page IO Latch Wait ms] = 'x' THEN NULL
              ELSE [Page IO Latch Wait ms]
            END AS BIGINT)         AS [Page IO Latch Wait ms],
       [Data Compression],
       [Create Date],
       [Modify Date]
INTO   ##PSBlitzIndexUsage
FROM   XMLToTableCTE;