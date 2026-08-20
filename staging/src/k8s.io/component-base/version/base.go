package version

var (
	gitMajor = "1"
	gitMinor = "34"
	gitVersion   = "v1.34.11-k3s1"
	gitCommit    = "1e89624cdeef5cacf1c43c0738161867393671a2"
	gitTreeState = "clean"
	buildDate = "2026-08-20T20:40:53Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.34"
)
