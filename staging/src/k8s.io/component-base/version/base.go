package version

var (
	gitMajor = "1"
	gitMinor = "35"
	gitVersion   = "v1.35.8-k3s1"
	gitCommit    = "62d383842e5f6c61b9fe268458ec23704b30c2d5"
	gitTreeState = "clean"
	buildDate = "2026-08-20T20:42:35Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.35"
)
