# frozen_string_literal: true

require "minitest/autorun"
require "simulator_picker"

class SimulatorPickerTest < Minitest::Test
  def test_picks_an_iphone_from_the_newest_runtime_the_sdk_supports
    json = listing(
      "iOS-17-5" => [device("iPhone 15", "A")],
      "iOS-18-2" => [device("iPhone 16", "B")],
      "iOS-26-0" => [device("iPhone 17", "C")]
    )

    assert_equal "B", pick(json)
  end

  def test_accepts_runtimes_equal_to_the_minimum_and_to_the_sdk_version
    assert_equal "A", pick(listing("iOS-17-0" => [device("iPhone 15", "A")]))
    assert_equal "B", pick(listing("iOS-18-2" => [device("iPhone 16", "B")]))
  end

  def test_ignores_runtimes_older_than_the_minimum
    assert_nil pick(listing("iOS-16-4" => [device("iPhone 14", "A")]))
  end

  def test_ignores_runtimes_newer_than_the_sdk
    assert_nil pick(listing("iOS-26-0" => [device("iPhone 17", "A")]))
  end

  def test_ignores_other_platforms_and_non_iphone_devices
    json = listing(
      "tvOS-18-2" => [device("Apple TV", "A")],
      "watchOS-11-2" => [device("Apple Watch", "B")],
      "iOS-18-2" => [device("iPad Pro", "C")]
    )

    assert_nil pick(json)
  end

  def test_ignores_devices_that_are_not_available
    json = listing(
      "iOS-18-2" => [device("iPhone 16", "A", available: false), device("iPhone 16 Plus", "B")]
    )

    assert_equal "B", pick(json)
  end

  def test_ignores_devices_marked_unavailable_by_the_older_availability_field
    unavailable = { "name" => "iPhone 16", "udid" => "A", "availability" => "(unavailable, runtime profile not found)" }
    json = listing("iOS-18-2" => [unavailable, device("iPhone 16 Plus", "B")])

    assert_equal "B", pick(json)
  end

  def test_prefers_the_base_model_by_choosing_the_shortest_name
    json = listing(
      "iOS-18-2" => [device("iPhone 16 Pro Max", "A"), device("iPhone 16 Plus", "B"), device("iPhone 16", "C")]
    )

    assert_equal "C", pick(json)
  end

  def test_breaks_ties_by_name_so_the_choice_does_not_depend_on_list_order
    first_order = listing("iOS-18-2" => [device("iPhone 16", "B"), device("iPhone 15", "A")])
    second_order = listing("iOS-18-2" => [device("iPhone 15", "A"), device("iPhone 16", "B")])

    assert_equal "A", pick(first_order)
    assert_equal "A", pick(second_order)
  end

  def test_compares_runtime_versions_numerically
    json = listing(
      "iOS-18-9" => [device("iPhone 16", "A")],
      "iOS-18-10" => [device("iPhone 17", "B")]
    )

    assert_equal "B", pick(json, sdk: "18.10")
  end

  def test_returns_nil_when_nothing_is_listed
    assert_nil pick({ "devices" => {} })
    assert_nil pick({})
  end

  private

  def pick(json, sdk: "18.2", minimum: "17.0")
    SimulatorPicker.pick(json, sdk_version: sdk, minimum_version: minimum)
  end

  def device(name, udid, available: true)
    { "name" => name, "udid" => udid, "isAvailable" => available }
  end

  def listing(runtimes)
    { "devices" => runtimes.transform_keys { |version| "com.apple.CoreSimulator.SimRuntime.#{version}" } }
  end
end