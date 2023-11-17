DECLARE @XMLContent XML,
@FileName NVARCHAR(512);

IF OBJECT_ID(N'tempdb.dbo.##PSBlitzIndexDiagnosis', N'U') IS NOT NULL
  BEGIN
      DROP TABLE ##PSBlitzIndexDiagnosis;
  END;

SELECT @XMLContent = CONVERT (XML, 
     REPLACE(REPLACE(REPLACE(BulkColumn, '<a href="#top">Jump to top</a>', ''), '<br>', ''), '<td></td>', '<td>x</td>')
                              , 2)
FROM   OPENROWSET (BULK 'E:\VSQL\Backup\BlitzIndex_4_new.html', SINGLE_BLOB) AS HTMLData;

WITH XMLToTableCTE
     AS (SELECT xx.value('(./td/text())[1]', 'INT')            AS [Priority],
                xx.value('(./td/text())[2]', 'NVARCHAR(200)')  AS [Finding],
                xx.value('(./td/text())[3]', 'NVARCHAR(128)')  AS [DatabaseName],
                xx.value('(./td/text())[4]', 'NVARCHAR(MAX)')  AS [Details],
                xx.value('(./td/text())[5]', 'NVARCHAR(MAX)')  AS [Definition],
                xx.value('(./td/text())[6]', 'NVARCHAR(MAX)')  AS [SecretColumns],
                xx.value('(./td/text())[7]', 'NVARCHAR(MAX)')  AS [Usage],
                xx.value('(./td/text())[8]', 'NVARCHAR(MAX)')  AS [Size],
                xx.value('(./td/text())[9]', 'NVARCHAR(MAX)')  AS [MoreInfo],
                xx.value('(./td/text())[10]', 'NVARCHAR(MAX)') AS [CreateTSQL]
         FROM   (VALUES(@XMLContent)) t1(x)
                CROSS APPLY x.nodes('//table[1]/tr[position()>1]') t2(xx))
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [MoreInfo],
       [CreateTSQL],
	   REPLACE(REPLACE(REPLACE([MoreInfo], 'EXEC dbo.sp_BlitzIndex @DatabaseName='''+[DatabaseName]+''', @SchemaName=''', ''), ''', @TableName=''', '.'), ''';', '') AS [TableName],
	   CAST('' AS NVARCHAR(300)) AS [DataPrep],
	   CAST('' AS NVARCHAR(MAX)) AS [ObjectName]
INTO ##PSBlitzIndexDiagnosis
FROM   XMLToTableCTE
ORDER  BY [Priority] ASC,[Finding]
ASC;
GO
/*Prepare data here */

UPDATE ##PSBlitzIndexDiagnosis
SET    [DataPrep] = CASE
                      WHEN [Finding] LIKE N'%Wide Tables: 35+ cols or > 2000 non-LOB bytes'
                           AND [Details] LIKE N'%LOB types.' 
						   THEN REPLACE(REPLACE(REPLACE(REPLACE([Details], [TableName] + ' has ', ''), ' total columns with a max possible width of', ''), ' bytes', ''), ' columns are LOB types.', '')
                      WHEN [Finding] LIKE N'%Wide Tables: 35+ cols or > 2000 non-LOB bytes'
                           AND [Details] NOT LIKE '%LOB types.' 
						   THEN REPLACE(REPLACE(REPLACE(REPLACE([Details], [TableName] + ' has ', ''), ' total columns with a max possible width of', ''), ' bytes', ''), '.', '')
                      WHEN [Finding] LIKE '%Addicted to Nulls' 
					       THEN REPLACE(REPLACE(REPLACE([Details], [TableName] + ' allows null in ', ''), ' columns.', ''), ' of ', ' ')
                      WHEN [Finding] LIKE '%Wide Clustered Index (> 3 columns OR > 16 bytes)' 
					       THEN REPLACE(REPLACE(LEFT([Details], CHARINDEX(':', [Details]) - 1), ' bytes in clustered index', ''), ' columns with potential size of ', ' ')
                      WHEN [Priority] = 50
                           AND [Finding] LIKE '%High Value Missing Index' 
						   THEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([Usage], N' uses;', N';'), N' use;', N';'), N' Impact: ', N''), N'%;', N'%'), N' Avg query cost: ', N'')
                      ELSE ''
                    END; 

/*Object names pass 1*/
UPDATE ##PSBlitzIndexDiagnosis
SET    [ObjectName] = CASE
                        WHEN [CreateTSQL] LIKE 'CREATE%' THEN REPLACE(REPLACE(REPLACE(REPLACE([CreateTSQL], 'CREATE ', ''), 'UNIQUE ', ''), 'CLUSTERED ', ''), 'INDEX [', '')
                        WHEN [CreateTSQL] LIKE 'ALTER%CONSTRAINT%' THEN REPLACE([CreateTSQL], 'ALTER TABLE [' + [DatabaseName] + '].['
                                                                                              + REPLACE([TableName], '.', '].[')
                                                                                              + '] ADD CONSTRAINT [', '')
                        WHEN [Finding] LIKE '%Unindexed Foreign Keys' THEN REPLACE([Details], 'Foreign key [', '')
                        ELSE ''
                      END

/*Object names pass 2*/
UPDATE ##PSBlitzIndexDiagnosis
SET    [ObjectName] = REPLACE(LEFT([ObjectName], CHARINDEX(' ', [ObjectName]) - 1), ']', '')
WHERE  [ObjectName] <> ''

/*More table names */
UPDATE ##PSBlitzIndexDiagnosis
SET    [TableName] = REPLACE([Details], 'Foreign key [' + [ObjectName] + '] on [', '')
WHERE  [Finding] LIKE '%Unindexed Foreign Keys'
       AND [TableName] = 'x'

UPDATE ##PSBlitzIndexDiagnosis
SET    [TableName] = REPLACE(LEFT([TableName], CHARINDEX(' ', [TableName]) - 1), ']', '')
WHERE  [Finding] LIKE '%Unindexed Foreign Keys'
       AND [TableName] LIKE '%]%' 



/*Show me what you got*/
/*10	Index Hoarder: Many NC Indexes on a Single Table*/
IF EXISTS(SELECT 1 FROM   ##PSBlitzIndexDiagnosis
WHERE  [Priority] = 10
       AND [Finding] LIKE '%Many NC Indexes on a Single Table')
BEGIN
SELECT -3                                                            AS [Priority],
       N''                                                           AS [Finding],
       N''                                                           AS [DatabaseName],
       N''                                                           AS [Details],
       N''                                                           AS [Definition],
       N''                                                           AS [SecretColumns],
       N''                                                           AS [Usage],
       N''                                                           AS [Size],
       N''                                                           AS [CreateTSQL],
       NULL                                                          AS [NCIndexesCount],
       N'| DatabaseName | TableName | NCIndexCount | Usage | Size |' AS [MarkdownInfo]
UNION ALL
SELECT -2                                           AS [Priority],
       N''                                          AS [Finding],
       N''                                          AS [DatabaseName],
       N''                                          AS [Details],
       N''                                          AS [Definition],
       N''                                          AS [SecretColumns],
       N''                                          AS [Usage],
       N''                                          AS [Size],
       N''                                          AS [CreateTSQL],
       NULL                                         AS [NCIndexesCount],
       N'| :---- | :---- | :---- | :---- | ----: |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],
       CAST(REPLACE(TRIM(LEFT([Details], CHARINDEX(' ', [Details]))), ',', '')AS INT) AS [NCIndexesCount],
       '|' + [DatabaseName] + ' | '
       + LEFT([Definition], CHARINDEX(' ', [Definition]))
       + ' | '
       + REPLACE(TRIM(LEFT([Details], CHARINDEX(' ', [Details]))), ',', '')
       + ' | ' + [Usage] + ' | ' + [Size] + ' | '                                     AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE  [Priority] = 10
       AND [Finding] LIKE '%Many NC Indexes on a Single Table'
ORDER  BY [Priority] ASC,
          [NCIndexesCount] DESC; 
END;

/*20	Multiple Index Personalities: Duplicate keys*/

SELECT -3                                                            AS [Priority],
       N''                                                           AS [Finding],
       N''                                                           AS [DatabaseName],
       N''                                                           AS [Details],
       N''                                                           AS [Definition],
       N''                                                           AS [SecretColumns],
       N''                                                           AS [Usage],
       N''                                                           AS [Size],
       N''                                                           AS [CreateTSQL],
       --NULL                                                          AS [NCIndexesCount],
       N'| DatabaseName | IndexName | Definition | SecretColumns | Usage | Size |' AS [MarkdownInfo]
UNION ALL
SELECT -2                                           AS [Priority],
       N''                                          AS [Finding],
       N''                                          AS [DatabaseName],
       N''                                          AS [Details],
       N''                                          AS [Definition],
       N''                                          AS [SecretColumns],
       N''                                          AS [Usage],
       N''                                          AS [Size],
       N''                                          AS [CreateTSQL],
       --NULL                                         AS [NCIndexesCount],
       N'| :---- | :---- | :---- | :---- | :---- | ----: |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],
        '|' + [DatabaseName] + ' | '
       + LEFT([Details], CHARINDEX(' ', [Details]))
       + ' | '
       + [Definition] + ' | ' +CASE WHEN [SecretColumns] = 'x' THEN '' ELSE [SecretColumns] END
       + ' | ' + [Usage] + ' | ' + [Size] + ' | '                                     AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE  [Priority] = 20
       AND [Finding] LIKE '%duplicate keys'
ORDER  BY [Priority] ASC,
[DatabaseName] ASC,
[Details] ASC; 

/*30	Multiple Index Personalities: Borderline duplicate keys*/

SELECT -3                                                            AS [Priority],
       N''                                                           AS [Finding],
       N''                                                           AS [DatabaseName],
       N''                                                           AS [Details],
       N''                                                           AS [Definition],
       N''                                                           AS [SecretColumns],
       N''                                                           AS [Usage],
       N''                                                           AS [Size],
       N''                                                           AS [CreateTSQL],
       --NULL                                                          AS [NCIndexesCount],
       N'| DatabaseName | IndexName | Definition | SecretColumns | Usage | Size |' AS [MarkdownInfo]
UNION ALL
SELECT -2                                           AS [Priority],
       N''                                          AS [Finding],
       N''                                          AS [DatabaseName],
       N''                                          AS [Details],
       N''                                          AS [Definition],
       N''                                          AS [SecretColumns],
       N''                                          AS [Usage],
       N''                                          AS [Size],
       N''                                          AS [CreateTSQL],
       --NULL                                         AS [NCIndexesCount],
       N'| :---- | :---- | :---- | :---- | :---- | ----: |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],
        '|' + [DatabaseName] + ' | '
       + LEFT([Details], CHARINDEX(' ', [Details]))
       + ' | '
       + [Definition] + ' | ' +CASE WHEN [SecretColumns] = 'x' THEN '' ELSE [SecretColumns] END
       + ' | ' + [Usage] + ' | ' + [Size] + ' | '                                     AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE  [Priority] = 30
       AND [Finding] LIKE '%Borderline duplicate keys'
ORDER  BY [Priority] ASC,
[DatabaseName] ASC,
[Details] ASC; 


/*100	Self Loathing Indexes: Heaps with Forwarded Fetches*/
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
	   NULL AS [ForwardedFetchesCount],
	   N'' AS [RebuildTSQL],
	   N'| DatabaseName | HeapName | Usage | ForwardedFetches | Size |' AS [MarkdownInfo]

UNION ALL
SELECT -2 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
	   NULL AS [ForwardedFetchesCount],
	   N'' AS [RebuildTSQL],
	   N'| :---- | :---- | :---- | ----: | ----: |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
	   CAST(REPLACE(TRIM(LEFT([Details],CHARINDEX(' f',[Details]))),',','')AS BIGINT) AS [ForwardedFetchesCount],
	    [CreateTSQL] AS [RebuildTSQL],
		'|'+ [DatabaseName] + ' | ' + REPLACE(SUBSTRING([Details],CHARINDEX(':',[Details])+2, LEN([Details])),'.Unknown (0)','') + ' | ' + [Usage] + ' | '
		+ LEFT([Details],CHARINDEX(' f',[Details])) + '|'+ [Size] +' | ' AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE [Priority] = 100
AND [Finding] LIKE '%Heaps with Forwarded Fetches'
ORDER BY [Priority] ASC,
[ForwardedFetchesCount] DESC;

/*100	Self Loathing Indexes: L/M/S Active Heap*/

SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'| DatabaseName | HeapName | Finding | Usage | Size |' AS [MarkdownInfo]

UNION ALL
SELECT -2 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'| :---- | :---- | :---- | :---- | ----: |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],
	  '|'+ [DatabaseName] + ' | ' + 
	  REPLACE(REPLACE([Details], 'Should this table be a heap? ',''),'.Unknown (0)','') +
	  ' | ' +REPLACE ([Finding], 'Self Loathing Indexes: ', '') +
	  + ' | ' + [Usage] + ' | ' + [Size] + ' | ' AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE [Priority] = 100
AND lower([Finding]) LIKE '%active heap'
ORDER BY [Priority] ASC, 
       [Finding] ASC, [DatabaseName] ASC;


/*100	Self Loathing Indexes: Heap with a Nonclustered Primary Key*/ 
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'| Database | Table & PKName | Definition | Usage | Size |' AS [MarkdownInfo]

UNION ALL
SELECT -2 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'| :---- | :---- | :---- |  :---- | ----: |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],

		'|'+ [DatabaseName] + ' | ' + LEFT([Details], CHARINDEX(' ', [Details])) + ' | ' 
		+ [Definition] + ' | ' + [Usage] + ' | ' 
		+[Size] + 
		' | '  AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE [Priority] = 100
AND 
[Finding] LIKE N'%Heap with a Nonclustered Primary Key'
ORDER BY [Priority] ASC;



/*200	Self Loathing Indexes: Heaps with Deletes*/
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
	   NULL [DeletesCount],
	   N'' AS [RebuildTSQL],
	   N'| Database | Table | Usage | Deletes | Size |' AS [MarkdownInfo]

UNION ALL
SELECT -2 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
	   NULL [DeletesCount],
	   N'' AS [RebuildTSQL],
	   N'| :---- | :---- | :---- | ----: | ----: |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
	   CAST(REPLACE(TRIM(LEFT([Details],CHARINDEX(' d',[Details]))),',','')AS BIGINT) AS [DeletesCount],
	    [CreateTSQL] AS [RebuildTSQL],
		'|'+ [DatabaseName] + ' | ' + REPLACE(SUBSTRING([Details],CHARINDEX(':',[Details])+2, LEN([Details])),'.Unknown (0)','') + ' | ' 
		+[Usage] + 
		' | '
		+ LEFT([Details],CHARINDEX(' d',[Details])) + '|' +[Size] + ' | ' AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE [Priority] = 200
AND 
[Finding] LIKE N'%Heaps with Deletes'
ORDER BY [Priority] ASC, 
[DeletesCount]
DESC;



/*150	Index Hoarder: Borderline: Wide Indexes (7 or More Columns) */
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'| Database | Index(IndexId) | Definition | Usage | Size |' AS [MarkdownInfo]

UNION ALL
SELECT -2 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'| :---- | :---- | :---- |  :---- | ----: |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],

		'|'+ [DatabaseName] + ' | ' + REPLACE(SUBSTRING([Details],CHARINDEX(' ',[Details])+1, LEN([Details])), 'columns on ', '') + ' | ' 
		+ [Definition] + ' | ' + [Usage] + ' | ' 
		+[Size] + 
		' | '  AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE [Priority] = 150
AND 
[Finding] LIKE N'%Wide Indexes (7 or More Columns)'
ORDER BY [Priority] ASC;


/*150	Index Hoarder: Wide Clustered Index (> 3 columns OR > 16 bytes) */
SELECT -3                                                                                  AS [Priority],
       N''                                                                                 AS [Finding],
       N''                                                                                 AS [DatabaseName],
       N''                                                                                 AS [Details],
       N''                                                                                 AS [Definition],
       N''                                                                                 AS [SecretColumns],
       N''                                                                                 AS [Usage],
       N''                                                                                 AS [Size],
       N''                                                                                 AS [CreateTSQL],
       NULL                                                                                AS [CXMaxBytes],
       N'| Database | Table | CXName | KeyColumns |  KeyColPotentialSize(Bytes) | Size | Definition |' AS [MarkdownInfo]
UNION ALL
SELECT -2                                            AS [Priority],
       N''                                           AS [Finding],
       N''                                           AS [DatabaseName],
       N''                                           AS [Details],
       N''                                           AS [Definition],
       N''                                           AS [SecretColumns],
       N''                                           AS [Usage],
       N''                                           AS [Size],
       N''                                           AS [CreateTSQL],
       NULL                                          AS [CXMaxBytes],
       N'| :---- | :---- | :---- |  ----: | ----: | ----: | :---- |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],
       CAST(RIGHT([DataPrep],CHARINDEX(' ',REVERSE([DataPrep]))-1) AS INT)  AS [CXMaxBytes],
       '|' + [DatabaseName] + ' | '
       + [TableName]
       + ' | ' + [ObjectName] + ' | ' 
       + LEFT([DataPrep],CHARINDEX(' ',[DataPrep])-1) + ' | '+ RIGHT([DataPrep],CHARINDEX(' ',REVERSE([DataPrep]))-1)
       + ' | '  +  [Size] + ' | ' + [Definition] + ' | '                                                                                                                                                                                                                                                    AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE  [Priority] = 150
       AND [Finding] LIKE N'%Wide Clustered Index (> 3 columns OR > 16 bytes)'
ORDER  BY [Priority] ASC,
          [CXMaxBytes] DESC; 


/*150	Abnormal Psychology: Unindexed Foreign Keys*/ 
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'| Database Name | FKMissingIndex |' AS [MarkdownInfo]

UNION ALL
SELECT -2 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'| :---- | :---- |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],

		'|'+ [DatabaseName] + ' | ' + [Details] + ' | '  AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE [Priority] = 150
AND 
[Finding] LIKE N'%Unindexed Foreign Keys'
ORDER BY [Priority] ASC,
[DatabaseName] ASC;

/*150	Index Hoarder: Wide Tables: 35+ cols or > 2000 non-LOB bytes */
/**/
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'' AS [DataPrep],
	   NULL AS [TotalColumns],
	   NULL AS [LOBColumns],
	   NULL AS [MaxPossibleBytesPerRecord],
	   N'| Database | Table | Total Columns | LOB Columns | Max Possible Bytes/Record | Usage | Size |' AS [MarkdownInfo]

UNION ALL
SELECT -2 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'' AS [DataPrep],
	   NULL AS [TotalColumns],
	   NULL AS [LOBColumns],
	   NULL AS [MaxPossibleBytesPerRecord],
	   N'| :---- | :---- | :---- | :---- | ----: | :---- | ----: |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],
       [DataPrep],
       CAST(LEFT([DataPrep], CHARINDEX(' ', [DataPrep]) - 1) AS INT) AS [TotalColumns],
       CASE
         WHEN [DataPrep] LIKE '%.%' THEN REVERSE(LEFT(REVERSE([DataPrep]), CHARINDEX('.', REVERSE([DataPrep])) - 1))
         ELSE ''
       END                                                           AS [LOBColumns],
       CAST(CASE
              WHEN [DataPrep] LIKE '%.%' THEN REPLACE(LEFT(RIGHT([DataPrep], CHARINDEX(' ', REVERSE([DataPrep]))), CHARINDEX('.', RIGHT([DataPrep], CHARINDEX(' ', REVERSE([DataPrep]))))), '.', '')
              ELSE RIGHT([DataPrep], CHARINDEX(' ', REVERSE([DataPrep])))
            END AS BIGINT)                                           AS [MaxPossibleBytesPerRecord],
       '|' + [DatabaseName] + ' | ' + [TableName] + ' | '
       + LEFT([DataPrep], CHARINDEX(' ', [DataPrep]) - 1)
       + ' | '
       + CASE
           WHEN [DataPrep] LIKE '%.%' THEN REVERSE(LEFT(REVERSE([DataPrep]), CHARINDEX('.', REVERSE([DataPrep])) - 1))
           ELSE ''
         END
       + ' | '
       + CASE
           WHEN [DataPrep] LIKE '%.%' THEN REPLACE(LEFT(RIGHT([DataPrep], CHARINDEX(' ', REVERSE([DataPrep]))), CHARINDEX('.', RIGHT([DataPrep], CHARINDEX(' ', REVERSE([DataPrep]))))), '.', '')
           ELSE RIGHT([DataPrep], CHARINDEX(' ', REVERSE([DataPrep])))
         END
       + ' | ' + [Usage] + ' | ' + [Size] + ' | '                    AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE  [Priority] = 150
       AND [Finding] LIKE N'%Wide Tables: 35+ cols or > 2000 non-LOB bytes'
ORDER  BY [Priority] ASC,
          [MaxPossibleBytesPerRecord] DESC,
		  [DatabaseName] ASC; 

/*200	Index Hoarder: Addicted to Nulls*/
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'' AS [DataPrep],
	   NULL AS [TotalColumns],
	   NULL AS [NULLableColumns],
	   N'| Database | Table | Total Columns | NULLable Columns | Usage | Size |' AS [MarkdownInfo]

UNION ALL
SELECT -2 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'' AS [DataPrep],
	   NULL AS [TotalColumns],
	   NULL AS [NULLableColumns],
	   N'| :---- | :---- | ----: | ----: | :---- | ----: |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],
       [DataPrep],
       CAST(RIGHT([DataPrep], CHARINDEX(' ', REVERSE([DataPrep])) - 1) AS INT) AS [TotalColumns],
       CAST(LEFT([DataPrep], CHARINDEX(' ', [DataPrep]) - 1) AS INT)           AS [NULLableColumns],
       '|' + [DatabaseName] + ' | ' + [TableName] + ' | '
       + RIGHT([DataPrep], CHARINDEX(' ', REVERSE([DataPrep])) - 1)
       + ' | '
       + LEFT([DataPrep], CHARINDEX(' ', [DataPrep]) - 1)
       + ' | ' + [Usage] + ' | ' + [Size] + ' | '                              AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE  [Priority] = 200
       AND [Finding] LIKE N'%Addicted to Nulls'
ORDER  BY [Priority] ASC,
          [NULLableColumns] DESC,
          [DatabaseName] ASC;
		  
/*50 High Value Missing Indexs*/
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'' AS [DataPrep],
	   NULL AS [UsageCount],
	   NULL AS [Impact%],
	   NULL AS [AvgQueryCost],
	   N'| Database | Table | Avg Query Cost | Potential Improvement| UsageCount | Size | CreateTSQL |' AS [MarkdownInfo]

UNION ALL
SELECT -2 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'' AS [DataPrep],
	   NULL AS [UsageCount],
	   NULL AS [Impact%],
	   NULL AS [AvgQueryCost],
	   N'| :---- | :---- | ----: | ----: | ----: | ----: | :---- |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],
       [DataPrep],
	   CAST(REPLACE(LEFT([DataPrep], CHARINDEX(';', [DataPrep])-1),',','') AS BIGINT) AS [UsageCount],
CAST(REPLACE(LEFT(RIGHT([DataPrep], CHARINDEX(';', REVERSE(DataPrep))-1),CHARINDEX('%',RIGHT([DataPrep], CHARINDEX(';', REVERSE([DataPrep]))-1))),'%','') AS NUMERIC(4,1)) AS [Impact%],
CAST(RIGHT([DataPrep], CHARINDEX('%',REVERSE([DataPrep]))-1) AS NUMERIC(20,4)) AS [AvgQueryCost],
' | ' + [DatabaseName] + ' | ' + [TableName] + ' | ' + RIGHT([DataPrep], CHARINDEX('%',REVERSE([DataPrep]))-1) + ' | ' + LEFT(RIGHT([DataPrep], CHARINDEX(';', REVERSE(DataPrep))-1),CHARINDEX('%',RIGHT([DataPrep], CHARINDEX(';', REVERSE([DataPrep]))-1))) + ' | '
+ REPLACE(LEFT([DataPrep], CHARINDEX(';', [DataPrep])-1),',','')  + ' | ' + [Size] + ' | ' + REPLACE([CreateTSQL], N'  WITH (FILLFACTOR=100, ONLINE=?, SORT_IN_TEMPDB=?, DATA_COMPRESSION=?)', '')+ ' | '
AS [MarkdownInfo]
FROM ##PSBlitzIndexDiagnosis
WHERE [Priority] = 50 
AND [Finding] LIKE '%High Value Missing Index'
ORDER BY [Priority] ASC,  [AvgQueryCost] DESC, [Impact%] DESC, UsageCount DESC;

/*100 NC index with High Writes:Reads*/
SELECT * 
FROM ##PSBlitzIndexDiagnosis
WHERE [Priority] = 100
AND [Finding] LIKE '%NC index with High Writes:Reads';