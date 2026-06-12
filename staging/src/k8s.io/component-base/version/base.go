package version

var (
	gitMajor = "1"
	gitMinor = "36"
	gitVersion   = "v1.36.2-k3s1"
	gitCommit    = "a43b86b0d70359d525ad6c5a70353381969e7056"
	gitTreeState = "clean"
	buildDate = "2026-06-12T14:55:54Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.36"
)
