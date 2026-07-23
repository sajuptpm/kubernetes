package version

var (
	gitMajor = "1"
	gitMinor = "36"
	gitVersion   = "v1.36.3-k3s1"
	gitCommit    = "42e8cf8fa35589f096f5f2ae25802032799e9495"
	gitTreeState = "clean"
	buildDate = "2026-07-23T01:58:08Z"
)

const (
	// DefaultKubeBinaryVersion is the hard coded k8 binary version based on the latest K8s release.
	// It is supposed to be consistent with gitMajor and gitMinor, except for local tests, where gitMajor and gitMinor are "".
	// Should update for each minor release!
	DefaultKubeBinaryVersion = "1.36"
)
