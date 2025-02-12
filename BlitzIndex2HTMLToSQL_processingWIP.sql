DECLARE @XMLContent XML,
        @FileName   NVARCHAR(512);

IF OBJECT_ID(N'dbo.PSBlitzIndexUsage', N'U') IS NULL
  BEGIN
      CREATE TABLE [dbo].[PSBlitzIndexUsage]
        (
           [ID]                                                    INT IDENTITY(1, 1) NOT NULL PRIMARY KEY CLUSTERED,
           [Database]                                            [NVARCHAR](200) NULL,
           [Schema]                                              [NVARCHAR](200) NULL,
           [Object]                                              [NVARCHAR](128) NULL,
           [Index Name]                                          [NVARCHAR](200) NULL,
           [IndexID]                                             [INT] NULL,
           --[Details: schema.table.index(indexid)]                [NVARCHAR](500) NULL,
           [ObjectType]                                          [NVARCHAR](200) NULL,
           [Definition: Property ColumnName {datatype maxbytes}] [NVARCHAR](max) NULL,
           [Key Column Names With Sort]                          [NVARCHAR](max) NULL,
           [Count Key Columns]                                   [INT] NULL,
           [Include Column Names]                                [NVARCHAR](max) NULL,
           [Count Included Columns]                              [INT] NULL,
           [Secret Column Names]                                 [NVARCHAR](max) NULL,
           [Count Secret Columns]                                [INT] NULL,
           [Partition key column name]                           [NVARCHAR](200) NULL,
           [Filter Definition]                                   [NVARCHAR](max) NULL,
           [Is Indexed View]                                     [NVARCHAR](30) NULL,
           [Is PK]                                               [NVARCHAR](30) NULL,
           [Is XML]                                              [NVARCHAR](30) NULL,
           [Is Spatial]                                          [NVARCHAR](30) NULL,
           [Is NC Columnstore]                                   [NVARCHAR](30) NULL,
           [Is CX Columnstore]                                   [NVARCHAR](30) NULL,
           [Is Disabled]                                         [NVARCHAR](30) NULL,
           [Is Hypothetical]                                     [NVARCHAR](30) NULL,
           [Is Padded]                                           [NVARCHAR](30) NULL,
           [Fill Factor]                                         [INT] NULL,
           [Is Reference by Foreign Key]                         [NVARCHAR](30) NULL,
           [Last User Seek]                                      [DATETIME] NULL,
           [Last User Scan]                                      [DATETIME] NULL,
           [Last User Lookup]                                    [DATETIME] NULL,
           [Last User Update]                                    [DATETIME] NULL,
           [Total Reads]                                         [INT] NULL,
           [User Updates]                                        [INT] NULL,
           [Reads Per Write]                                     [NVARCHAR](30) NULL,
           [Index Usage]                                         [NVARCHAR](300) NULL,
           [Partition Count]                                     [INT] NULL,
           [Rows]                                                [BIGINT] NULL,
           [Reserved MB]                                         [NUMERIC](18, 2) NULL,
           [Reserved LOB MB]                                     [NUMERIC](18, 2) NULL,
           [Reserved Row Overflow MB]                            [NUMERIC](18, 2) NULL,
           [Index Size]                                          [NVARCHAR](300) NULL,
           [Row Lock Count]                                      [BIGINT] NULL,
           [Row Lock Wait Count]                                 [BIGINT] NULL,
           [Row Lock Wait ms]                                    [BIGINT] NULL,
           [Avg Row Lock Wait ms]                                [BIGINT] NULL,
           [Page Lock Count]                                     [BIGINT] NULL,
           [Page Lock Wait Count]                                [BIGINT] NULL,
           [Page Lock Wait ms]                                   [BIGINT] NULL,
           [Avg Page Lock Wait ms]                               [BIGINT] NULL,
           [Lock Escalation Attempts]                            [BIGINT] NULL,
           [Lock Escalations]                                    [BIGINT] NULL,
           [Page Latch Wait Count]                               [BIGINT] NULL,
           [Page Latch Wait ms]                                  [BIGINT] NULL,
           [Page IO Latch Wait Count]                            [BIGINT] NULL,
           [Page IO Latch Wait ms]                               [BIGINT] NULL,
           [Data Compression]                                    [NVARCHAR](100) NULL,
           [Forwarded Fetches]                                   INT NULL,
           [Create Date]                                         [DATETIME] NULL,
           [Modify Date]                                         [DATETIME] NULL
        );
  END;

