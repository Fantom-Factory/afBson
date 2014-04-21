using concurrent

internal class BsonTest : Test {

	LogRec[] logMsgs {
		get { Actor.locals["test.logs"] }
		set { }
	}

	private	Func logFunc := |LogRec rec| { (Actor.locals["test.logs"] as LogRec[]).add(rec) }
	
	override Void setup() {
		Actor.locals["test.logs"] = LogRec[,]
		Log.addHandler(logFunc)
	}
	
	override Void teardown() {
		Log.removeHandler(logFunc)
	}
	
	protected Void verifyErrMsg(Type errType, Str errMsg, |Obj| func) {
		try {
			func(4)
		} catch (Err e) {
			if (!e.typeof.fits(errType)) 
				throw Err("Expected $errType got $e.typeof", e)
			verifyEq(errMsg, e.msg)	// this gives the Str comparator in eclipse
			return
		}
		throw Err("$errType not thrown")
	}
	
}
