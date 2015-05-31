using build

class Build : BuildPod {

	new make() {
		podName = "afBson"
		summary = "A BSON specification implementation"
		version = Version("1.0.0")

		meta = [
			"proj.name"		: "Bson",
			"repo.tags"		: "database",
			"repo.public"	: "true"		
		]

		depends = [
			"sys        1.0", 
			
			"inet       1.0",
			"concurrent 1.0"	// ObjectId uses AtomicInt
		]

		srcDirs = [`test/`, `fan/`, `fan/internal/`]
		resDirs = [`doc/`]

		docApi = true
		docSrc = true
	}
}
