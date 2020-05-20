using concurrent

** Nicked and reduced from 'afConcurrent'.
** 
** Provides 'synchronized' access to blocks of code. Example usage:
** 
** pre>
** syntax: fantom
**  
** lock := Synchronized(ActorPool())
** 
** val := lock.synchronized |->Obj?| {
**     // ...
**     // important stuff
**     // ...
**     return 69
** }
** <pre
internal const class BsonSynchronized {
	private static const Log	log 	:= BsonSynchronized#.pod.log
	
	** The 'Actor' used to process all sync and async calls.
	@NoDoc  const Actor 		actor

	** The default timeout to use when waiting for 'synchronized' blocks to complete.
	** 
	** The default timeout of 'null' blocks forever.
	const Duration? timeout
	
	** Create a 'Synchronized' class from the given 'ActorPool' and timeout.
	** 
	** The default timeout of 'null' blocks forever.
	new make(ActorPool actorPool, Duration? timeout := null, |This|? f := null) {
		this.actor	 = Actor(actorPool, |Obj? obj -> Obj?| { receive(obj) })
		this.timeout = timeout
		f?.call(this)
	}

	** Runs the given func asynchronously, using this Synchronized's 'ActorPool'.
	** 
	** Errs that occur within the block are logged but not rethrown unless you call 'get()' on 
	** the returned 'Future'. 
	** 
	** The given func and return value must be immutable.
	Future async(|->Obj?| f) {
		// explicit call to .toImmutable() - see http://fantom.org/sidewalk/topic/1798#c12190
		func	:= f.toImmutable
		future 	:= actor.send([true, func].toImmutable)
		return future	// sounds cool, huh!?
	}

	** Runs the given func asynchronously, after the given duration has elapsed.
	** 
	** Errs that occur within the block are logged but not rethrown unless you call 'get()' on 
	** the returned 'Future'. 
	** 
	** The given func and return value must be immutable.
	Future asyncLater(Duration d, |->Obj?| f) {
		// explicit call to .toImmutable() - see http://fantom.org/sidewalk/topic/1798#c12190
		func	:= f.toImmutable
		future 	:= actor.sendLater(d, [true, func].toImmutable)
		return future	// sounds cool, huh!?
	}

	** This effectively wraps the given func in a Java 'synchronized { ... }' block and returns its
	** calculated value. 
	** 
	** The given func and return value must be immutable.
	Obj? synchronized(|->Obj?| f) {
		// explicit call to .toImmutable() - see http://fantom.org/sidewalk/topic/1798#c12190
		func	:= f.toImmutable
		future	:= actor.send([false, func].toImmutable)

		try {
			return future.get(timeout)
		} catch (IOErr err) {
			throw err.msg.contains("Not serializable") ? IOErr("Synchronized return type ${f.returns.signature} is not immutable or serializable", err) : err
		}
	}
	
	private Obj? receive(Obj[] msg) {
		logErr	:= msg[0] as Bool
		func 	:= msg[1] as |->Obj?|

		try {
			return func.call()

		} catch (Err e) {
			// log the Err so the thread doesn't fail silently
			if (logErr)
				log.err("This Err is being logged to avoid it being swallowed as Errs thrown in async {...} blocks do not propagate to the calling thread.", e)
			throw e
		}
	}	
}
