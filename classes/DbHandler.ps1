using namespace System.Collections.Specialized
using namespace System.Collections.Generic

[NoRunspaceAffinity()]
class DbHandler {
    # public attributes
    [string] $Server
    [string] $Database
    [string] $Port
    [string] $Driver
    [boolean] $Debug = $false
    [LogType] $LogType = [LogType]::json
    [DbType] $DbType
    [System.Management.Automation.Runspaces.RunspacePool] $RunspacePool

    # private attributes
    hidden [string] $ConnectionString

    # sqlite class constructor
    DbHandler([System.IO.FileInfo] $DbPath) {
        $this.DbType = [DbType]::SQLite
        $this.SetConnectionString($DbPath.FullName)
        $this.RunspacePool = [runspacefactory]::CreateRunspacePool(1, [Environment]::ProcessorCount)
        $this.RunspacePool.Open()
    }

    # # sqlite class constructor
    # DbHandler([System.IO.FileInfo] $DbPath, [SecureString] $Password) {
    #     $this.DbType = [DbType]::SQLite
    #     $this.SetConnectionString($DbPath.FullName, $Password)
    # }

    # convenience odbc class constructor
    DbHandler([hashtable] $Properties) {
        $this.Init($Properties)
        $this.RunspacePool = [runspacefactory]::CreateRunspacePool(1, [Environment]::ProcessorCount)
        $this.RunspacePool.Open()
    }

    # Odbc class constructor
    DbHandler([string] $Server, [string] $Database, [string] $Port, [string] $Driver, [pscredential] $Credential) {
        $this.Server   = $Server
        $this.Database = $Database
        $this.Port     = $Port
        $this.Driver   = $Driver
        $this.DbType   = [DbType]::Odbc
        $this.SetConnectionString($Server, $Database, $Port, $Driver, $Credential)
        $this.RunspacePool = [runspacefactory]::CreateRunspacePool(1, [Environment]::ProcessorCount)
        $this.RunspacePool.Open()
    }

    hidden [Void] Init([hashtable] $Properties) {
        foreach ($Property in $Properties.Keys) {
            try {
                $this.$Property = $Properties[$Property]
            } catch {
                [void] $_
            }
        }

        $this.SetConnectionString($Properties.Server, $Properties.Database, $Properties.Port, $Properties.Driver, $Properties.Credential)
    }

    # this method uses the odbc/sqlite .NET framework to retrieve data from a database. This method only accepts SELECT/PREPARE statements
    [List[pscustomobject]] GetDatabaseData ([string] $Statement) {
        $this.ValidateGetStatement($Statement)
        $Method = 'GetDatabaseData ([string] $Statement)'

        $this.Log('info','Querying database', $Method)

        return $this.ExecuteQuery($Statement)
    }

    # this method uses the odbc/sqlite .NET framework to retrieve data from a database with parameters. This method only accepts SELECT/PREPARE statements
    [List[pscustomobject]] GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateGetStatement($Statement)
        $Method = 'GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)'

        $this.Log('info','Querying database', $Method)

