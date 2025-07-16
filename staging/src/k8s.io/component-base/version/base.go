package version

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.31"
)

var (
	gitMajor = "1"
	gitMinor = "33"
	gitVersion   = "v1.33.3-k3s1"
	gitCommit    = "5a12bfb95082aea01e67312c91878aff93944471"
	gitTreeState = "clean"
	buildDate = "2025-07-16T14:38:43Z"
)
