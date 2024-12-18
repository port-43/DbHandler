# DbHandler
This module provides a class to work with databases using Odbc/SQLite .NET framework.

# Using the module
## Working with SQLite
The most basic constructor creates a DbHandler that works with sqlite. It accepts a full path to the sqlite database. Under the hood the class is implementing `System.Data.SqlLite`. The dll required is included in the packaged release of this module.
```powershell
# creating DbHandler object for SQLite connection
$Handler = [DbHandler]::new("C:\Path\to\sqlite.db")
```

## Working with Postgres/Odbc
To create a DbHandler to work with the Odbc .NET framework provide the following parameters in this order:
- Server hostname/ip address
- Database name
- Port
- Driver
- Credential

```powershell
# creating DbHandler object for Odbc connection
$Credential = Get-Credential -UserName 'username'
$Handler    = [DbHandler]::new('192.168.20.103', 'test_database', '5432', 'PostgreSQL UNICODE(x64)', $Credential)
```

## Querying data
### Synchronous
```powershell
# simple query
$Statement = "SELECT * FROM test_table"
$Handler.GetDatabaseData($Statement)

# using parameters
$Statement = "SELECT * FROM test_table WHERE name = @name"
$Param     = [ordered]@{name = "test"}
$Handler.GetDatabaseData($Statement, $Param)
```
### Asynchronous
```powershell
# async query
$Statement = "SELECT * FROM test_table"
$Result = $Handler.GetDatabaseDataAsync($Statement)

...do other work

$Result.Await()

# async await method chaining
$Statement = "SELECT * FROM test_table WHERE name = @name"
$Param     = [ordered]@{name = "test"}
$Result = $Handler.GetDatabaseDataAsync($Statement, $Param).Await()

# setting async await timeout in seconds
# will throw a timeout exception due to the query taking longer than the configured time of 1 second
$Statement = "SELECT pg_sleep(10) FROM test_table"
$Param     = [ordered]@{name = "test"}
$Result = $Handler.GetDatabaseDataAsync($Statement, $Param).Await(1)

# using asyncresult status method to await multiple results
$Statement1 = 'SELECT pg_sleep(2) as "two" FROM test_table1'
$Statement2 = 'SELECT pg_sleep(4) as "four" FROM test_table2'

$Result1 = $Handler.GetDatabaseDataAsync($Statement1)
$Result2 = $Handler.GetDatabaseDataAsync($Statement2)

[AsyncResult]::AwaitAll(@($Result1, $Result2)) # will return both results

# using asyncresult status method to await the first completed query
$Statement1 = 'SELECT pg_sleep(2) as "two" FROM test_table1'
$Statement2 = 'SELECT pg_sleep(4) as "four" FROM test_table2'

$Result1 = $Handler.GetDatabaseDataAsync($Statement1)
$Result2 = $Handler.GetDatabaseDataAsync($Statement2)

[AsyncResult]::AwaitAny(@($Result1, $Result2)) # will only return "two"
```
## Setting data
### Synchronous
```powershell
# simple statement
$Statement = "CREATE TABLE test_table (name varchar, fname varchar, lname varchar);"
$Handler.SetDatabaseData($Statement)

# using parameters
$Statement = "INSERT INTO test_table (name, fname, lname) VALUES (@name, @first, @last)"
$Param     = [ordered]@{name = "test"; first = "first"; last = "last"}
$Handler.SetDatabaseDataTransaction($Statement, $Param)

# using transactions
$Statement = "INSERT INTO test_table (name, fname, lname) VALUES (@name, @first, @last)"
$Param     = [ordered]@{name = "test"; first = "first"; last = "last"}
$Handler.SetDatabaseDataTransaction($Statement, $Param)

# set and get with parameters
$Statement = @"
UPDATE test_table
SET name = ?
WHERE id = ?
RETURNING *;
"@
$Param     = [ordered]@{name = "test"; id = 1}
$Handler.SetAndGetDatabaseData($Statement, $Param)

# set and get with parameters using transactions
$Statement = @"
UPDATE test_table
SET name = ?
WHERE id = ?
RETURNING *;
"@
$Param     = [ordered]@{name = "test"; id = 1}
$Handler.SetAndGetDatabaseDataTransaction($Statement, $Param)

# execute DDL statements (all DDL executions use transactions)
$Statement = @"
CREATE TABLE public.testing (
    name varchar
);
"@

$Handler.ExecuteDDL($Statement)
```
### Asynchronous
```powershell
# simple statement
$Statement = "CREATE TABLE test_table (name varchar, fname varchar, lname varchar);"
$Result = $Handler.SetDatabaseDataAsync($Statement).Await()

# using parameters
$Statement = "INSERT INTO test_table (name, fname, lname) VALUES (@name, @first, @last)"
$Param     = [ordered]@{name = "test"; first = "first"; last = "last"}
$Result = $Handler.SetDatabaseDataAsync($Statement, $Param).Await()

# using transactions
$Statement = "INSERT INTO test_table (name, fname, lname) VALUES (@name, @first, @last)"
$Param     = [ordered]@{name = "test"; first = "first"; last = "last"}
$Result = $Handler.SetDatabaseDataTransactionAsync($Statement, $Param).Await()

# set and get with parameters
$Statement = @"
UPDATE test_table
SET name = ?
WHERE id = ?
RETURNING *;
"@
$Param     = [ordered]@{name = "test"; id = 1}
$Handler.SetAndGetDatabaseDataAsync($Statement, $Param).Await()

# set and get with parameters using transactions
$Statement = @"
UPDATE test_table
SET name = ?
WHERE id = ?
RETURNING *;
"@
$Param     = [ordered]@{name = "test"; id = 1}
$Handler.SetAndGetDatabaseDataTransactionAsync($Statement, $Param).Await()

# execute DDL statements (all DDL executions use transactions)
$Statement = @"
CREATE TABLE public.testing (
    name varchar
);
"@

$Handler.ExecuteDDLAsync($Statement).Await()
```

