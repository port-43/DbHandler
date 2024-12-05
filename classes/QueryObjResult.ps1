using namespace System.Collections.Specialized
using namespace System.Collections.Generic
using namespace System.Management.Automation
[NoRunspaceAffinity()]
class QueryObjResult : IQueryResult {
    [List[pscustomobject]] $Results
    [ErrorRecord] $Exception

    QueryObjResult() {}

    QueryObjResult([List[pscustomobject]] $ResultList, [ErrorRecord] $Exception) {
        $this.Results   = $ResultList
        $this.Exception = $Exception
    }
}
