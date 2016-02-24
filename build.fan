using build

class Build : BuildPod {

	new make() {
		podName = "afBson"
		summary = "A BSON specification implementation"
		version = Version("1.0.1")

		meta = [
			"proj.name"		: "Bson",
			"repo.tags"		: "database",
			"repo.public"	: "false"		
		]

		depends = [
			"sys        1.0", 
			
			"inet       1.0",
			"concurrent 1.0"	// ObjectId uses AtomicInt
		]

		srcDirs = [`fan/`, `fan/internal/`, `test/`]
		resDirs = [`doc/`]

		docApi = true
		docSrc = true
	}
}