## Logging/Debugging
The module also provides a built in logging that logs to stdout. To turn on logging set the `Debug` property value to true.
```powershell
# setting debug
$Handler.Debug = $true
```
There are two types of log formats supported, json and logfmt (json is the default). These can be managed via the `LogType` property.
```powershell
# setting log type
$Handler.LogType = 'logfmt'
$Handler.LogType = 'json'
```
Example log output:
```
# json
{"timestamp":"2024-04-30 12:04:00.383","level":"info","thread":25,"hostname":"C-3PO","method":"GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)","message":"Opening db connection"}
{"timestamp":"2024-04-30 12:04:00.396","level":"info","thread":25,"hostname":"C-3PO","method":"GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)","message":"Submitting query - SELECT * FROM test_table WHERE name = @name"}
{"timestamp":"2024-04-30 12:04:00.398","level":"info","thread":25,"hostname":"C-3PO","method":"GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)","message":"Parameters - name=test"}
{"timestamp":"2024-04-30 12:04:00.405","level":"info","thread":25,"hostname":"C-3PO","method":"GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)","message":"*Closing* db connection"}

# logfmt
timestamp="2024-04-30 12:09:05.406" level=info thread=25 hostname=C-3PO method="GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)" message="Opening db connection"
timestamp="2024-04-30 12:09:05.407" level=info thread=25 hostname=C-3PO method="GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)" message="Submitting query - SELECT * FROM test_table WHERE name = @name"
timestamp="2024-04-30 12:09:05.408" level=info thread=25 hostname=C-3PO method="GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)" message="Parameters - name=test"
timestamp="2024-04-30 12:09:05.408" level=info thread=25 hostname=C-3PO method="GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)" message="Closing db connection
```

## Considerations
### Parameters
As seen in the above examples the module supports providing parameters to the SQL statements to protect against SQL injection. However, not all Odbc drivers support named parameters but accept postional parameters instead (e.g. Postgres driver). In order to use positional parameters the code looks like the following:
```powershell
# positional parameter example
$Statement = 'SELECT * FROM test_table WHERE name = ? and last = ?'
$Param     = [ordered]@{name = "test"; lname = "last"}
$Handler.GetDatabaseData($Statement, $Param)
```
Of note, the key names `name` and `lname` do not matter, only the order in which they're defined impacts how they're used in the sql statement. The following would work the exact same:
```powershell
# positional parameter example
$Statement = 'SELECT * FROM test_table WHERE name = ? and last = ?'
$Param     = [ordered]@{asdf = "test"; qwer = "last"}
$Handler.GetDatabaseData($Statement, $Param)
```
### Connection Pooling
Connection pooling is handled by the driver with the .NET odbc framework automatically. Documentation defines that if the connection string is the exact same it will use the same connection pool.

### Multithreading
The class implements the [NoRunspaceAffinity](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_classes?view=powershell-7.4#norunspaceaffinity-attribute]) attribute which ensures that the class isn't affiliated with a particular runspace. This allows for using the class in scenarios such as the following:
```powershell
$Handler   = [DbHandler]::new("C:\Projects\sqlite\test.db")
$Statement = "SELECT * FROM test_table WHERE name = @name"

1..5 | Foreach-Object -ThrottleLimit 5 -Parallel {
    $DbHandler   = $using:Handler
    $DbStatement = $using:Statement

    $Param = [ordered]@{name = "test$_"}
    $DbHandler.GetDatabaseData($DbStatement, $Param)
}
```

If you want logging to to still work in a multithreaded environment you will need to explicitiy set `$InformationPreference = 'continue'` before. Of note, logging for the async commands will not be output to stdout due to the command running in a separate runspace. However, any errors will still surface once the async result is awaited.

### DDL Execution
The class calls `ExecuteNonQuery` to submit the DDL statements to the database. In general `ExecuteNonQuery` behaves in the following manner when returning values:
- For DML statements, `ExecuteNonQuery` returns the number of rows **affected** by the command.
- For DDL statements (e.g., CREATE TABLE), no rows are directly affected, so it typically returns:
  - `0` in many databases (e.g., SQL Server, MySQL, PostgreSQL)
  - `-1` in some database providers or configurations
