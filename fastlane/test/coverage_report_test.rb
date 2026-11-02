# frozen_string_literal: true

require "minitest/autorun"
require "coverage_report"

class CoverageReportTest < Minitest::Test
  ALL = %w[SehatCore SehatDomain SehatPersistence].freeze

  def test_ignore_regex_excludes_build_tests_views_and_localization
    regex = CoverageReport.ignore_regex(package: "SehatCore", all_packages: ["SehatCore"])

    assert_equal '/\.build/|/Tests/|/Views/|/Localization/', regex
  end

  def test_ignore_regex_excludes_the_other_packages_but_not_the_one_measured
    regex = CoverageReport.ignore_regex(package: "SehatDomain", all_packages: ALL)

    assert_includes regex, "/Packages/(SehatCore|SehatPersistence)/"
    refute_includes regex, "SehatDomain"
  end

  def test_ignore_regex_matches_the_expected_paths
    regex = Regexp.new(CoverageReport.ignore_regex(package: "SehatDomain", all_packages: ALL))

    assert_match regex, "/r/Packages/SehatCore/Sources/SehatCore/AppError.swift"
    assert_match regex, "/r/Packages/SehatDomain/Tests/SehatDomainTests/Some.swift"
    assert_match regex, "/r/Packages/SehatDomain/.build/checkouts/Other.swift"
    refute_match regex, "/r/Packages/SehatDomain/Sources/SehatDomain/Consultation/Consultation.swift"
  end

  def test_arguments_build_the_llvm_cov_report_command
    args = CoverageReport.arguments(
      package: "SehatCore",
      all_packages: ALL,
      package_dir: "/r/Packages/SehatCore",
      codecov_json_path: "/r/Packages/SehatCore/.build/arm64-apple-macosx/debug/codecov/SehatCore.json"
    )

    assert_equal %w[xcrun llvm-cov report], args.first(3)
    assert_equal(
      "/r/Packages/SehatCore/.build/debug/SehatCorePackageTests.xctest/Contents/MacOS/SehatCorePackageTests",
      args[3]
    )
    assert_equal(
      "-instr-profile=/r/Packages/SehatCore/.build/arm64-apple-macosx/debug/codecov/default.profdata",
      args[4]
    )
    assert args[5].start_with?("-ignore-filename-regex=")
  end
end