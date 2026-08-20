package version

var (
	gitMajor = "1"
	gitMinor = "36"
	gitVersion   = "v1.36.4-k3s1"
	gitCommit    = "e3a7a0affccfb4b93f38c2937252822be0481223"
	gitTreeState = "clean"
	buildDate = "2026-08-20T20:44:11Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.36"
)
