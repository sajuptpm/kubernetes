package version

var (
	gitMajor = "1"
	gitMinor = "35"
	gitVersion   = "v1.35.7-k3s1"
	gitCommit    = "49036926cf24883d527d093e9b41fda9286732ae"
	gitTreeState = "clean"
	buildDate = "2026-07-23T01:55:36Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.35"
)
