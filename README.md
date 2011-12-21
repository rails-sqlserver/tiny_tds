# TinyTDS - A modern, simple and fast FreeTDS library for Ruby using DB-Library.

The TinyTDS gem is meant to serve the extremely common use-case of connecting, querying and iterating over results to Microsoft SQL Server databases from ruby. Even though it uses FreeTDS's DB-Library, it is NOT meant to serve as direct 1:1 mapping of that C API.

The benefits are speed, automatic casting to ruby primitives, and proper encoding support. It converts all SQL Server datatypes to native ruby objects supporting :utc or :local time zones for time-like types. To date it is the only ruby client library that allows client encoding options, defaulting to UTF-8, while connecting to SQL Server. It also  properly encodes all string and binary data. The motivation for TinyTDS is to become the de-facto low level connection mode for the SQL Server adapter for ActiveRecord. For further details see the special thanks section at the bottom

The API is simple and consists of these classes:

* TinyTds::Client - Your connection to the database.
* TinyTds::Result - Returned from issuing an #execute on the connection. It includes Enumerable.
* TinyTds::Error - A wrapper for all FreeTDS exceptions.


## New & Noteworthy

* Works with FreeTDS 0.91
* Tested on Windows using MiniPortile & RailsInstaller.
* New :host/:port connection options. Removes need for freetds.conf file.


## Install

Installing with rubygems should just work. TinyTDS is tested on ruby version 1.8.6, 1.8.7, 1.9.1, 1.9.2, 1.9.3 as well as REE & JRuby.

```
$ gem install tiny_tds
```

Although we search for FreeTDS's libraries and headers, you may have to specify include and lib directories using `--with-freetds-include=/some/local/include/freetds` and `--with-freetds-lib=/some/local/lib`


## FreeTDS Compatibility & Configuration

TinyTDS is developed against FreeTDS 0.82 & 0.91, the latest is recommended. It is tested with SQL Server 2000, 2005, 2008 and Azure. Below are a few QA style notes about installing FreeTDS.

* **Do I need to install FreeTDS?** Yes! Somehow, someway, your are going to need FreeTDS for TinyTDS to compile against. You can avoid installing FreeTDS on your system by using our projects usage of rake-compiler and mini_portile to compile and package a native gem just for you. See the "Using MiniPortile" section below.

* **OK, I am installing FreeTDS, how do I configure it?** Contrary to what most people think, you do not need to specially configure FreeTDS in any way for client libraries like TinyTDS to use it. About the only requirement is that you compile it with libiconv for proper encoding support. FreeTDS must also be compiled with OpenSSL (or the like) to use it with Azure. See the "Using TinyTDS with Azure" section below for more info.

* **Do I need to configure `--with-tdsver` equal to anything?** Maybe! Technically you should not have too. This is only a default for clients/configs that do not specify what TDS version they want to use. We are currently having issues with passing down a TDS version with the login bit. Till we get that fixed, if you are not using a freetds.conf or a TDSVER environment variable, the make sure to use 7.1 for FreeTDS 0.91 and 8.0 for FreeTDS 0.82.

* **But I want to use TDS version 7.2 for SQL Server 2005 and up!** TinyTDS uses TDS version 7.1 (previously named 8.0) and fully supports all the data types supported by FreeTDS, this includes `varchar(max)` and `nvarchar(max)`. Technically compiling and using TDS version 7.2 with FreeTDS is not supported. But this does not mean those data types will not work. I know, it's confusing If you want to learn more, read this thread. http://lists.ibiblio.org/pipermail/freetds/2011q3/027306.html

* **I want to configure FreeTDS using `--enable-msdblib` and/or `--enable-sybase-compat` so it works for my database. Cool?** It's a waste of time and totally moot! Client libraries like TinyTDS define their own C structure names where they diverge from Sybase to SQL Server. Technically we use the Sybase structures which does not mean we only work with that database vs SQL Server. These configs are just a low level default for C libraries that do not define what they want. So I repeat, you do not NEED to use any of these, nor will they hurt anything since we control what C structure names we use and this has no affect on what database you use!


