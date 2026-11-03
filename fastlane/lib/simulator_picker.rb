# frozen_string_literal: true

# Chooses the iPhone simulator for UI tests from the output of
# `xcrun simctl list devices available --json`.
#
# Rules:
# 1. If `FASTLANE_EXPLICIT_SIMULATOR_VERSION` is provided in the environment,
#    force the picker to match that exact runtime version (bypassing SDK checks).
# 2. Otherwise, fallback to standard rule: only target iOS runtimes between
#    `minimum_version` and `sdk_version` (inclusive).
# 3. From the filtered runtimes, pick the newest one available on an iPhone base model.
module SimulatorPicker
  RUNTIME = /\.iOS-(\d+(?:-\d+)*)\z/

  Candidate = Struct.new(:udid, :name, :runtime_version)

  def self.pick(listing, sdk_version:, minimum_version:)
    # Check if there is specified version locally
    local_override = ENV["FASTLANE_EXPLICIT_SIMULATOR_VERSION"]

    minimum = Gem::Version.new(minimum_version)
    maximum = Gem::Version.new(sdk_version)

    candidates = (listing["devices"] || {}).flat_map do |runtime, devices|
      match = RUNTIME.match(runtime)
      next [] unless match

      version = Gem::Version.new(match[1].tr("-", "."))
      
      # If override exists, match exactly. Otherwise, use original SDK range.
      if local_override
        next [] if version != Gem::Version.new(local_override)
      else
        next [] if version < minimum || version > maximum
      end

      devices.filter_map { |device| candidate(device, version) }
    end

    newest = candidates.map(&:runtime_version).max
    candidates
      .select { |candidate| candidate.runtime_version == newest }
      .min_by { |candidate| [candidate.name.length, candidate.name, candidate.udid] }
      &.udid
  end

  def self.candidate(device, version)
    name = device["name"].to_s
    return unless name.start_with?("iPhone") && available?(device)

    Candidate.new(device["udid"], name, version)
  end

  def self.available?(device)
    device["isAvailable"] != false && !device["availability"].to_s.include?("unavailable")
  end

  private_class_method :candidate, :available?
end
