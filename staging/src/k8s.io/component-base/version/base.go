package version

var (
	gitMajor = "1"
	gitMinor = "34"
	gitVersion   = "v1.34.9-k3s2"
	gitCommit    = "6317045c672cb39941d0d147a00a472925398d33"
	gitTreeState = "clean"
	buildDate = "2026-06-24T04:09:35Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.34"
)
