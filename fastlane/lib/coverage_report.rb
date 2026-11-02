# frozen_string_literal: true

# Builds the `llvm-cov report` command for one package.
module CoverageReport
  # Parts of a path that are never production logic of the package measured.
  # Views and Localization are excluded on purpose (ADR-0009, ADR-0013).
  ALWAYS_IGNORED = ['/\.build/', "/Tests/", "/Views/", "/Localization/"].freeze

  # Regular expression for `-ignore-filename-regex`: the always-ignored parts,
  # plus the sources of every other local package.
  def self.ignore_regex(package:, all_packages:)
    others = (all_packages - [package]).map { |name| Regexp.escape(name) }
    parts = ALWAYS_IGNORED.dup
    parts << "/Packages/(#{others.join('|')})/" unless others.empty?
    parts.join("|")
  end

  # Command (as an argument list) that prints the coverage table of `package`.
  # The profile data sits next to the JSON file named by
  # `swift test --show-codecov-path`.
  def self.arguments(package:, all_packages:, package_dir:, codecov_json_path:)
    binary = File.join(
      package_dir, ".build", "debug", "#{package}PackageTests.xctest",
      "Contents", "MacOS", "#{package}PackageTests"
    )
    profile = File.join(File.dirname(codecov_json_path), "default.profdata")

    [
      "xcrun", "llvm-cov", "report", binary,
      "-instr-profile=#{profile}",
      "-ignore-filename-regex=#{ignore_regex(package: package, all_packages: all_packages)}"
    ]
  end
end