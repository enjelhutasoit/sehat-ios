# frozen_string_literal: true

require "minitest/autorun"
require "xcode_selector"

class XcodeSelectorTest < Minitest::Test
  def test_picks_the_newest_xcode_of_the_requested_major_version
    paths = apps("Xcode_15.4.app", "Xcode_16.2.app", "Xcode_16.4.app", "Xcode_26.1.1.app")

    assert_equal "/Applications/Xcode_16.4.app", XcodeSelector.newest(paths, major: 16)
  end

  def test_compares_version_numbers_numerically_not_alphabetically
    paths = apps("Xcode_16.9.app", "Xcode_16.10.app")

    assert_equal "/Applications/Xcode_16.10.app", XcodeSelector.newest(paths, major: 16)
  end

  def test_understands_names_with_one_two_or_three_version_parts
    paths = apps("Xcode_16.app", "Xcode_16.1.app", "Xcode_16.1.1.app")

    assert_equal "/Applications/Xcode_16.1.1.app", XcodeSelector.newest(paths, major: 16)
  end

  def test_ignores_names_that_are_not_versioned_release_apps
    paths = apps("Xcode.app", "Xcode_16.4_beta.app", "Xcode_16.4.app.zip", "Xcode-16.4.app")

    assert_nil XcodeSelector.newest(paths, major: 16)
  end

  def test_returns_nil_when_no_xcode_has_the_requested_major_version
    assert_nil XcodeSelector.newest(apps("Xcode_15.4.app", "Xcode_26.1.app"), major: 16)
  end

  def test_returns_nil_for_an_empty_list
    assert_nil XcodeSelector.newest([], major: 16)
  end

  def test_returns_one_of_the_inputs_when_two_names_have_the_same_version
    paths = apps("Xcode_16.4.app", "Xcode_16.4.0.app")

    assert_includes paths, XcodeSelector.newest(paths, major: 16)
  end

  private

  def apps(*names)
    names.map { |name| "/Applications/#{name}" }
  end
end