SELECT @XMLContent = CONVERT (XML, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([BulkColumn], '<a href="#top">Jump to top</a>', ''), '<br>', ''), '<td></td>', '<td>x</td>'),'<link rel="stylesheet" href="styles.css">',''),'<input type="text" id="SearchBox" class="SearchBox" onkeyup="SearchIndexUsage()" placeholder=" Filter by object name...">',''),'<table id=''IndexUsgTable'' class=''IndexUsageTable sortable''>','<table>'), 2)
--SELECT BulkColumn
FROM   OPENROWSET (BULK 'F:\PSBlitz_wip\LOCALHOST_VSQL2019_202502121028\HTMLFiles\BlitzIndex_2.html', SINGLE_BLOB) AS [HTMLData];

WITH XMLToTableCTE
     AS (SELECT xx.value('(./td/text())[1]', 'NVARCHAR(200)')  AS [Database],
                xx.value('(./td/text())[2]', 'NVARCHAR(200)')  AS [Schema],
                xx.value('(./td/text())[3]', 'NVARCHAR(128)')  AS [Object],
                xx.value('(./td/text())[4]', 'NVARCHAR(200)')  AS [Index],
                xx.value('(./td/text())[5]', 'INT')            AS [IndexID],
                --xx.value('(./td/text())[6]', 'NVARCHAR(500)')  AS [Details: schema.table.index(indexid)],
                xx.value('(./td/text())[6]', 'NVARCHAR(200)')  AS [ObjectType],
                xx.value('(./td/text())[7]', 'NVARCHAR(MAX)')  AS [Definition: Property ColumnName {datatype maxbytes}],
                xx.value('(./td/text())[8]', 'NVARCHAR(MAX)')  AS [Key Column Names With Sort],
                xx.value('(./td/text())[9]', 'NVARCHAR(200)')           AS [Count Key Columns],
                xx.value('(./td/text())[10]', 'NVARCHAR(MAX)') AS [Include Column Names],
                xx.value('(./td/text())[11]', 'INT')           AS [Count Included Columns],
                xx.value('(./td/text())[12]', 'NVARCHAR(MAX)') AS [Secret Column Names],
                xx.value('(./td/text())[13]', 'INT')           AS [Count Secret Columns],
                xx.value('(./td/text())[14]', 'NVARCHAR(200)') AS [Partition key column name],
                xx.value('(./td/text())[15]', 'NVARCHAR(MAX)') AS [Filter Definition],
                xx.value('(./td/text())[16]', 'NVARCHAR(30)')  AS [Is Indexed View],
                xx.value('(./td/text())[17]', 'NVARCHAR(30)')  AS [Is PK],
                xx.value('(./td/text())[18]', 'NVARCHAR(30)')  AS [Is Unique Constraint],
                xx.value('(./td/text())[19]', 'NVARCHAR(30)')  AS [Is XML],
                xx.value('(./td/text())[20]', 'NVARCHAR(30)')  AS [Is Spatial],
                xx.value('(./td/text())[21]', 'NVARCHAR(30)')  AS [Is NC Columnstore],
                xx.value('(./td/text())[22]', 'NVARCHAR(30)')  AS [Is CX Columnstore],
                xx.value('(./td/text())[23]', 'NVARCHAR(30)')  AS [Is In-Memory OLTP],
                xx.value('(./td/text())[24]', 'NVARCHAR(30)')  AS [Is Disabled],
                xx.value('(./td/text())[25]', 'NVARCHAR(30)')  AS [Is Hypothetical],
                xx.value('(./td/text())[26]', 'NVARCHAR(30)')  AS [Is Padded],
                xx.value('(./td/text())[27]', 'INT')           AS [Fill Factor],
                xx.value('(./td/text())[28]', 'NVARCHAR(30)')  AS [Is Reference by Foreign Key],
                xx.value('(./td/text())[29]', 'NVARCHAR(30)')  AS [Last User Seek],
                xx.value('(./td/text())[30]', 'NVARCHAR(30)')  AS [Last User Scan],
                xx.value('(./td/text())[31]', 'NVARCHAR(30)')  AS [Last User Lookup],
                xx.value('(./td/text())[32]', 'NVARCHAR(30)')  AS [Last User Update],
                xx.value('(./td/text())[33]', 'INT')           AS [Total Reads],
                xx.value('(./td/text())[34]', 'INT')           AS [User Updates],
                xx.value('(./td/text())[35]', 'NVARCHAR(30)')  AS [Reads Per Write],
                xx.value('(./td/text())[36]', 'NVARCHAR(300)') AS [Index Usage],
                xx.value('(./td/text())[37]', 'NVARCHAR(30)')  AS [Partition Count],
                xx.value('(./td/text())[38]', 'NVARCHAR(30)')  AS [Rows],
                xx.value('(./td/text())[39]', 'NVARCHAR(30)')  AS [Reserved MB],
                xx.value('(./td/text())[40]', 'NVARCHAR(30)')  AS [Reserved LOB MB],
                xx.value('(./td/text())[41]', 'NVARCHAR(30)')  AS [Reserved Row Overflow MB],
                xx.value('(./td/text())[42]', 'NVARCHAR(300)') AS [Index Size],
                xx.value('(./td/text())[43]', 'NVARCHAR(30)')  AS [Row Lock Count],
                xx.value('(./td/text())[44]', 'NVARCHAR(30)')  AS [Row Lock Wait Count],
                xx.value('(./td/text())[45]', 'NVARCHAR(30)')  AS [Row Lock Wait ms],
                xx.value('(./td/text())[46]', 'NVARCHAR(30)')  AS [Avg Row Lock Wait ms],
                xx.value('(./td/text())[47]', 'NVARCHAR(30)')  AS [Page Lock Count],
                xx.value('(./td/text())[48]', 'NVARCHAR(30)')  AS [Page Lock Wait Count],
                xx.value('(./td/text())[49]', 'NVARCHAR(30)')  AS [Page Lock Wait ms],
                xx.value('(./td/text())[50]', 'NVARCHAR(30)')  AS [Avg Page Lock Wait ms],
                xx.value('(./td/text())[51]', 'NVARCHAR(30)')  AS [Lock Escalation Attempts],
                xx.value('(./td/text())[52]', 'NVARCHAR(30)')  AS [Lock Escalations],
                xx.value('(./td/text())[53]', 'NVARCHAR(30)')  AS [Page Latch Wait Count],
                xx.value('(./td/text())[54]', 'NVARCHAR(30)')  AS [Page Latch Wait ms],
                xx.value('(./td/text())[55]', 'NVARCHAR(30)')  AS [Page IO Latch Wait Count],
                xx.value('(./td/text())[56]', 'NVARCHAR(30)')  AS [Page IO Latch Wait ms],
                xx.value('(./td/text())[57]', 'NVARCHAR(100)') AS [Forwarded Fetches],
                xx.value('(./td/text())[58]', 'NVARCHAR(100)') AS [Data Compression],
                xx.value('(./td/text())[59]', 'DATETIME')      AS [Create Date],
                xx.value('(./td/text())[60]', 'DATETIME')      AS [Modify Date]
         FROM   (VALUES(@XMLContent)) [t1](x)
                CROSS APPLY x.nodes('//table[1]/tr[position()>1]') [t2](xx))
