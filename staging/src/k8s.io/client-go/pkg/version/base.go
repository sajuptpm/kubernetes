package version

var (
	gitMajor = "1"
	gitMinor = "36"
	gitVersion   = "v1.36.2-k3s2"
	gitCommit    = "d98d5fe745c811d737d52cf60d3a37ba60378574"
	gitTreeState = "clean"
	buildDate = "2026-06-24T03:46:22Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.36"
)
