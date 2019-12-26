USE [LeonDev]
GO

/****** Object:  StoredProcedure [dbo].[usp_PII_Search]    Script Date: 12/2/2019 2:33:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_PII_Search]
	@Database VARCHAR(128),
	@Schema VARCHAR(64),
	@Table VARCHAR(128),
	@Column VARCHAR(128),
	@InputValues VARCHAR(512) = NULL -- must be separated by comma, i.e. 'abc,def,ghij, klmnop'
/*
Flower Box
Addition #1 at 14:55 on Dec 02, 2019.
*/
AS

SET NOCOUNT ON

/* Step 0: declare all necessary variables for further processing */

DECLARE @SQL VARCHAR(4000)

/* Step 1: if @InputValues parameter is present, it must be parsed into a temp table */

DECLARE @StringClone VARCHAR(512)
DECLARE @Charindex INT

CREATE TABLE [dbo].[TempTable]( -- this table is going to hold the parsed @InputValues in a single column; it will be destroyed at the end of the procedure
[TableColumn] VARCHAR(128) NULL
)

IF @InputValues IS NOT NULL
	BEGIN
		SELECT @StringClone = REPLACE(@InputValues,' ','')

		SELECT @Charindex = CHARINDEX(',',@StringClone,1)

		WHILE @Charindex > 0
			BEGIN

				INSERT [dbo].[TempTable] ([TableColumn])
				VALUES(SUBSTRING(@StringClone,1,@Charindex - 1))

				SELECT @StringClone = SUBSTRING(@StringClone,@Charindex + 1,LEN(@StringClone) - @Charindex + 1)
		
				SELECT @Charindex = CHARINDEX(',',@StringClone,1)

			END
	END

/* Step 2: compose the executable T-SQL statement */

SELECT @SQL = 'SELECT *
FROM ['  + @Database + '].[' + @Schema + '].[' + @Table + ']
WHERE [' + @Column + '] IN
(' + CASE 
	WHEN @InputValues IS NOT NULL THEN 'SELECT [TableColumn] FROM [dbo].[TempTable])'
	ELSE 'SELECT [ICDDescription] FROM [InfoScan].[dbo].[icd10cm_codes_2020])'
	END

EXEC (@SQL)

DROP TABLE [dbo].[TempTable]
GO


