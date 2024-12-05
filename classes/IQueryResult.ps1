using namespace System.Collections.Specialized
using namespace System.Collections.Generic
using namespace System.Management.Automation
[NoRunspaceAffinity()]
class IQueryResult {
    [List[object]] $Results
    [ErrorRecord] $Exception

    IQueryResult() {}

    IQueryResult([List[pscustomobject]] $ResultList, [ErrorRecord] $Exception) {
        $this.Results   = $ResultList
        $this.Exception = $Exception
    }
}
