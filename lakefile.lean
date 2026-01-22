import Lake
open Lake DSL

package markup where
  version := v!"0.1.0"
  leanOptions := #[
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩
  ]

require scribe from git "https://github.com/nathanial/scribe" @ "v0.0.2"
require crucible from git "https://github.com/nathanial/crucible" @ "v0.0.9"
require sift from git "https://github.com/nathanial/sift" @ "v0.0.5"

@[default_target]
lean_lib Markup where
  roots := #[`Markup]

lean_lib Tests where
  roots := #[`Tests]
  globs := #[.submodules `Tests]

@[test_driver]
lean_exe markup_tests where
  root := `Tests.Main
