using build

class Build : BuildPod {

	new make() {
		podName = "afBson"
		summary = "A BSON specification implementation"
		version = Version("0.0.3")

		meta = [
			"org.name"		: "Alien-Factory",
			"org.uri"		: "http://www.alienfactory.co.uk/",
			"proj.name"		: "Bson",
			"proj.uri"		: "http://www.fantomfactory.org/pods/afBson",
			"vcs.uri"		: "https://bitbucket.org/AlienFactory/afbson",
			"license.name"	: "MIT Licence",	
			"repo.private"	: "true"
		]

		depends = [
			"sys 1.0", 
			
			"inet 1.0+",
			"concurrent 1.0+"	// ObjectId uses AtomicInt
		]

		srcDirs = [`test/`, `fan/`, `fan/internal/`]
		resDirs = [`doc/`]

		docApi = true
		docSrc = true
	}
	
	@Target { help = "Compile to pod file and associated natives" }
	override Void compile() {
		// exclude test code when building the pod
		srcDirs = srcDirs.exclude { it.toStr.startsWith("test/") }
		resDirs = resDirs.exclude { it.toStr.startsWith("res/test/") }
		
		super.compile
		
		// copy src to %FAN_HOME% for F4 debugging
		log.indent
		destDir := Env.cur.homeDir.plus(`src/${podName}/`)
		destDir.delete
		destDir.create		
		`fan/`.toFile.copyInto(destDir)		
		log.info("Copied `fan/` to ${destDir.normalize}")
		log.unindent
	}
}
