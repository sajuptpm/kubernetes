package version

var (
	gitMajor = "1"
	gitMinor = "35"
	gitVersion   = "v1.35.6-k3s1"
	gitCommit    = "ddf6b10b18fb5e9ce2a342b23e580472203532cf"
	gitTreeState = "clean"
	buildDate = "2026-06-12T14:54:20Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.35"
)
