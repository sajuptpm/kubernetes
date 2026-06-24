package version

var (
	gitMajor = "1"
	gitMinor = "35"
	gitVersion   = "v1.35.6-k3s2"
	gitCommit    = "60bea2b6e2e4886a237f76b2e7e36da45f6b5a83"
	gitTreeState = "clean"
	buildDate = "2026-06-24T03:58:45Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.35"
)
