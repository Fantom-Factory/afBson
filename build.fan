using build

class Build : BuildPod {

	new make() {
		podName = "afBson"
		summary = "A BSON specification implementation"
		version = Version("2.0.5")

		meta = [
			"pod.dis"		: "Bson",
			"repo.tags"		: "database",
			"repo.public"	: "true"
		]

		depends = [
			"sys        1.0.71 - 1.0",
			"concurrent 1.0.71 - 1.0"	// for ObjectId & Timestamp
		]

		srcDirs = [`fan/`, `fan/internal/`, `test/`]
		resDirs = [`doc/`]

		docApi = true
		docSrc = true
	}
}
