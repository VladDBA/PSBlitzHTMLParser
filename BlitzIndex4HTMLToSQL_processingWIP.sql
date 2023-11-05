DECLARE @XMLContent XML,
@FileName NVARCHAR(512);


SELECT @XMLContent = CONVERT (XML, REPLACE(REPLACE(REPLACE(BulkColumn, '<a href="#top">Jump to top</a>', ''), '<br>', ''), '<td></td>', '<td>x</td>'), 2)
FROM   OPENROWSET (BULK 'E:\VSQL\Backup\BlitzIndex_4_.html', SINGLE_CLOB) AS HTMLData;

	 SELECT     xx.value('(./td/text())[1]', 'INT')            AS [Priority],
                xx.value('(./td/text())[2]', 'NVARCHAR(200)')  AS [Finding],
                xx.value('(./td/text())[3]', 'NVARCHAR(128)')  AS [DatabaseName],
                xx.value('(./td/text())[4]', 'NVARCHAR(MAX)')  AS [Details],
                xx.value('(./td/text())[5]', 'NVARCHAR(MAX)')  AS [Definition],
                xx.value('(./td/text())[6]', 'NVARCHAR(MAX)')  AS [SecretColumns],
                xx.value('(./td/text())[7]', 'NVARCHAR(MAX)')  AS [Usage],
                xx.value('(./td/text())[8]', 'NVARCHAR(MAX)')  AS [Size],
				xx.value('(./td/text())[9]', 'NVARCHAR(MAX)')  AS [MoreInfo],
                xx.value('(./td/text())[10]', 'NVARCHAR(MAX)') AS [CreateTSQL]
				INTO ##PSBlitzIndexDiagnosis
         FROM   (VALUES(@XMLContent)) t1(x)
                CROSS APPLY x.nodes('//table[1]/tr[position()>1]') t2(xx)

/*Many NC indexes on a table*/

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
       N'| :---- | :---- | :---- | :---- | :---- |' AS [MarkdownInfo]
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


/*Borderline duplicate indexes*/

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
       N'| :---- | :---- | :---- | :---- | :---- | :---- |' AS [MarkdownInfo]
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


/*Heaps with forwarded fetches*/
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
	   N'| :---- | :---- | :---- | ----: | :---- |' AS [MarkdownInfo]
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

/*Active heaps*/

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
	   N'| :---- | :---- | :---- | :---- | :---- |' AS [MarkdownInfo]
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
AND [Finding] LIKE '%Active Heap'
ORDER BY [Priority] ASC, 
       [Finding] ASC, [DatabaseName] ASC;


/*Heap with a Nonclustered Primary Key*/ 
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'| DatabaseName | HeapAndPKName | Definition | Usage | Size |' AS [MarkdownInfo]

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
	   N'| :---- | :---- | :---- |  :---- | :---- |' AS [MarkdownInfo]
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



/*Heaps With Deletes*/
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
	   N'| DatabaseName | HeapName | Usage | Deletes | Size |' AS [MarkdownInfo]

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
	   N'| :---- | :---- | :---- | ----: | :---- |' AS [MarkdownInfo]
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



/*Wide Indexes */
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'| DatabaseName | IndexName(IndexId) | Definition | Usage | Size |' AS [MarkdownInfo]

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
	   N'| :---- | :---- | :---- |  :---- | :---- |' AS [MarkdownInfo]
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


/*Wide clustered Indexes */
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
       N'| DatabaseName | TableName | CXDefinition |  KeyColPotentialSize(Bytes) | Size |' AS [MarkdownInfo]
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
       N'| :---- | :---- | :---- |  :---- | :---- |' AS [MarkdownInfo]
UNION ALL
SELECT [Priority],
       [Finding],
       -- LEFT([Details], CHARINDEX(' ', [Details])),
       [DatabaseName],
       [Details],
       [Definition],
       [SecretColumns],
       [Usage],
       [Size],
       [CreateTSQL],
       CAST(LEFT(REPLACE(SUBSTRING([Details], CHARINDEX(' ', [Details]) + 1, LEN([Details])), 'columns with potential size of ', ''), CHARINDEX(' ', REPLACE(SUBSTRING([Details], CHARINDEX(' ', [Details]) + 1, LEN([Details])), 'columns with potential size of ', ''))) AS INT) AS [CXMaxBytes],
       '|' + [DatabaseName] + ' | '
       + REPLACE(REPLACE(REPLACE([MoreInfo], 'EXEC dbo.sp_BlitzIndex @DatabaseName='''+[DatabaseName]+''', @SchemaName=''', ''), ''', @TableName=''', '.'), ''';', '')
       + ' | ' + [Definition] + ' | '
       + LEFT(REPLACE(SUBSTRING([Details], CHARINDEX(' ', [Details])+1, LEN([Details])), 'columns with potential size of ', ''), CHARINDEX(' ', REPLACE(SUBSTRING([Details], CHARINDEX(' ', [Details])+1, LEN([Details])), 'columns with potential size of ', '')))
       + ' | ' + [Size] + ' | '                                                                                                                                                                                                                                                    AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE  [Priority] = 150
       AND [Finding] LIKE N'%Wide Clustered Index (> 3 columns OR > 16 bytes)'
ORDER  BY [Priority] ASC,
          [CXMaxBytes] DESC; 


/*Heap with a Nonclustered Primary Key*/ 
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   N'| DatabaseName | FKMissingIndex |' AS [MarkdownInfo]

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

/*Wide tables */
/*todo sort out Details with dbo.brs_table has 35 total columns with a max possible width of 1938 bytes.1 columns are LOB types.*/
SELECT -3 AS [Priority],
       N'' AS [Finding],
       N'' AS [DatabaseName],
       N'' AS [Details],
       N'' AS [Definition],
       N'' AS [SecretColumns],
       N'' AS [Usage],
       N'' AS [Size],
       N'' AS [CreateTSQL],
	   NULL AS [Coulmns],
	   NULL AS [MaxWidthBytes],
	   N'| DatabaseName | FKMissingIndex |' AS [MarkdownInfo]

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
	   NULL AS [Coulmns],
	   NULL AS [MaxWidthBytes],
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
	   
	   /*these are columns*/
	   LEFT(
	   REPLACE(REPLACE(REPLACE([Details],(LEFT([Details], CHARINDEX(' ',[Details])))+'has ',''), 'total columns with a max possible width of ', ''), ' bytes.','')
	   ,CHARINDEX(' ',REPLACE(REPLACE(REPLACE([Details],(LEFT([Details], CHARINDEX(' ',[Details])))+'has ',''), 'total columns with a max possible width of ', ''), ' bytes.',''))) AS [Coulmns],
	   /*these are max width bytes*/
	   RIGHT(
	   REPLACE(REPLACE(REPLACE([Details],(LEFT([Details], CHARINDEX(' ',[Details])))+'has ',''), 'total columns with a max possible width of ', ''), ' bytes.','')
	   ,CHARINDEX(' ',REPLACE(REPLACE(REPLACE([Details],(LEFT([Details], CHARINDEX(' ',[Details])))+'has ',''), 'total columns with a max possible width of ', ''), ' bytes.',''))+1) AS [MaxWidthBytes],
		'|'+ [DatabaseName] + ' | ' + LEFT([Details], CHARINDEX(' ',[Details])) + ' | '  AS [MarkdownInfo]
FROM   ##PSBlitzIndexDiagnosis
WHERE [Priority] = 150
AND 
[Finding] LIKE N'%Wide Tables: 35+ cols or > 2000 non-LOB bytes'
ORDER BY [Priority] ASC,
[MaxWidthBytes] DESC;
