/**
 * @name Unsafe shiro deserialization
 * @kind path-problem
 * @id java/unsafe-shiro-deserialization
 */
import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSources
// import semmle.code.java.dataflow.TaintTracking
import DataFlow::PathGraph


predicate isDes(Expr arg){
    exists(MethodAccess des |
    des.getMethod().hasName("deserialize") 
    and
    arg = des.getArgument(0)
    )
}

class Deserialize extends RefType{
    Deserialize(){
        this.hasQualifiedName("com.summersec.shiroctf.Tools", "Tools")
    }
}

class DeserializeTobytes extends Method{
    DeserializeTobytes(){
        this.getDeclaringType() instanceof Deserialize
        and
        this.hasName("deserialize")
    }
}

class Myindex extends RefType{
    Myindex(){
        this.hasQualifiedName("com.summersec.shiroctf.controller", "IndexController")
    }
}

class MyindexTomenthod extends Method{
    MyindexTomenthod(){
        this.getDeclaringType().getAnAncestor() instanceof Myindex
        and
        this.hasName("index")
    }
}

class ShiroUnsafeDeserializationConfig extends DataFlow::Configuration {
    ShiroUnsafeDeserializationConfig() { 
        this = "StrutsUnsafeDeserializationConfig" 
    }

    override predicate isSource(DataFlow::Node source) {
        exists(DeserializeTobytes m |
            source.asParameter() = m.getParameter(0)
            // and
            // source instanceof RemoteFlowSource
        )
    }
    override predicate isSink(DataFlow::Node sink) {
        exists(Expr arg|
            isDes(arg) and
            sink.asExpr() = arg /* bytes */
        )
    }
    
    // override predicate isAdditionalFlowStep(DataFlow::Node n1 ,DataFlow::Node n2){
    //     exists(Call call |
    //         n1.asExpr() = call.getAnArgument() and
    //         n2.asExpr() = call
    //     )
    // }
    
    
}

// class CallTaintStep extends TaintTracking::AdditionalTaintStep {
//     override predicate step(DataFlow::Node n1, DataFlow::Node n2) {
//         exists(Call call |
//         n1.asExpr() = call.getAnArgument() and
//         n2.asExpr() = call
//         )
//     }
// }




from ShiroUnsafeDeserializationConfig config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "Unsafe shiro deserialization" ,source.getNode(), "this user input"