        return $this.ExecuteQuery($Statement, $Parameters)
    }

    # WIP - Testing out returning exceptions
    # [QueryObjResult] GetDatabaseDataT ([string] $Statement, [OrderedDictionary] $Parameters) {
    #     $this.ValidateGetStatement($Statement)
    #     $Method = 'GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)'
    #     $Result = $null
    #     $ThisError = $null

    #     $this.Log('info','Querying database', $Method)
    #     try {
    #         $Result = $this.ExecuteQuery($Statement, $Parameters)
    #     } catch {
    #         $ThisError = $_
    #     }

    #     return [QueryObjResult]::new($Result, $ThisError)
    # }

    # this async method uses the odbc/sqlite .NET framework to retrieve data from a database. This method only accepts SELECT/PREPARE statements
    [AsyncResult] GetDatabaseDataAsync ([string] $Statement) {
        $this.ValidateGetStatement($Statement)
        $Method = 'GetDatabaseDataAsync ([string] $Statement)'

        # Start a background job for the async operation
        $Job = [powershell]::Create().AddScript({
            param ($Statement, $Handler)
            $Handler.ExecuteQuery($Statement)
        }).AddArgument($Statement).AddArgument($this)

        $this.Log('info','Querying database asynchronously', $Method)

        $Job.RunspacePool = $this.RunspacePool
        $AsyncObject      = $Job.BeginInvoke()

        $this.Log('info','Returning async result', $Method)

        return [AsyncResult]::new($AsyncObject, $Job)
    }

    # this async method uses the odbc/sqlite .NET framework to retrieve data from a database with parameters. This method only accepts SELECT/PREPARE statements
    [AsyncResult] GetDatabaseDataAsync ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateGetStatement($Statement)
        $Method = 'GetDatabaseDataAsync ([string] $Statement, [OrderedDictionary] $Parameters)'

        $Job = [powershell]::Create().AddScript({
            param ($Statement, $Handler, $Parameters)
            $Handler.ExecuteQuery($Statement, $Parameters)
        }).AddArgument($Statement).AddArgument($this).AddArgument($Parameters)

        $this.Log('info','Querying database asynchronously', $Method)

        $Job.RunspacePool = $this.RunspacePool
        $AsyncObject      = $Job.BeginInvoke()

        $this.Log('info','Returning async result', $Method)

        return [AsyncResult]::new($AsyncObject, $Job)
    }

    # this method uses the odbc/sqlite .NET framework to update a database. This method only accepts UPDATE/INSERT/DELETE/CREATE/PREPARE statements
    [Int] SetDatabaseData ([string] $Statement) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseData ([string] $Statement)'

        $this.Log('info','Updating database', $Method)

        return $this.ExecuteNonQuery($Statement)
    }

    # this method uses the odbc/sqlite .NET framework to update a database with parameters. This method only accepts UPDATE/INSERT/DELETE/CREATE/PREPARE statements
    [Int] SetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)'

        $this.Log('info','Updating database', $Method)

        return $this.ExecuteNonQuery($Statement, $Parameters)
    }

    # this async method uses the odbc/sqlite .NET framework to update a database. This method only accepts UPDATE/INSERT/DELETE/CREATE/PREPARE statements
    [AsyncResult] SetDatabaseDataAsync ([string] $Statement) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseDataAsync ([string] $Statement)'

        # Start a background job for the async operation
        $Job = [powershell]::Create().AddScript({
            param ($Statement, $Handler)
            $Handler.ExecuteNonQuery($Statement)
        }).AddArgument($Statement).AddArgument($this)

        $this.Log('info','Updating database asynchronously', $Method)

        $Job.RunspacePool = $this.RunspacePool
        $AsyncObject      = $Job.BeginInvoke()

        $this.Log('info','Returning async result', $Method)

        return [AsyncResult]::new($AsyncObject, $Job)
    }

    # this async method uses the odbc/sqlite .NET framework to update a database with parameters. This method only accepts UPDATE/INSERT/DELETE/CREATE/PREPARE statements
    [AsyncResult] SetDatabaseDataAsync ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseDataAsync ([string] $Statement, [OrderedDictionary] $Parameters)'

        # Start a background job for the async operation
        $Job = [powershell]::Create().AddScript({
            param ($Statement, $Handler, $Parameters)
            $Handler.ExecuteNonQuery($Statement, $Parameters)
        }).AddArgument($Statement).AddArgument($this).AddArgument($Parameters)

        $this.Log('info','Updating database asynchronously', $Method)

        $Job.RunspacePool = $this.RunspacePool
        $AsyncObject      = $Job.BeginInvoke()

        $this.Log('info','Returning async result', $Method)

        return [AsyncResult]::new($AsyncObject, $Job)
    }

    # this method uses the odbc/sqlite .NET framework to update a database using transactions. This method only accepts UPDATE/INSERT/DELETE/CREATE/PREPARE statements
    [Int] SetDatabaseDataTransaction ([string] $Statement) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseDataTransaction ([string] $Statement)'

        $this.Log('info','Updating database', $Method)

        return $this.ExecuteNonQueryTransaction($Statement)
    }

    # this method uses the odbc/sqlite .NET framework to update a database with parameters using transactions. This method only accepts UPDATE/INSERT/DELETE/CREATE statements
    [Int] SetDatabaseDataTransaction ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseDataTransaction ([string] $Statement. [OrderedDictionary] $Parameters)'

        $this.Log('info','Updating database', $Method)

        return $this.ExecuteNonQueryTransaction($Statement, $Parameters)
    }

    # this async method uses the odbc/sqlite .NET framework to update a database using transactions. This method only accepts UPDATE/INSERT/DELETE/CREATE/PREPARE statements
    [AsyncResult] SetDatabaseDataTransactionAsync ([string] $Statement) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseDataTransactionAsync ([string] $Statement)'

        # Start a background job for the async operation
        $Job = [powershell]::Create().AddScript({
            param ($Statement, $Handler)
            $Handler.ExecuteNonQueryTransaction($Statement)
        }).AddArgument($Statement).AddArgument($this)

        $this.Log('info','Updating database asynchronously', $Method)

        $Job.RunspacePool = $this.RunspacePool
        $AsyncObject      = $Job.BeginInvoke()

        $this.Log('info','Returning async result', $Method)

        return [AsyncResult]::new($AsyncObject, $Job)
    }

    # this async method uses the odbc/sqlite .NET framework to update a database with parameters using transactions. This method only accepts UPDATE/INSERT/DELETE/CREATE statements
    [AsyncResult] SetDatabaseDataTransactionAsync ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseDataTransactionAsync ([string] $Statement,  [OrderedDictionary] $Parameters)'

        # Start a background job for the async operation
        $Job = [powershell]::Create().AddScript({
            param ($Statement, $Handler, $Parameters)
            $Handler.ExecuteNonQueryTransaction($Statement, $Parameters)
        }).AddArgument($Statement).AddArgument($this).AddArgument($Parameters)

        $this.Log('info','Updating database asynchronously', $Method)

        $Job.RunspacePool = $this.RunspacePool
        $AsyncObject      = $Job.BeginInvoke()

        $this.Log('info','Returning async result', $Method)

        return [AsyncResult]::new($AsyncObject, $Job)
    }

    # this method uses the odbc/sqlite .NET framework to set and retrieve data from a database. This method only accepts statements that UPDATE with a RETURNING clause
    [List[pscustomobject]] SetAndGetDatabaseData ([string] $Statement) {
        $this.ValidateSetAndGetStatement($Statement)
        $Method = 'SetAndGetDatabaseData ([string] $Statement)'

        $this.Log('info','Querying database', $Method)

        return $this.ExecuteQuery($Statement)
    }

    # this method uses the odbc/sqlite .NET framework to set and retrieve data from a database with parameters. This method only accepts statements that UPDATE with a RETURNING clause
    [List[pscustomobject]] SetAndGetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateSetAndGetStatement($Statement)
        $Method = 'SetAndGetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)'

        $this.Log('info','Querying database', $Method)

        return $this.ExecuteQuery($Statement, $Parameters)
    }

    # this async method uses the odbc/sqlite .NET framework to set and retrieve data from a database. This method only accepts statements that UPDATE with a RETURNING clause
    [AsyncResult] SetAndGetDatabaseDataAsync ([string] $Statement) {
        $this.ValidateSetAndGetStatement($Statement)
        $Method = 'SetAndGetDatabaseDataAsync ([string] $Statement)'

        # Start a background job for the async operation
        $Job = [powershell]::Create().AddScript({
            param ($Statement, $Handler)
            $Handler.ExecuteQuery($Statement)
        }).AddArgument($Statement).AddArgument($this)

        $this.Log('info','Updating database and retrieving data asynchronously', $Method)

        $Job.RunspacePool = $this.RunspacePool
        $AsyncObject      = $Job.BeginInvoke()

        $this.Log('info','Returning async result', $Method)

        return [AsyncResult]::new($AsyncObject, $Job)
    }

    # this async method uses the odbc/sqlite .NET framework to set and retrieve data from a database with parameters. This method only accepts statements that UPDATE with a RETURNING clause
    [AsyncResult] SetAndGetDatabaseDataAsync ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateSetAndGetStatement($Statement)
        $Method = 'SetAndGetDatabaseDataAsync ([string] $Statement, [OrderedDictionary] $Parameters)'

        # Start a background job for the async operation
        $Job = [powershell]::Create().AddScript({
            param ($Statement, $Handler, $Parameters)
            $Handler.ExecuteQuery($Statement, $Parameters)
        }).AddArgument($Statement).AddArgument($this).AddArgument($Parameters)

        $this.Log('info','Updating database and retrieving data asynchronously', $Method)

        $Job.RunspacePool = $this.RunspacePool
        $AsyncObject      = $Job.BeginInvoke()

        $this.Log('info','Returning async result', $Method)

        return [AsyncResult]::new($AsyncObject, $Job)
    }

    # this method uses the odbc/sqlite .NET framework to set and retrieve data from a database using transactions. This method only accepts statements that UPDATE with a RETURNING clause
    [List[pscustomobject]] SetAndGetDatabaseDataTransaction ([string] $Statement) {
        $this.ValidateSetAndGetStatement($Statement)
        $Method = 'SetAndGetDatabaseDataTransaction ([string] $Statement)'

        $this.Log('info','Querying database', $Method)

        return $this.ExecuteQueryTransaction($Statement)
    }

    # this method uses the odbc/sqlite .NET framework to set and retrieve data from a database with parameters using transactions. This method only accepts statements that UPDATE with a RETURNING clause
    [List[pscustomobject]] SetAndGetDatabaseDataTransaction ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateSetAndGetStatement($Statement)
        $Method = 'SetAndGetDatabaseDataTransaction ([string] $Statement, [OrderedDictionary] $Parameters)'

        $this.Log('info','Querying database', $Method)

        return $this.ExecuteQueryTransaction($Statement, $Parameters)
    }

    # this async method uses the odbc/sqlite .NET framework to set and retrieve data from a database using transactions. This method only accepts statements that UPDATE with a RETURNING clause
    [AsyncResult] SetAndGetDatabaseDataTransactionAsync ([string] $Statement) {
        $this.ValidateSetAndGetStatement($Statement)
        $Method = 'SetAndGetDatabaseDataTransactionAsync ([string] $Statement)'

        $Job = [powershell]::Create().AddScript({
            param ($Statement, $Handler)
            $Handler.ExecuteQueryTransaction($Statement)
        }).AddArgument($Statement).AddArgument($this)

        $this.Log('info','Updating database and retrieving data asynchronously', $Method)

        $Job.RunspacePool = $this.RunspacePool
        $AsyncObject      = $Job.BeginInvoke()

        $this.Log('info','Returning async result', $Method)

        return [AsyncResult]::new($AsyncObject, $Job)
    }

    # this async method uses the odbc/sqlite .NET framework to set and retrieve data from a database with parameters using transactions. This method only accepts statements that UPDATE with a RETURNING clause
    [AsyncResult] SetAndGetDatabaseDataTransactionAsync ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateSetAndGetStatement($Statement)
        $Method = 'SetAndGetDatabaseDataTransactionAsync ([string] $Statement, [OrderedDictionary] $Parameters)'

        $Job = [powershell]::Create().AddScript({
            param ($Statement, $Handler, $Parameters)
            $Handler.ExecuteQueryTransaction($Statement, $Parameters)
        }).AddArgument($Statement).AddArgument($this).AddArgument($Parameters)

        $this.Log('info','Updating database and retrieving data asynchronously', $Method)

        $Job.RunspacePool = $this.RunspacePool
        $AsyncObject      = $Job.BeginInvoke()

        $this.Log('info','Returning async result', $Method)

        return [AsyncResult]::new($AsyncObject, $Job)
    }

    # this method executes a standard query and returns the results
    [List[pscustomobject]] hidden ExecuteQuery([string] $Statement) {
        $Method = 'ExecuteQuery ([string] $Statement)'
        $Records = [List[pscustomobject]]::new()
        $DBConnection = $this.CreateConnection()
        $DBConnection.ConnectionString = $this.ConnectionString

        try {
            # Opening DB connection
            $this.Log('info','Opening db connection', $Method)
            $DBConnection.Open()
            $DBCommand = $DBConnection.CreateCommand();
            $DBCommand.CommandText = $Statement

            $this.Log('info',"Submitting query - $Statement", $Method)
            $Reader = $DBCommand.ExecuteReader()
            $FieldCount = $Reader.FieldCount

            # Record data while there are records being returned
            while ($Reader.read()) {
                $Record = [ordered]@{}
                for ($i = 0; $i -lt $FieldCount; $i++) {
                    # cast boolean values
                    if ($Reader.GetDataTypeName($i) -eq 'bool') {
                        # need to cast to int first due to being a string
                        $Record.add($Reader.GetName($i), [bool] [int] $Reader.GetValue($i))
                    } else {
                        $Record.add($Reader.GetName($i), $Reader.GetValue($i))
                    }
                }
                if ($Record) {
                    $Records.add([pscustomobject]$Record)
                }
            }

            return $Records
        } catch {
            $this.Log('error',$_.Exception.Message, $Method)
            throw $_
        } finally {
            $this.Log('info','Closing db connection', $Method)

            if ($Reader) {
                $Reader.Dispose()
            }

            $DBConnection.Close()
        }
    }

    # this method executes a standard query with parameters and returns the results
    [List[pscustomobject]] hidden ExecuteQuery([string] $Statement, [OrderedDictionary] $Parameters) {
        $Method = 'ExecuteQuery ([string] $Statement, [OrderedDictionary] $Parameters)'
        $Records = [List[pscustomobject]]::new()
        $DBConnection = $this.CreateConnection()
        $DBConnection.ConnectionString = $this.ConnectionString
        $Bindings = @()

        try {
            # Opening DB connection
            $this.Log('info','Opening db connection', $Method)
            $DBConnection.Open()
            $DBCommand = $DBConnection.CreateCommand();
            $DBCommand.CommandText = $Statement

            foreach ($Key in $Parameters.Keys) {
                [void] $DBCommand.Parameters.AddWithValue("@$Key",$Parameters[$Key])
                $Bindings += "$Key=$($Parameters[$Key])"
            }

            $this.Log('info',"Submitting query - $Statement", $Method)
            $this.Log('info',"Parameters - $($Bindings -join ', ')", $Method)
            $Reader = $DBCommand.ExecuteReader()
            $FieldCount = $Reader.FieldCount

            # Record data while there are records being returned
            while ($Reader.read()) {
                $Record = [ordered]@{}
                for ($i = 0; $i -lt $FieldCount; $i++) {
                    # cast boolean values
                    if ($Reader.GetDataTypeName($i) -eq 'bool') {
                        # need to cast to int first due to being a string
                        $Record.add($Reader.GetName($i), [bool] [int] $Reader.GetValue($i))
                    } else {
                        $Record.add($Reader.GetName($i), $Reader.GetValue($i))
                    }
                }
                if ($Record) {
                    $Records.add([pscustomobject]$Record)
                }
            }

            return $Records
        } catch {
            $this.Log('error',$_.Exception.Message, $Method)
            throw $_
        } finally {
            $this.Log('info','Closing db connection', $Method)

            if ($Reader) {
                $Reader.Dispose()
            }

            $DBConnection.Close()
        }
    }

    # this method executes a standard query and returns the results
    [List[pscustomobject]] hidden ExecuteQueryTransaction([string] $Statement) {
        $Method = 'ExecuteQueryTransaction ([string] $Statement)'
        $Records = [List[pscustomobject]]::new()
        $DBConnection = $this.CreateConnection()
        $DBConnection.ConnectionString = $this.ConnectionString
        $Transaction = $null

        try {
            # Opening DB connection
            $this.Log('info','Opening db connection', $Method)
            $DBConnection.Open()
            $Transaction = $DBConnection.BeginTransaction()
            $DBCommand = $DBConnection.CreateCommand();
            $DBCommand.CommandText = $Statement
            $DBCommand.Transaction = $Transaction

            $this.Log('info',"Submitting query - $Statement", $Method)
            $Reader = $DBCommand.ExecuteReader()
            $FieldCount = $Reader.FieldCount

            # Record data while there are records being returned
            while ($Reader.read()) {
                $Record = [ordered]@{}
                for ($i = 0; $i -lt $FieldCount; $i++) {
                    # cast boolean values
                    if ($Reader.GetDataTypeName($i) -eq 'bool') {
                        # need to cast to int first due to being a string
                        $Record.add($Reader.GetName($i), [bool] [int] $Reader.GetValue($i))
                    } else {
                        $Record.add($Reader.GetName($i), $Reader.GetValue($i))
                    }
                }
                if ($Record) {
                    $Records.add([pscustomobject]$Record)
                }
            }

            $Transaction.Commit()

            return $Records
        } catch {
            $this.Log('error',$_.Exception.Message, $Method)
            $Transaction.Rollback()
            throw $_
        } finally {
            $this.Log('info','Closing db connection', $Method)

            if ($Reader) {
                $Reader.Dispose()
            }

            $DBConnection.Close()
        }
    }

    # this method executes a standard query and returns the results
    [List[pscustomobject]] hidden ExecuteQueryTransaction([string] $Statement, [OrderedDictionary] $Parameters) {
        $Method = 'ExecuteQueryTransaction ([string] $Statement, [OrderedDictionary] $Parameters)'
        $Records = [List[pscustomobject]]::new()
        $DBConnection = $this.CreateConnection()
        $DBConnection.ConnectionString = $this.ConnectionString
        $Transaction = $null
        $Bindings = @()

        try {
            # Opening DB connection
            $this.Log('info','Opening db connection', $Method)
            $DBConnection.Open()
            $Transaction = $DBConnection.BeginTransaction()
            $DBCommand = $DBConnection.CreateCommand();
            $DBCommand.CommandText = $Statement

            foreach ($Key in $Parameters.Keys) {
                [void] $DBCommand.Parameters.AddWithValue("@$Key",$Parameters[$Key])
                $Bindings += "$Key=$($Parameters[$Key])"
            }

            $DBCommand.Transaction = $Transaction

            $this.Log('info',"Submitting query - $Statement", $Method)
            $this.Log('info',"Parameters - $($Bindings -join ', ')", $Method)
            $Reader = $DBCommand.ExecuteReader()
            $FieldCount = $Reader.FieldCount

            # Record data while there are records being returned
            while ($Reader.read()) {
                $Record = [ordered]@{}
                for ($i = 0; $i -lt $FieldCount; $i++) {
                    # cast boolean values
                    if ($Reader.GetDataTypeName($i) -eq 'bool') {
                        # need to cast to int first due to being a string
                        $Record.add($Reader.GetName($i), [bool] [int] $Reader.GetValue($i))
                    } else {
                        $Record.add($Reader.GetName($i), $Reader.GetValue($i))
                    }
                }
                if ($Record) {
                    $Records.add([pscustomobject]$Record)
                }
            }

            $Transaction.Commit()

            return $Records
        } catch {
            $this.Log('error',$_.Exception.Message, $Method)
            $Transaction.Rollback()
            throw $_
        } finally {
            $this.Log('info','Closing db connection', $Method)

            if ($Reader) {
                $Reader.Dispose()
            }

            $DBConnection.Close()
        }
    }

    # this method executes a sql statement and returns the number of rows affected
    [Int] hidden ExecuteNonQuery ([string] $Statement) {
        $Method = 'ExecuteNonQuery ([string] $Statement)'
        $DBConnection = $this.CreateConnection()
        $DBConnection.ConnectionString = $this.ConnectionString

        try {
            $this.Log('info','Opening db connection', $Method)
            $DBConnection.Open()
            $DBCommand = $DBConnection.CreateCommand();
            $DBCommand.CommandText = $Statement

            $this.Log('info',"Submitting query - $Statement", $Method)
            $RowsAffectedCount = $DBCommand.ExecuteNonQuery()

            return $RowsAffectedCount
        } catch {
            $this.Log('error',$_.Exception.Message, $Method)
            throw $_
        } finally {
            $this.Log('info','Closing db connection', $Method)
            $DBConnection.Close()
        }
    }

    # this method executes a sql statement with parameters and returns the number of rows affected
    [Int] hidden ExecuteNonQuery ([string] $Statement, [OrderedDictionary] $Parameters) {
        $Method = 'ExecuteNonQuery ([string] $Statement, [OrderedDictionary] $Parameters)'
        $DBConnection = $this.CreateConnection()
        $DBConnection.ConnectionString = $this.ConnectionString
        $Bindings = @()

        try {
            $this.Log('info','Opening db connection', $Method)
            $DBConnection.Open()
            $DBCommand = $DBConnection.CreateCommand();
            $DBCommand.CommandText = $Statement

            foreach ($Key in $Parameters.Keys) {
                [Void] $DBCommand.Parameters.AddWithValue("@$Key",$Parameters[$Key])
                $Bindings += "$Key=$($Parameters[$Key])"
            }

            $this.Log('info',"Submitting query - $Statement", $Method)
            $this.Log('info',"Parameters - $($Bindings -join ', ')", $Method)
            $RowsAffectedCount = $DBCommand.ExecuteNonQuery()

            return $RowsAffectedCount
        } catch {
            $this.Log('error',$_.Exception.Message, $Method)
            throw $_
        } finally {
            $this.Log('info','Closing db connection', $Method)
            $DBConnection.Close()
        }
    }

    # this method executes a transact-sql statement and returns the number of rows affected
    [Int] hidden ExecuteNonQueryTransaction ([string] $Statement) {
        $Method = 'ExecuteNonQueryTransaction ([string] $Statement)'
        $DBConnection = $this.CreateConnection()
        $DBConnection.ConnectionString = $this.ConnectionString
        $Transaction = $null

        try {
            $this.Log('info','Opening db connection', $Method)
            $DBConnection.Open()
            $Transaction = $DBConnection.BeginTransaction()
            $DBCommand = $DBConnection.CreateCommand();
            $DBCommand.CommandText = $Statement
            $DBCommand.Transaction = $Transaction

            $this.Log('info',"Submitting query - $Statement", $Method)
            $RowsAffectedCount = $DBCommand.ExecuteNonQuery()
            $Transaction.Commit()
            return $RowsAffectedCount
        } catch {
            $this.Log('error',$_.Exception.Message, $Method)
            $Transaction.Rollback()
            throw $_
        } finally {
            $this.Log('info','Closing db connection', $Method)
            $DBConnection.Close()
        }
    }

    # this method executes a transact-sql statement with parameters and returns the number of rows affected
    [Int] hidden ExecuteNonQueryTransaction ([string] $Statement, [OrderedDictionary] $Parameters) {
        $Method = 'ExecuteNonQueryTransaction ([string] $Statement, [OrderedDictionary] $Parameters)'
        $DBConnection = $this.CreateConnection()
        $DBConnection.ConnectionString = $this.ConnectionString
        $Transaction = $null
        $Bindings = @()

        try {
            $this.Log('info','Opening db connection', $Method)
            $DBConnection.Open()
            $Transaction = $DBConnection.BeginTransaction()
            $DBCommand = $DBConnection.CreateCommand();
            $DBCommand.CommandText = $Statement

            foreach ($Key in $Parameters.Keys) {
                [Void] $DBCommand.Parameters.AddWithValue("@$Key",$Parameters[$Key])
                $Bindings += "$Key=$($Parameters[$Key])"
            }

            $DBCommand.Transaction = $Transaction

            $this.Log('info',"Submitting query - $Statement", $Method)
            $this.Log('info',"Parameters - $($Bindings -join ', ')", $Method)
            $RowsAffectedCount = $DBCommand.ExecuteNonQuery()
            $Transaction.Commit()
            return $RowsAffectedCount
        } catch {
            $this.Log('error',$_.Exception.Message, $Method)
            $Transaction.Rollback()
            throw $_
        } finally {
            $this.Log('info','Closing db connection', $Method)
            $DBConnection.Close()
        }
    }

    # create db connection object
    [System.Object] hidden CreateConnection() {
        return ($this.DbType -eq [DbType]::Odbc) ? [System.Data.Odbc.OdbcConnection]::new() : [System.Data.SQLite.SQLiteConnection]::new()
    }

    # [void] ChangePassword([SecureString] $Password) {
    #     $Method = 'ChangePassword([SecureString] $Password)'

    #     $DBConnection = $this.CreateConnection()
    #     $DBConnection.ConnectionString = $this.ConnectionString
    #     try {
    #         $this.Log('info','Opening db connection', $Method)
    #         $DBConnection.Open()

    #         $this.Log('info','Changing Password', $Method)
    #         $DBConnection.ChangePassword([pscredential]::new('placeholder', $Password).GetNetworkCredential().Password)
    #     } catch {
    #         $this.Log('error',$_.Exception.Message, $Method)
    #         throw $_
    #     } finally {
    #         $this.Log('info','Closing db connection', $Method)
    #         $DBConnection.Close()
    #     }
    # }

    # set sqlite connection string
    [Void] SetConnectionString([String] $DbPath) {
        $this.ConnectionString = "Data Source=$DbPath"
    }

    # set sqlite connection string
    # [Void] SetConnectionString([String] $DbPath, [SecureString] $Password) {
    #     $this.ConnectionString = ("Data Source=$DbPath;Password={0}" -f [pscredential]::new('placeholder', $Password).GetNetworkCredential().Password)
    # }

    # set the database connection string
    [Void] SetConnectionString([string] $Server, [string] $Database, [string] $Port, [string] $Driver, [pscredential] $Credential) {
        $ConnectionStringBuilder = [System.Data.Odbc.OdbcConnectionStringBuilder]::new()
        $ConnectionStringBuilder.Driver = $Driver
        $ConnectionStringBuilder.add('Server',$Server)
        $ConnectionStringBuilder.add('Port',$Port)
        $ConnectionStringBuilder.add('Database',$Database)
        $ConnectionStringBuilder.add('Uid',$Credential.Username)
        $ConnectionStringBuilder.add('Pwd',$Credential.GetNetworkCredential().Password)

        $this.ConnectionString = $ConnectionStringBuilder.ConnectionString
    }

    # this method logs details to stdout
    [Void] Log([LogLevel] $Level, [string] $Message, [string] $Method) {
        if (!$this.Debug) {
            return
        }

        $Timestamp = Get-Date -format "yyyy-MM-dd HH:mm:ss.fff"
        $StructuredLog = [ordered]@{
            timestamp = $timestamp
            level     = $Level.ToString()
            thread    = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            hostname  = $env:COMPUTERNAME;
            method    = $Method
            message   = $Message
        }

        switch ($this.LogType) {
            ([LogType]::json) {
                $StructuredLog | ConvertTo-Json -Compress | Write-Information -InformationAction Continue
            }
            ([LogType]::logfmt) {
                $KeyValueList = [System.Collections.Generic.List[string]]::new()
                foreach ($Key in $StructuredLog.Keys) {
                    if ($StructuredLog[$Key] -match '\s') {
                        $KeyValueList.Add("$Key=`"$($StructuredLog[$Key])`"")
                    } else {
                        $KeyValueList.Add("$Key=$($StructuredLog[$Key])")
                    }
                }

                $KeyValueList -join " " | Write-Information -InformationAction Continue
            }
        }
    }

    # dispose of runspace pool
    [Void] Dispose() {
        if ($null -ne $this.RunspacePool) {
            $this.RunspacePool.Close()
            $this.RunspacePool.Dispose()
        }
    }

    # validate the get statement
    [Void] hidden ValidateGetStatement ([string] $Statement) {
        if ([string]::IsNullOrEmpty($Statement)) {
            throw "Statement must not be null"
        }

        if ($Statement -notmatch '^SELECT|^PREPARE') {
            throw "Statement is invalid"
        }
    }

    # validate the set statement
    [Void] hidden ValidateSetStatement ([string] $Statement) {
        if ([string]::IsNullOrEmpty($Statement)) {
            throw "Statement must not be null"
        }

        if ($Statement -notmatch '^UPDATE|^INSERT|^DELETE|^PREPARE|^CREATE') {
            throw "Statement is invalid"
        }
    }

    # validate the set and get statement
    [Void] hidden ValidateSetAndGetStatement ([string] $Statement) {
        if ([string]::IsNullOrEmpty($Statement)) {
            throw "Statement must not be null"
        }

        if ($Statement -notmatch '^UPDATE') {
            throw "Statement is invalid, must begin with UPDATE"
        }

        if ($Statement -notmatch 'RETURNING\b.*?;') {
            throw "Statement is invalid, must have a RETURNING statement"
        }
    }
}

Enum LogType {
    json   = 1
    logfmt = 2
}

Enum LogLevel {
    info    = 1
    trace   = 2
    warning = 3
    error   = 4
}

Enum DbType {
    Odbc   = 1
    SQLite = 2
}
