
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[datatypes]') AND type in (N'U'))
DROP TABLE [dbo].[datatypes]

CREATE TABLE [dbo].[datatypes](
	[bigint] [bigint] NULL,
	[binary_50] [binary](50) NULL,
	[bit] [bit] NULL,
	[char_10] [char](10) NULL,
	[date] [date] NULL,
	[datetime] [datetime] NULL,
	[datetime2_7] [datetime2](7) NULL,
	[datetimeoffset_7] [datetimeoffset](7) NULL,
	[decimal_9_2] [decimal](9, 2) NULL,
	[decimal_16_4] [decimal](16, 4) NULL,
	[float] [float] NULL,
	[geography] [geography] NULL,
	[geometry] [geometry] NULL,
	[hierarchyid] [hierarchyid] NULL,
	[image] [image] NULL,
	[int] [int] NULL,
	[money] [money] NULL,
	[nchar_10] [nchar](10) NULL,
	[ntext] [ntext] NULL,
	[numeric_18_0] [numeric](18, 0) NULL,
	[nvarchar_50] [nvarchar](50) NULL,
	[nvarchar_max] [nvarchar](max) NULL,
	[real] [real] NULL,
	[smalldatetime] [smalldatetime] NULL,
	[smallint] [smallint] NULL,
	[smallmoney] [smallmoney] NULL,
	[sql_variant] [sql_variant] NULL,
	[text] [text] NULL,
	[time_7] [time](7) NULL,
	[timestamp] [timestamp] NULL,
	[tinyint] [tinyint] NULL,
	[uniqueidentifier] [uniqueidentifier] NULL,
	[varbinary_50] [varbinary](50) NULL,
	[varbinary_max] [varbinary](max) NULL,
	[varchar_50] [varchar](50) NULL,
	[varchar_max] [varchar](max) NULL,
	[xml] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

