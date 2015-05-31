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
}
