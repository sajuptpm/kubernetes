package version

var (
	gitMajor = "1"
	gitMinor = "34"
	gitVersion   = "v1.34.9-k3s1"
	gitCommit    = "88e7cd5bd37cf2e527a817a5d84d99781abd0eb9"
	gitTreeState = "clean"
	buildDate = "2026-06-12T14:51:50Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.34"
)
