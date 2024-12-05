using namespace System.Collections.Specialized
using namespace System.Collections.Generic
using namespace System.Management.Automation
[NoRunspaceAffinity()]
class QueryIntResult : IQueryResult {
    [List[int]] $Results
    [ErrorRecord] $Exception

    QueryIntResult() {}

    QueryIntResult([List[int]] $ResultList, [ErrorRecord] $Exception) {
        $this.Results = $ResultList
        $this.Exception  = $Exception
    }
}