## Data Types

Our goal is to support every SQL Server data type and covert it to a logical ruby object. When dates or times are returned, they are instantiated to either `:utc` or `:local` time depending on the query options. Under ruby 1.9, all strings are encoded to the connection's encoding and all binary data types are associated to ruby's `ASCII-8BIT/BINARY` encoding.

Below is a list of the data types we plan to support using future versions of FreeTDS. They are associated with SQL Server 2008. All unsupported data types are returned as properly encoded strings.

* [date]
* [datetime2]
* [datetimeoffset]
* [time]


## TinyTds::Client Usage

Connect to a database.

```ruby
client = TinyTds::Client.new(:username => 'sa', :password => 'secret', :host => 'mydb.host.net')
```

Creating a new client takes a hash of options. For valid iconv encoding options, see the output of `iconv -l`. Only a few have been tested and highly recommended to leave blank for the UTF-8 default.

* :username - The database server user.
* :password - The user password.
* :dataserver - Many options. Can be the name for your data server as defined in freetds.conf. Raw host name or IP will work here too. You can also used a named instance like 'localhost\SQLEXPRESS' too.
* :host - Used if :dataserver blank. Can be an host name or IP.
* :port - Defaults to 1433. Only used if :host is used.
* :database - The default database to use.
* :appname - Short string seen in SQL Servers process/activity window.
* :tds_version - TDS version. Defaults to 71 (7.1) and is not recommended to change!
* :login_timeout - Seconds to wait for login. Default to 60 seconds.
* :timeout - Seconds to wait for a response to a SQL command. Default 5 seconds.
* :encoding - Any valid iconv value like CP1251 or ISO-8859-1. Default UTF-8.
* :azure - Pass true to signal that you are connecting to azure.

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
  # The values are pre-built ruby primitives mapped from their corresponding types.
  # Here's an leemer: http://is.gd/g61xo
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
result.return_code  # => 420
client.return_code  # => 420
```


## Query Options

Every `TinyTds::Result` object can pass query options to the #each method. The defaults are defined and configurable by setting options in the `TinyTds::Client.default_query_options` hash. The default values are:

* :as => :hash - Object for each row yielded. Can be set to :array.
* :symbolize_keys => false - Row hash keys. Defaults to shared/frozen string keys.
* :cache_rows => true - Successive calls to #each returns the cached rows.
* :timezone => :local - Local to the ruby client or :utc for UTC.
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



## Using TinyTDS With Rails & The ActiveRecord SQL Server adapter.

As of version 2.3.11 & 3.0.3 of the adapter, you can specify a `:dblib` mode in database.yml and use TinyTDS as the low level connection mode, this is the default in versions 3.1 or higher. The SQL Server adapter can be found using the link below. Also included is a direct link to the wiki article covering common questions when using TinyTDS as the low level connection mode for the adapter.

* ActiveRecord SQL Server Adapter: http://github.com/rails-sqlserver/activerecord-sqlserver-adapter
* Using TinyTDS: http://github.com/rails-sqlserver/activerecord-sqlserver-adapter/wiki/Using-TinyTds


## Using TinyTDS with Azure

TinyTDS is fully tested with the Azure platform. You must set the `:azure => true` connection option when connecting. This is needed to specify the default database name in the login packet since Azure has no notion of `USE [database]`. You must use the latest FreeTDS 0.91. FreeTDS must be compiled with OpenSSL too.


## Using MiniPortile

MiniPortile is a minimalistic, simplistic and stupid implementation of a port/recipe system for developers. <https://github.com/luislavena/mini_portile>

The TinyTDS project uses MiniPortile so that we can easily install a local "project specific" version of FreeTDS and supporting libraries to link against when building a test version of TinyTDS. MiniPortile is a great tool that even allows us to build statically linked components that TinyTDS relies on. Hence this allows us to publish native gems for any platform. We use this feature for gems targeted at Windows.

You too can use MiniPortile to build TinyTDS and build your own gems for your own package management needs. Here is a few simple steps that assume you have cloned a fresh copy of this repository. 1) Bundling will install all the development dependencies. 2) Running `rake compile` will basically download and install a supported version of FreeTDS in our `ports.rake` file and supporting libraries. These will all be installed into the projects tmp directory. 3) The final `rake native gem` command will build a native gem for your specific platform. 4) The native gem can be found in the `pkg` directory. The last command assumes "X" is version numbers and #{platform} will be your platform.

```
$ bundle install
$ rake compile
$ rake native gem
$ gem install pkg/tiny_tds-X.X.X-#{platform}.gem
```

**Important:** You must use rubygems version 1.7.2 or higher. You will almost certainly hit a *Don't know how to build task...* error when running the `rake native gem` command if you do not. Please update rubygems! Here is a link on [how to upgrade or downgrade rubygems](http://rubygems.rubyforge.org/rubygems-update/UPGRADING_rdoc.html).


## Development & Testing  

We use bundler for development. Simply run `bundle install` then `rake` to build the gem and run the unit tests. The tests assume you have created a database named `tinytdstest` accessible by a database owner named `tinytds`. Before running the test rake task, you may need to define a pair of environment variables that help the client connect to your specific FreeTDS database server name and which schema (2000, 2005, 2008, Azure or Sybase ASE) to use. For example:

```
$ rake TINYTDS_UNIT_DATASERVER=mydbserver TINYTDS_SCHEMA=sqlserver_2008
  or
