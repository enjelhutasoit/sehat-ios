# frozen_string_literal: true

# Chooses the iPhone simulator for UI tests from the output of
# `xcrun simctl list devices available --json`.
#
# Rules: only iOS runtimes between `minimum_version` and `sdk_version`
# (inclusive; an Xcode cannot use runtimes newer than its SDK); the newest such
# runtime; an available iPhone; the base model (shortest name, then name).
module SimulatorPicker
  RUNTIME = /\.iOS-(\d+(?:-\d+)*)\z/

  Candidate = Struct.new(:udid, :name, :runtime_version)

  # Returns the UDID, or nil when nothing fits.
  def self.pick(listing, sdk_version:, minimum_version:)
    minimum = Gem::Version.new(minimum_version)
    maximum = Gem::Version.new(sdk_version)

    candidates = (listing["devices"] || {}).flat_map do |runtime, devices|
      match = RUNTIME.match(runtime)
      next [] unless match

      version = Gem::Version.new(match[1].tr("-", "."))
      next [] if version < minimum || version > maximum

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