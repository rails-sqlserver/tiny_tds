# TinyTDS - Simple and fast FreeTDS bindings for Ruby using DB-Library.

* [![CircleCI](https://circleci.com/gh/rails-sqlserver/tiny_tds.svg?style=svg)](https://app.circleci.com/pipelines/github/rails-sqlserver/tiny_tds) - CircleCi
* [![Gem Version](https://img.shields.io/gem/v/tiny_tds.svg)](https://rubygems.org/gems/tiny_tds) - Gem Version
* [![Gitter chat](https://img.shields.io/badge/%E2%8A%AA%20GITTER%20-JOIN%20CHAT%20%E2%86%92-brightgreen.svg?style=flat)](https://gitter.im/rails-sqlserver/activerecord-sqlserver-adapter) - Community

## About TinyTDS

The TinyTDS gem is meant to serve the extremely common use-case of connecting, querying and iterating over results to Microsoft SQL Server or Sybase databases from Ruby using the FreeTDS's DB-Library API.

TinyTDS offers automatic casting to Ruby primitives along with proper encoding support. It converts all SQL Server datatypes to native Ruby primitives while supporting :utc or :local time zones for time-like types. To date it is the only Ruby client library that allows client encoding options, defaulting to UTF-8, while connecting to SQL Server. It also  properly encodes all string and binary data. The motivation for TinyTDS is to become the de-facto low level connection mode for the SQL Server Adapter for ActiveRecord.

The API is simple and consists of these classes:

* TinyTds::Client - Your connection to the database.
* TinyTds::Result - Returned from issuing an #execute on the connection. It includes Enumerable.
* TinyTds::Error - A wrapper for all FreeTDS exceptions.


## Install

Installing with rubygems should just work. TinyTDS is currently tested on Ruby version 2.0.0 and upward.

```
$ gem install tiny_tds
```

If you use Windows, we pre-compile TinyTDS with static versions of FreeTDS and supporting libraries.
If you're using RubyInstaller the binary gem will require that devkit is installed and in your path to operate properly.

On all other platforms, we will find these dependencies. It is recommended that you install the latest FreeTDS via your method of choice. For example, here is how to install FreeTDS on Ubuntu. You might also need the `build-essential` and possibly the `libc6-dev` packages.

```shell
$ apt-get install wget
$ apt-get install build-essential
$ apt-get install libc6-dev

$ wget http://www.freetds.org/files/stable/freetds-1.1.24.tar.gz
$ tar -xzf freetds-1.1.24.tar.gz
$ cd freetds-1.1.24
$ ./configure --prefix=/usr/local --with-tdsver=7.3
$ make
$ make install
```

Please read the MiniPortile and/or Windows sections at the end of this file for advanced configuration options past the following:

```
--with-freetds-dir=DIR
  Use the freetds library placed under DIR.
```


## Getting Started

Optionally, Microsoft has done a great job writing some articles on how to get started with SQL Server and Ruby using TinyTDS. Please checkout one of the following posts that match your platform.

* [SQL Server on a Mac](https://www.microsoft.com/en-us/sql-server/developer-get-started/ruby/mac)
* [SQL Server on RHEL](https://www.microsoft.com/en-us/sql-server/developer-get-started/ruby/rhel)
* [SQL Server on Ubuntu](https://www.microsoft.com/en-us/sql-server/developer-get-started/ruby/ubuntu)


## FreeTDS Compatibility & Configuration

TinyTDS is developed against FreeTDS 0.95, 0.99, and 1.0 current. Our default and recommended is 1.0. We also test with SQL Server 2008, 2014, and Azure. However, usage of TinyTDS with SQL Server 2000 or 2005 should be just fine. Below are a few QA style notes about installing FreeTDS.

**NOTE:** Windows users of our pre-compiled native gems need not worry about installing FreeTDS and its dependencies.

* **Do I need to install FreeTDS?** Yes! Somehow, someway, you are going to need FreeTDS for TinyTDS to compile against.

* **OK, I am installing FreeTDS, how do I configure it?** Contrary to what most people think, you do not need to specially configure FreeTDS in any way for client libraries like TinyTDS to use it. About the only requirement is that you compile it with libiconv for proper encoding support. FreeTDS must also be compiled with OpenSSL (or the like) to use it with Azure. See the "Using TinyTDS with Azure" section below for more info.

* **Do I need to configure `--with-tdsver` equal to anything?** Most likely! Technically you should not have to. This is only a default for clients/configs that do not specify what TDS version they want to use. We are currently having issues with passing down a TDS version with the login bit. Till we get that fixed, if you are not using a freetds.conf or a TDSVER environment variable, then make sure to use 7.1.

* **But I want to use TDS version 7.2 for SQL Server 2005 and up!** TinyTDS uses TDS version 7.1 (previously named 8.0) and fully supports all the data types supported by FreeTDS, this includes `varchar(max)` and `nvarchar(max)`. Technically compiling and using TDS version 7.2 with FreeTDS is not supported. But this does not mean those data types will not work. I know, it's confusing If you want to learn more, read this thread. http://lists.ibiblio.org/pipermail/freetds/2011q3/027306.html

* **I want to configure FreeTDS using `--enable-msdblib` and/or `--enable-sybase-compat` so it works for my database. Cool?** It's a waste of time and totally moot! Client libraries like TinyTDS define their own C structure names where they diverge from Sybase to SQL Server. Technically we use the MSDBLIB structures which does not mean we only work with that database vs Sybase. These configs are just a low level default for C libraries that do not define what they want. So I repeat, you do not NEED to use any of these, nor will they hurt anything since we control what C structure names we use internally!


## Data Types

Our goal is to support every SQL Server data type and covert it to a logical Ruby object. When dates or times are returned, they are instantiated to either `:utc` or `:local` time depending on the query options. Only [datetimeoffset] types are excluded. All strings are associated the to the connection's encoding and all binary data types are associated to Ruby's `ASCII-8BIT/BINARY` encoding.

Below is a list of the data types we support when using the 7.3 TDS protocol version. Using a lower protocol version will result in these types being returned as strings.

* [date]
* [datetime2]
* [datetimeoffset]
* [time]


## TinyTds::Client Usage

Connect to a database.

```ruby
client = TinyTds::Client.new username: 'sa', password: 'secret', host: 'mydb.host.net'
```

Creating a new client takes a hash of options. For valid iconv encoding options, see the output of `iconv -l`. Only a few have been tested and highly recommended to leave blank for the UTF-8 default.

* :username - The database server user.
* :password - The user password.
* :dataserver - Can be the name for your data server as defined in freetds.conf. Raw hostname or hostname:port will work here too. FreeTDS says that named instance like 'localhost\SQLEXPRESS' work too, but I highly suggest that you use the :host and :port options below. [Google how to find your host port if you are using named instances](http://bit.ly/xAf2jm) or [go here](http://msdn.microsoft.com/en-us/library/ms181087.aspx).
* :host - Used if :dataserver blank. Can be an host name or IP.
* :port - Defaults to 1433. Only used if :host is used.
* :database - The default database to use.
* :appname - Short string seen in SQL Servers process/activity window.
* :tds_version - TDS version. Defaults to "7.3".
* :login_timeout - Seconds to wait for login. Default to 60 seconds.
* :timeout - Seconds to wait for a response to a SQL command. Default 5 seconds. Prior to 1.0rc5, FreeTDS was unable to set the timeout on a per-client basis, permitting only a global timeout value. This means that if you're using an older version, the timeout values for all clients will be overwritten each time you instantiate a new `TinyTds::Client` object. If you are using 1.0rc5 or later, all clients will have an independent timeout setting as you'd expect. Timeouts caused by network failure will raise a timeout error 1 second after the configured timeout limit is hit (see [#481](https://github.com/rails-sqlserver/tiny_tds/pull/481) for details).
* :encoding - Any valid iconv value like CP1251 or ISO-8859-1. Default UTF-8.
* :azure - Pass true to signal that you are connecting to azure.
* :contained - Pass true to signal that you are connecting with a contained database user.
* :use_utf16 - Instead of using UCS-2 for database wide character encoding use UTF-16. Newer Windows versions use this encoding instead of UCS-2. Default true.
* :message_handler - Pass in a `call`-able object such as a `Proc` or a method to receive info messages from the database. It should have a single parameter, which will be a `TinyTds::Error` object representing the message. For example:

```ruby
opts = ... # host, username, password, etc
opts[:message_handler] = Proc.new { |m| puts m.message }
client = TinyTds::Client.new opts
# => Changed database context to 'master'.
# => Changed language setting to us_english.
client.execute("print 'hello world!'").do
# => hello world!
```

Use the `#active?` method to determine if a connection is good. The implementation of this method may change but it should always guarantee that a connection is good. Current it checks for either a closed or dead connection.

```ruby
client.dead?    # => false
client.closed?  # => false
client.active?  # => true
client.execute("SQL TO A DEAD SERVER")
client.dead?    # => true
client.closed?  # => false
client.active?  # => false
client.close
client.closed?  # => true
client.active?  # => false
```

Escape strings.

```ruby
client.escape("How's It Going'") # => "How''s It Going''"
```

Send a SQL string to the database and return a TinyTds::Result object.

```ruby
result = client.execute("SELECT * FROM [datatypes]")
```


## TinyTds::Result Usage

A result object is returned by the client's execute command. It is important that you either return the data from the query, most likely with the #each method, or that you cancel the results before asking the client to execute another SQL batch. Failing to do so will yield an error.

Calling #each on the result will lazily load each row from the database.

```ruby
result.each do |row|
  # By default each row is a hash.
  # The keys are the fields, as you'd expect.
  # The values are pre-built Ruby primitives mapped from their corresponding types.
end
```

A result object has a `#fields` accessor. It can be called before the result rows are iterated over. Even if no rows are returned, #fields will still return the column names you expected. Any SQL that does not return columned data will always return an empty array for `#fields`. It is important to remember that if you access the `#fields` before iterating over the results, the columns will always follow the default query option's `:symbolize_keys` setting at the client's level and will ignore the query options passed to each.

```ruby
result = client.execute("USE [tinytdstest]")
result.fields # => []
result.do

result = client.execute("SELECT [id] FROM [datatypes]")
result.fields # => ["id"]
result.cancel
result = client.execute("SELECT [id] FROM [datatypes]")
result.each(:symbolize_keys => true)
result.fields # => [:id]
```

You can cancel a result object's data from being loading by the server.

```ruby
result = client.execute("SELECT * FROM [super_big_table]")
result.cancel
```

You can use results cancelation in conjunction with results lazy loading, no problem.

```ruby
result = client.execute("SELECT * FROM [super_big_table]")
result.each_with_index do |row, i|
  break if row > 10
end
result.cancel
```

If the SQL executed by the client returns affected rows, you can easily find out how many.

```ruby
result.each
result.affected_rows # => 24
```

This pattern is so common for UPDATE and DELETE statements that the #do method cancels any need for loading the result data and returns the `#affected_rows`.

```ruby
result = client.execute("DELETE FROM [datatypes]")
result.do # => 72
```

Likewise for `INSERT` statements, the #insert method cancels any need for loading the result data and executes a `SCOPE_IDENTITY()` for the primary key.

```ruby
result = client.execute("INSERT INTO [datatypes] ([xml]) VALUES ('<html><br/></html>')")
result.insert # => 420
```

The result object can handle multiple result sets form batched SQL or stored procedures. It is critical to remember that when calling each with a block for the first time will return each "row" of each result set. Calling each a second time with a block will yield each "set".

```ruby
sql = ["SELECT TOP (1) [id] FROM [datatypes]",
       "SELECT TOP (2) [bigint] FROM [datatypes] WHERE [bigint] IS NOT NULL"].join(' ')

set1, set2 = client.execute(sql).each
set1 # => [{"id"=>11}]
set2 # => [{"bigint"=>-9223372036854775807}, {"bigint"=>9223372036854775806}]

result = client.execute(sql)

result.each do |rowset|
  # First time data loading, yields each row from each set.
  # 1st: {"id"=>11}
  # 2nd: {"bigint"=>-9223372036854775807}
  # 3rd: {"bigint"=>9223372036854775806}
end

result.each do |rowset|
  # Second time over (if columns cached), yields each set.
  # 1st: [{"id"=>11}]
  # 2nd: [{"bigint"=>-9223372036854775807}, {"bigint"=>9223372036854775806}]
end
```

Use the `#sqlsent?` and `#canceled?` query methods on the client to determine if an active SQL batch still needs to be processed and or if data results were canceled from the last result object. These values reset to true and false respectively for the client at the start of each `#execute` and new result object. Or if all rows are processed normally, `#sqlsent?` will return false. To demonstrate, lets assume we have 100 rows in the result object.

```ruby
client.sqlsent?   # = false
client.canceled?  # = false

result = client.execute("SELECT * FROM [super_big_table]")

client.sqlsent?   # = true
client.canceled?  # = false

result.each do |row|
  # Assume we break after 20 rows with 80 still pending.
  break if row["id"] > 20
end

client.sqlsent?   # = true
client.canceled?  # = false

result.cancel

client.sqlsent?   # = false
client.canceled?  # = true
```

It is possible to get the return code after executing a stored procedure from either the result or client object.

```ruby
client.return_code  # => nil

result = client.execute("EXEC tinytds_TestReturnCodes")
result.do
result.return_code  # => 420
client.return_code  # => 420
```


## Query Options

Every `TinyTds::Result` object can pass query options to the #each method. The defaults are defined and configurable by setting options in the `TinyTds::Client.default_query_options` hash. The default values are:

* :as => :hash - Object for each row yielded. Can be set to :array.
* :symbolize_keys => false - Row hash keys. Defaults to shared/frozen string keys.
* :cache_rows => true - Successive calls to #each returns the cached rows.
* :timezone => :local - Local to the Ruby client or :utc for UTC.
* :empty_sets => true - Include empty results set in queries that return multiple result sets.

Each result gets a copy of the default options you specify at the client level and can be overridden by passing an options hash to the #each method. For example

```ruby
result.each(:as => :array, :cache_rows => false) do |row|
  # Each row is now an array of values ordered by #fields.
  # Rows are yielded and forgotten about, freeing memory.
end
```

Besides the standard query options, the result object can take one additional option. Using `:first => true` will only load the first row of data and cancel all remaining results.

```ruby
result = client.execute("SELECT * FROM [super_big_table]")
result.each(:first => true) # => [{'id' => 24}]
```


## Row Caching

By default row caching is turned on because the SQL Server adapter for ActiveRecord would not work without it. I hope to find some time to create some performance patches for ActiveRecord that would allow it to take advantages of lazily created yielded rows from result objects. Currently only TinyTDS and the Mysql2 gem allow such a performance gain.


## Encoding Error Handling

TinyTDS takes an opinionated stance on how we handle encoding errors. First, we treat errors differently on reads vs. writes. Our opinion is that if you are reading bad data due to your client's encoding option, you would rather just find `?` marks in your strings vs being blocked with exceptions. This is how things wold work via ODBC or SMS. On the other hand, writes will raise an exception. In this case we raise the SYBEICONVO/2402 error message which has a description of `Error converting characters into server's character set. Some character(s) could not be converted.`. Even though the severity of this message is only a `4` and TinyTDS will automatically strip/ignore unknown characters, we feel you should know that you are inserting bad encodings. In this way, a transaction can be rolled back, etc. Remember, any database write that has bad characters due to the client encoding will still be written to the database, but it is up to you rollback said write if needed. Most ORMs like ActiveRecord handle this scenario just fine.


## Timeout Error Handling

TinyTDS will raise a `TinyTDS::Error` when a timeout is reached based on the options supplied to the client. Depending on the reason for the timeout, the connection could be dead or alive. When db processing is the cause for the timeout, the connection should still be usable after the error is raised. When network failure is the cause of the timeout, the connection will be dead. If you attempt to execute another command batch on a dead connection you will see a `DBPROCESS is dead or not enabled` error. Therefore, it is recommended to check for a `dead?` connection before trying to execute another command batch.

## Binstubs

The TinyTDS gem uses binstub wrappers which mirror compiled [FreeTDS Utilities](https://www.freetds.org/userguide/usefreetds.html) binaries. These native executables are usually installed at the system level when installing FreeTDS. However, when using MiniPortile to install TinyTDS as we do with Windows binaries, these binstubs will find and prefer local gem `exe` directory executables. These are the following binstubs we wrap.

* tsql - Used to test connections and debug compile time settings.
* defncopy - Used to dump schema structures.


## Using TinyTDS With Rails & The ActiveRecord SQL Server adapter.

TinyTDS is the default connection mode for the SQL Server adapter in versions 3.1 or higher. The SQL Server adapter can be found using the links below.

* ActiveRecord SQL Server Adapter: http://github.com/rails-sqlserver/activerecord-sqlserver-adapter


## Using TinyTDS with Azure

TinyTDS is fully tested with the Azure platform. You must set the `azure: true` connection option when connecting. This is needed to specify the default database name in the login packet since Azure has no notion of `USE [database]`. FreeTDS must be compiled with OpenSSL too.

**IMPORTANT**: Do not use `username@server.database.windows.net` for the username connection option! You must use the shorter `username@server` instead!

Also, please read the [Azure SQL Database General Guidelines and Limitations](https://msdn.microsoft.com/en-us/library/ee336245.aspx) MSDN article to understand the differences. Specifically, the connection constraints section!

## Connection Settings

A DBLIB connection does not have the same default SET options for a standard SMS SQL Server connection. Hence, we recommend the following options post establishing your connection.

#### SQL Server

```sql
SET ANSI_DEFAULTS ON

SET QUOTED_IDENTIFIER ON
SET CURSOR_CLOSE_ON_COMMIT OFF
SET IMPLICIT_TRANSACTIONS OFF
SET TEXTSIZE 2147483647
SET CONCAT_NULL_YIELDS_NULL ON
```

#### Azure

```sql
SET ANSI_NULLS ON
SET ANSI_NULL_DFLT_ON ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON

SET QUOTED_IDENTIFIER ON
SET CURSOR_CLOSE_ON_COMMIT OFF
SET IMPLICIT_TRANSACTIONS OFF
SET TEXTSIZE 2147483647
SET CONCAT_NULL_YIELDS_NULL ON
```


## Thread Safety

TinyTDS must be used with a connection pool for thread safety. If you use ActiveRecord or the [Sequel](https://github.com/jeremyevans/sequel) gem this is done for you. However, if you are using TinyTDS on your own, we recommend using the ConnectionPool gem when using threads:

* ConnectionPool Gem - https://github.com/mperham/connection_pool

Please read our [thread_test.rb](https://github.com/rails-sqlserver/tiny_tds/blob/master/test/thread_test.rb) file for details on how we test its usage.


## Emoji Support 😍

This is possible using FreeTDS version 0.95 or higher. You must use the `use_utf16` login option or add the following config to your `freetds.conf` in either the global section or a specfic dataserver. If you are on Windows, the default location for your conf file will be in `C:\Sites`.

```ini
[global]
  use utf-16 = true
```

The default is true and since FreeTDS v1.0 would do this as well.


## Compiling Gems for Windows

For the convenience of Windows users, TinyTDS ships pre-compiled gems for supported versions of Ruby on Windows. In order to generate these gems, [rake-compiler-dock](https://github.com/rake-compiler/rake-compiler-dock) is used. This project provides several [Docker images](https://registry.hub.docker.com/u/larskanis/) with rvm, cross-compilers and a number of different target versions of Ruby.

Run the following rake task to compile the gems for Windows. This will check the availability of [Docker](https://www.docker.com/) (and boot2docker on Windows or OS-X) and will give some advice for download and installation. When docker is running, it will download the docker image (once-only) and start the build:

```
$ rake gem:native
```

The compiled gems will exist in `./pkg` directory.


## Development & Testing

First, clone the repo using the command line or your Git GUI of choice.

```shell
$ git clone git@github.com:rails-sqlserver/tiny_tds.git
```

After that, the quickest way to get setup for development is to use [Docker](https://www.docker.com/). Assuming you have [downloaded docker](https://www.docker.com/products/docker) for your platform, you can use [docker-compose](https://docs.docker.com/compose/install/) to run the necessary containers for testing.

```shell
$ docker-compose up -d
```

This will download our SQL Server for Linux Docker image based from [microsoft/mssql-server-linux/](https://hub.docker.com/r/microsoft/mssql-server-linux/). Our image already has the `[tinytdstest]` DB and `tinytds` users created. This will also download a [toxiproxy](https://github.com/shopify/toxiproxy) Docker image which we can use to simulate network failures for tests. Basically, it does the following.

```shell
$ docker network create main-network
$ docker pull metaskills/mssql-server-linux-tinytds
$ docker run -p 1433:1433 -d --name sqlserver --network main-network metaskills/mssql-server-linux-tinytds
$ docker pull shopify/toxiproxy
$ docker run -p 8474:8474 -p 1234:1234 -d --name toxiproxy --network main-network shopify/toxiproxy
```

If you are using your own database. Make sure to run these SQL commands as SA to get the test database and user installed.

```sql
CREATE DATABASE [tinytdstest];
```

```sql
CREATE LOGIN [tinytds] WITH PASSWORD = '', CHECK_POLICY = OFF, DEFAULT_DATABASE = [tinytdstest];
USE [tinytdstest];
CREATE USER [tinytds] FOR LOGIN [tinytds];
EXEC sp_addrolemember N'db_owner', N'tinytds';
```

From here you can build and run tests against an installed version of FreeTDS.

```shell
$ bundle install
$ bundle exec rake
```

Examples us using enviornment variables to customize the test task.

```
$ rake TINYTDS_UNIT_DATASERVER=mydbserver
$ rake TINYTDS_UNIT_DATASERVER=mydbserver TINYTDS_SCHEMA=sqlserver_2008
$ rake TINYTDS_UNIT_HOST=mydb.host.net TINYTDS_SCHEMA=sqlserver_azure
$ rake TINYTDS_UNIT_HOST=mydb.host.net TINYTDS_UNIT_PORT=5000 TINYTDS_SCHEMA=sybase_ase
```

## Docker Builds

If you use a [multi stage](https://docs.docker.com/develop/develop-images/multistage-build/) Docker build to assemble your gems in one phase and then copy your app and gems
into another, lighter, container without build tools you will need to make sure you tell the OS how to find dependencies for TinyTDS.

After you have built and installed FreeTDS it will normally place library files in `/usr/local/lib`. When TinyTDS builds native extensions,
it [already knows to look here](https://github.com/rails-sqlserver/tiny_tds/blob/master/ext/tiny_tds/extconf.rb#L31) but if you copy your app to a new container that link will be broken.

Set the LD_LIBRARY_PATH environment variable `export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}` and run `ldconfig`. If you run `ldd tiny_tds.so` you should not see any broken links. Make
sure you also copied in the library dependencies from your build container with a command like `COPY --from=builder /usr/local/lib /usr/local/lib`.

## Help & Support

* Github Source: http://github.com/rails-sqlserver/tiny_tds
* Github Issues: http://github.com/rails-sqlserver/tiny_tds/issues
* Gitter Chat: https://gitter.im/rails-sqlserver/activerecord-sqlserver-adapter
* IRC Room: #rails-sqlserver on irc.freenode.net


## About Me

My name is Ken Collins and I currently maintain the SQL Server adapter for ActiveRecord and wrote this library as my first cut into learning Ruby C extensions. Hopefully it will help promote the power of Ruby and the Rails framework to those that have not yet discovered it. My blog is [metaskills.net](http://metaskills.net/) and I can be found on twitter as @metaskills. Enjoy!


## Special Thanks

* Lars Kanis for all his help getting the Windows builds working again with rake-compiler-dock.
* Erik Bryn for joining the project and helping me thru a few tight spots. - http://github.com/ebryn
* To the authors and contributors of the Mysql2 gem for inspiration. - http://github.com/brianmario/mysql2
* Yehuda Katz for articulating Ruby's need for proper encoding support. Especially in database drivers - http://yehudakatz.com/2010/05/05/ruby-1-9-encodings-a-primer-and-the-solution-for-rails/
* Josh Clayton of Thoughtbot for writing about Ruby C extensions. - http://robots.thoughtbot.com/post/1037240922/get-your-c-on


## License

TinyTDS is Copyright (c) 2010-2015 Ken Collins, <ken@metaskills.net> and Will Bond (Veracross LLC) <wbond@breuer.com>. It is distributed under the MIT license. Windows binaries contain pre-compiled versions of FreeTDS <http://www.freetds.org/> which is licensed under the GNU LGPL license at <http://www.gnu.org/licenses/lgpl-2.0.html>
