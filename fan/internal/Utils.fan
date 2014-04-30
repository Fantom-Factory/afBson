
internal const mixin Utils {
	
	private static const DateTime unixEpoch := DateTime.fromJava(1) - 1ms

	static Log getLog(Type type) {
//		Log.get(type.pod.name + "." + type.name)
		type.pod.log
	}
	
	// see http://fantom.org/sidewalk/topic/2267
	static DateTime fromUnixEpoch(Int timeInMs) {
		timeInMs > 0
			? DateTime.fromJava(timeInMs)
			: unixEpoch + Duration(timeInMs * 1000000)
	}
	
}
