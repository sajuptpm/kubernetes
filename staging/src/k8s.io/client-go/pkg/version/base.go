package version

var (
	gitMajor = "1"
	gitMinor = "34"
	gitVersion   = "v1.34.10-k3s1"
	gitCommit    = "01290011892f1547f074ba105a1dd497f5a9a2e5"
	gitTreeState = "clean"
	buildDate = "2026-07-23T01:52:42Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.34"
)
