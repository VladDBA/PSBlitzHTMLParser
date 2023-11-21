DECLARE @XMLContent XML,
@FileName NVARCHAR(512);

IF OBJECT_ID(N'tempdb.dbo.##PSBlitzIndexUsage', N'U') IS NOT NULL
  BEGIN
      DROP TABLE ##PSBlitzIndexUsage;
  END;

SELECT @XMLContent = CONVERT (XML, 
     REPLACE(REPLACE(REPLACE(BulkColumn, '<a href="#top">Jump to top</a>', ''), '<br>', ''), '<td></td>', '<td>x</td>')
                              , 2)
FROM   OPENROWSET (BULK 'C:\MSSQL\SQL2019_CS\Backup\BlitzIndex_2.html', SINGLE_BLOB) AS HTMLData;

WITH XMLToTableCTE
     AS (SELECT xx.value('(./td/text())[1]', 'NVARCHAR(200)')            AS [Database],
                xx.value('(./td/text())[2]', 'NVARCHAR(200)')  AS [Schema],
                xx.value('(./td/text())[3]', 'NVARCHAR(128)')  AS [Object],
                xx.value('(./td/text())[4]', 'NVARCHAR(200)')  AS [Index],
                xx.value('(./td/text())[5]', 'INT')  AS [IndexID],
                xx.value('(./td/text())[6]', 'NVARCHAR(500)')  AS [Details: schema.table.index(indexid)],
                xx.value('(./td/text())[7]', 'NVARCHAR(200)')  AS [ObjectType],
                xx.value('(./td/text())[8]', 'NVARCHAR(MAX)')  AS [Definition: Property ColumnName {datatype maxbytes}],
                xx.value('(./td/text())[9]', 'NVARCHAR(MAX)')  AS [Key Column Names With Sort],
                xx.value('(./td/text())[10]', 'int') AS [Count Key Columns],
				xx.value('(./td/text())[11]', 'NVARCHAR(MAX)')  AS [Include Column Names],
				xx.value('(./td/text())[12]', 'INT') AS [Count Included Columns],
				xx.value('(./td/text())[13]', 'NVARCHAR(MAX)')  AS [Secret Column Names],
				xx.value('(./td/text())[14]', 'INT') AS [Count Secret Columns],
				xx.value('(./td/text())[15]', 'NVARCHAR(200)')  AS [Partition key column name],
				xx.value('(./td/text())[16]', 'NVARCHAR(MAX)')  AS [Filter Definition],
				xx.value('(./td/text())[17]', 'NVARCHAR(30)')  AS [Is Indexed View],
				xx.value('(./td/text())[18]', 'NVARCHAR(30)')  AS [Is PK],
				xx.value('(./td/text())[19]', 'NVARCHAR(30)')  AS [Is XML],
				xx.value('(./td/text())[20]', 'NVARCHAR(30)')  AS [Is Spatial],
				xx.value('(./td/text())[21]', 'NVARCHAR(30)')  AS [Is NC Columnstore],
				xx.value('(./td/text())[22]', 'NVARCHAR(30)')  AS [Is CX Columnstore],
				xx.value('(./td/text())[23]', 'NVARCHAR(30)')  AS [Is Disabled],
				xx.value('(./td/text())[24]', 'NVARCHAR(30)')  AS [Is Hypothetical],
				xx.value('(./td/text())[25]', 'NVARCHAR(30)')  AS [Is Padded],
				xx.value('(./td/text())[26]', 'INT')  AS [Fill Factor],
				xx.value('(./td/text())[27]', 'NVARCHAR(30)')  AS [Is Reference by Foreign Key],
				xx.value('(./td/text())[28]', 'NVARCHAR(30)')  AS [Last User Seek], --DATETIME
				xx.value('(./td/text())[29]', 'NVARCHAR(30)')  AS [Last User Scan], --DATETIME
				xx.value('(./td/text())[30]', 'NVARCHAR(30)')  AS [Last User Lookup], --DATETIME
				xx.value('(./td/text())[31]', 'NVARCHAR(30)')  AS [Last User Update], --DATETIME
				xx.value('(./td/text())[32]', 'INT')  AS [Total Reads],
				xx.value('(./td/text())[33]', 'INT')  AS [User Updates],
				xx.value('(./td/text())[34]', 'NVARCHAR(30)')  AS [Reads Per Write],
				xx.value('(./td/text())[35]', 'NVARCHAR(300)')  AS [Index Usage],
				xx.value('(./td/text())[36]', 'NVARCHAR(30)')  AS [Partition Count], -- INT
				xx.value('(./td/text())[37]', 'NVARCHAR(30)')  AS [Rows], -- BIGINT
				xx.value('(./td/text())[38]', 'NVARCHAR(30)')  AS [Reserved MB],  -- NUMERIC(18,2)
				xx.value('(./td/text())[39]', 'NVARCHAR(30)')  AS [Reserved LOB MB],-- NUMERIC(18,2)
				xx.value('(./td/text())[40]', 'NVARCHAR(30)')  AS [Reserved Row Overflow MB],-- NUMERIC(18,2) 
				xx.value('(./td/text())[41]', 'NVARCHAR(300)')  AS [Index Size],
				xx.value('(./td/text())[42]', 'NVARCHAR(30)')  AS [Row Lock Count],-- bigint
				xx.value('(./td/text())[43]', 'NVARCHAR(30)')  AS [Row Lock Wait Count],-- bigint
				xx.value('(./td/text())[44]', 'NVARCHAR(30)')  AS [Row Lock Wait ms],-- bigint
				xx.value('(./td/text())[45]', 'NVARCHAR(30)')  AS [Avg Row Lock Wait ms],-- bigint
				xx.value('(./td/text())[46]', 'NVARCHAR(30)')  AS [Page Lock Count],-- bigint
				xx.value('(./td/text())[47]', 'NVARCHAR(30)')  AS [Page Lock Wait Count],-- bigint
				xx.value('(./td/text())[48]', 'NVARCHAR(30)')  AS [Page Lock Wait ms],-- bigint
				xx.value('(./td/text())[49]', 'NVARCHAR(30)')  AS [Avg Page Lock Wait ms],-- bigint
				xx.value('(./td/text())[50]', 'NVARCHAR(30)')  AS [Lock Escalation Attempts],-- bigint
				xx.value('(./td/text())[51]', 'NVARCHAR(30)')  AS [Lock Escalations],-- bigint
				xx.value('(./td/text())[52]', 'NVARCHAR(30)')  AS [Page Latch Wait Count],-- bigint
				xx.value('(./td/text())[53]', 'NVARCHAR(30)')  AS [Page Latch Wait ms],-- bigint
				xx.value('(./td/text())[54]', 'NVARCHAR(30)')  AS [Page IO Latch Wait Count],-- bigint
				xx.value('(./td/text())[55]', 'NVARCHAR(30)')  AS [Page IO Latch Wait ms],-- bigint
				xx.value('(./td/text())[56]', 'NVARCHAR(30)')  AS [Data Compression],-- bigint
				xx.value('(./td/text())[57]', 'DATETIME')  AS [Create Date],-- bigint
				xx.value('(./td/text())[58]', 'DATETIME')  AS [Modify Date]-- bigint
         FROM   (VALUES(@XMLContent)) t1(x)
                CROSS APPLY x.nodes('//table[1]/tr[position()>1]') t2(xx))
SELECT *
INTO ##PSBlitzIndexUsage
FROM   XMLToTableCTE;