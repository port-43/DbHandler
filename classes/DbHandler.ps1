using namespace System.Collections.Specialized

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

    # private attributes
    hidden [string] $ConnectionString

    # sqlite class constructor
    DbHandler([System.IO.FileInfo] $DbPath) {
        $this.DbType = [DbType]::SQLite
        $this.SetConnectionString($DbPath.FullName)
    }

    # # sqlite class constructor
    # DbHandler([System.IO.FileInfo] $DbPath, [SecureString] $Password) {
    #     $this.DbType = [DbType]::SQLite
    #     $this.SetConnectionString($DbPath.FullName, $Password)
    # }

    # Odbc class constructor
    DbHandler([string] $Server, [string] $Database, [string] $Port, [string] $Driver, [pscredential] $Credential) {
        $this.Server   = $Server
        $this.Database = $Database
        $this.Port     = $Port
        $this.Driver   = $Driver
        $this.DbType   = [DbType]::Odbc
        $this.SetConnectionString($Server, $Database, $Port, $Driver, $Credential)
    }

    # this method uses the odbc/sqlite .NET framework to retrieve data from a database. This method only accepts SELECT/PREPARE statements
    [Array] GetDatabaseData ([string] $Statement) {
        $this.ValidateGetStatement($Statement)
        $Method = 'GetDatabaseData ([string] $Statement)'

        $Records = [System.Collections.Generic.List[pscustomobject]]::new()
        $DBConnection = $this.CreateConnection()
        $DBConnection.ConnectionString = $this.ConnectionString

        try {
            $this.Log('info','Opening db connection', $Method)
            $DBConnection.Open()
            $DBCommand = $DBConnection.CreateCommand();
            $DBCommand.CommandText = $Statement

            $this.Log('info',"Submitting query - $Statement", $Method)
            $Reader = $DBCommand.ExecuteReader()
            $FieldCount = $Reader.FieldCount

            # record data while there are records being returned
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
            $Reader.Dispose()
            $DBConnection.Close()
        }
    }

    # this method uses the odbc/sqlite .NET framework to retrieve data from a database with parameters. This method only accepts SELECT/PREPARE statements
    [Array] GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateGetStatement($Statement)
        $Method = 'GetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)'

        $Records = [System.Collections.Generic.List[pscustomobject]]::new()
        $DBConnection = $this.CreateConnection()
        $DBConnection.ConnectionString = $this.ConnectionString
        $Bindings = @()

        try {
            $this.Log('info','Opening db connection', $Method)
            $DBConnection.Open()
            $DBCommand = $DBConnection.CreateCommand();
            $DBCommand.CommandText = $Statement

            foreach ($Key in $Parameters.Keys) {
                $DBCommand.Parameters.AddWithValue("@$Key",$Parameters[$Key])
                $Bindings += "$Key=$($Parameters[$Key])"
            }

            $this.Log('info',"Submitting query - $Statement", $Method)
            $this.Log('info',"Parameters - $($Bindings -join ', ')", $Method)
            $Reader = $DBCommand.ExecuteReader()
            $FieldCount = $Reader.FieldCount

            # record data while there are records being returned
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
            $Reader.Dispose()
            $DBConnection.Close()
        }
    }

    # this method uses the odbc/sqlite .NET framework to update a database. This method only accepts UPDATE/INSERT/DELETE/CREATE/PREPARE statements
    [Int] SetDatabaseData ([string] $Statement) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseData ([string] $Statement)'

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

    # this method uses the odbc/sqlite .NET framework to update a database with parameters. This method only accepts UPDATE/INSERT/DELETE/CREATE/PREPARE statements
    [Int] SetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseData ([string] $Statement, [OrderedDictionary] $Parameters)'

        $DBConnection = $this.CreateConnection()
        $DBConnection.ConnectionString = $this.ConnectionString
        $Bindings = @()

        try {
            $this.Log('info','Opening db connection', $Method)
            $DBConnection.Open()
            $DBCommand = $DBConnection.CreateCommand();
            $DBCommand.CommandText = $Statement

            foreach ($Key in $Parameters.Keys) {
                $DBCommand.Parameters.AddWithValue("@$Key",$Parameters[$Key])
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

    # this method uses the odbc/sqlite .NET framework to update a database using transactions. This method only accepts UPDATE/INSERT/DELETE/CREATE/PREPARE statements
    [Int] SetDatabaseDataTransaction ([string] $Statement) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseDataTransaction ([string] $Statement)'

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

    # this method uses the odbc/sqlite .NET framework to update a database with parameters using transactions. This method only accepts UPDATE/INSERT/DELETE/CREATE statements
    [Int] SetDatabaseDataTransaction ([string] $Statement, [OrderedDictionary] $Parameters) {
        $this.ValidateSetStatement($Statement)
        $Method = 'SetDatabaseDataTransaction ([string] $Statement. [OrderedDictionary] $Parameters)'

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
                $DBCommand.Parameters.AddWithValue("@$Key",$Parameters[$Key])
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
