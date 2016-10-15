using build

class Build : BuildPod {

	new make() {
		podName = "afBson"
		summary = "A BSON specification implementation"
		version = Version("1.1.1")

		meta = [
			"pod.displayName"	: "Bson",
			"repo.tags"			: "database",
			"repo.public"		: "true"		
		]

		depends = [
			"sys        1.0.69 - 1.0", 
			"inet       1.0.69 - 1.0",
			"concurrent 1.0.69 - 1.0"	// for ObjectId & Timestamp
		]

		srcDirs = [`fan/`, `fan/internal/`, `test/`]
		resDirs = [`doc/`]

		docApi = true
		docSrc = true
	}
}