$ rake TINYTDS_UNIT_HOST=mydb.host.net TINYTDS_SCHEMA=sqlserver_azure
  or
$ rake TINYTDS_UNIT_HOST=mydb.host.net TINYTDS_UNIT_PORT=5000 TINYTDS_SCHEMA=sybase_ase
```

If you do not want to use MiniPortile to compile a local project version of FreeTDS and instead use your local system version, use the `TINYTDS_SKIP_PORTS` environment variable. This will ignore any port tasks and will instead build and link to your system's FreeTDS installation as a normal gem install would.

```
$ rake TINYTDS_SKIP_PORTS=true
```


## Help & Support

* Github Source: http://github.com/rails-sqlserver/tiny_tds
* Github Issues: http://github.com/rails-sqlserver/tiny_tds/issues
* Google Group: http://groups.google.com/group/rails-sqlserver-adapter
* IRC Room: #rails-sqlserver on irc.freenode.net


## TODO List

* Include OpenSSL with Windows binaries for SQL Azure.
* Install an interrupt handler.
* Allow #escape to accept all ruby primitives.


## About Me

My name is Ken Collins and I currently maintain the SQL Server adapter for ActiveRecord and wrote this library as my first cut into learning ruby C extensions. Hopefully it will help promote the power of ruby and the Rails framework to those that have not yet discovered it. My blog is http://metaskills.net and I can be found on twitter as @metaskills. Enjoy!


## Special Thanks

* Erik Bryn for joining the project and helping me thru a few tight spots. - http://github.com/ebryn
* To the authors and contributors of the Mysql2 gem for inspiration. - http://github.com/brianmario/mysql2
* Yehuda Katz for articulating ruby's need for proper encoding support. Especially in database drivers - http://yehudakatz.com/2010/05/05/ruby-1-9-encodings-a-primer-and-the-solution-for-rails/
* Josh Clayton of Thoughtbot for writing about ruby C extensions. - http://robots.thoughtbot.com/post/1037240922/get-your-c-on


## License

TinyTDS is Copyright (c) 2010-2011 Ken Collins, <ken@metaskills.net> and is distributed under the MIT license. Windows binaries contain precompiled versions of FreeTDS <http://www.freetds.org/> which is licensed under the GNU LGPL license at <http://www.gnu.org/licenses/lgpl-2.0.html>

