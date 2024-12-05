using namespace System.Collections.Generic
[NoRunspaceAffinity()]
class AsyncResult {
    [System.Object] $Async
    [System.Object] $Ps
    [System.Object] $Value

    # asycn result constructor
    AsyncResult($AsyncObject, $Runspace) {
        $this.Async = $AsyncObject
        $this.Ps    = $Runspace
    }

    # await async result value
    [System.Object] Await() {
        $Result = $null

        if ($this.Value) {
            return $this.Value
        }

        if ($null -ne $this.Ps -and $null -ne $this.Async) {
            while (!$this.Async.IsCompleted) {
                Start-Sleep -Milliseconds 10
            }

            try {
                if ($this.Async.IsCompleted) {
                    $Result = $this.Ps.EndInvoke($this.Async)
                    $this.Value = $Result
                }
            } catch {
                throw $_
            }
        }

        return $Result
    }

    # await async result value for n amount of seconds
    [System.Object] Await([Int] $TimeoutInSeconds) {
        $Result = $null

        if ($this.Value) {
            return $this.Value
        }

        if ($null -ne $this.Ps -and $null -ne $this.Async) {
            $Stopwatch = [System.Diagnostics.Stopwatch]::new()
            $Stopwatch.Start()

            while (!($this.Async.IsCompleted)) {
                if ($Stopwatch.Elapsed.TotalSeconds -gt $TimeoutInSeconds) {
                    throw [System.TimeoutException]::new("The operation timed out after $TimeoutInSeconds seconds.")
                }

                Start-Sleep -Milliseconds 10
            }

            try {
                if ($this.Async.IsCompleted) {
                    $Result = $this.Ps.EndInvoke($this.Async)
                    $this.Value = $Result
                }
            } catch {
                throw $_
            } finally {
                $Stopwatch.Stop()
            }
        }

        return $Result
    }

    # await all async results
    [System.Object] static AwaitAll([AsyncResult[]] $AsyncResults) {
        $ResultList = [List[pscustomobject]]::new()

        foreach ($Result in $AsyncResults) {
            # allow processing to continue if error is returned
            try {
                $ResultList.Add($Result.Await())
            } catch {
                $ResultList.Add($_)
            }
        }

        return $ResultList
    }

    # await the first async result to complete
    [System.Object] static AwaitAny([AsyncResult[]] $AsyncResults) {
        while ($AsyncResults.Async.IsCompleted -notcontains $true) {
            Start-Sleep -Milliseconds 10
        }

        return $AsyncResults.Where({$_.Async.IsCompleted -eq $true})[0].Await()
    }
}
