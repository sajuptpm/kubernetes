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
	gitVersion   = "v1.33.13-k3s1"
	gitCommit    = "b7b1192af1dd5d34bcc771d4af1078e09ffaa059"
	gitTreeState = "clean"
	buildDate = "2026-06-12T14:47:33Z"
)