INSERT INTO [dbo].[PSBlitzIndexUsage]
            ([Database],
             [Schema],
             [Object],
             [Index Name],
             [IndexID],
             --[Details: schema.table.index(indexid)],
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
             [Last User Seek],
             [Last User Scan],
             [Last User Lookup],
             [Last User Update],
             [Total Reads],
             [User Updates],
             [Reads Per Write],
             [Index Usage],
             [Partition Count],
             [Rows],
             [Reserved MB],
             [Reserved LOB MB],
             [Reserved Row Overflow MB],
             [Index Size],
             [Row Lock Count],
             [Row Lock Wait Count],
             [Row Lock Wait ms],
             [Avg Row Lock Wait ms],
             [Page Lock Count],
             [Page Lock Wait Count],
             [Page Lock Wait ms],
             [Avg Page Lock Wait ms],
             [Lock Escalation Attempts],
             [Lock Escalations],
             [Page Latch Wait Count],
             [Page Latch Wait ms],
             [Page IO Latch Wait Count],
             [Page IO Latch Wait ms],
             [Data Compression],
             [Create Date],
             [Modify Date])
SELECT [Database],
       CASE
         WHEN [Schema] = 'x' THEN NULL
         ELSE [Schema]
       END                         AS [Schema],
       [Object],
       CASE
         WHEN [Index] = 'x' THEN NULL
         ELSE [Index]
       END                         AS [Index Name],
       [IndexID],
       --[Details: schema.table.index(indexid)],
       [ObjectType],
       CASE
         WHEN [Definition: Property ColumnName {datatype maxbytes}] = 'x' THEN NULL
         ELSE [Definition: Property ColumnName {datatype maxbytes}]
       END                         AS [Definition: Property ColumnName {datatype maxbytes}],
       CASE
         WHEN [Key Column Names With Sort] = 'x' THEN NULL
         ELSE [Key Column Names With Sort]
       END                         AS [Key Column Names With Sort],
       [Count Key Columns],
       CASE
         WHEN [Include Column Names] = 'x' THEN NULL
         ELSE [Include Column Names]
       END                         AS [Include Column Names],
       [Count Included Columns],
       CASE
         WHEN [Secret Column Names] = 'x' THEN NULL
         ELSE [Secret Column Names]
       END                         AS [Secret Column Names],
       [Count Secret Columns],
       CASE
         WHEN [Partition key column name] = 'x' THEN NULL
         ELSE [Partition key column name]
       END                         AS [Partition key column name],
       CASE
         WHEN [Filter Definition] = 'x' THEN NULL
         ELSE [Filter Definition]
       END                         AS [Filter Definition],
       CASE
         WHEN [Is Indexed View] = 'x' THEN NULL
         ELSE [Is Indexed View]
       END                         AS [Is Indexed View],
       CASE
         WHEN [Is PK] = 'x' THEN NULL
         ELSE [Is PK]
       END                         AS [Is PK],
       CASE
         WHEN [Is XML] = 'x' THEN NULL
         ELSE [Is XML]
       END                         AS [Is XML],
       CASE
         WHEN [Is Spatial] = 'x' THEN NULL
         ELSE [Is Spatial]
       END                         AS [Is Spatial],
       CASE
         WHEN [Is NC Columnstore] = 'x' THEN NULL
         ELSE [Is NC Columnstore]
       END                         AS [Is NC Columnstore],
       CASE
         WHEN [Is CX Columnstore] = 'x' THEN NULL
         ELSE [Is CX Columnstore]
       END                         AS [Is CX Columnstore],
       CASE
         WHEN [Is Disabled] = 'x' THEN NULL
         ELSE [Is Disabled]
       END                         AS [Is Disabled],
       CASE
         WHEN [Is Hypothetical] = 'x' THEN NULL
         ELSE [Is Hypothetical]
       END                         AS [Is Hypothetical],
       CASE
         WHEN [Is Padded] = 'x' THEN NULL
         ELSE [Is Padded]
       END                         AS [Is Padded],
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
FROM   XMLToTableCTE; 
