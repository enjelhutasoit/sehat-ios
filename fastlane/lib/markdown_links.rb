# frozen_string_literal: true

# Finds relative links in the project's Markdown files that point to files
# that do not exist. External links, mail links and anchors are not checked,
# and neither are links inside fenced code blocks.
module MarkdownLinks
  PATTERN = "{README.md,docs/**/*.md}"
  LINK = /\[[^\]]*\]\(([^)\s]+)\)/
  FENCE = /^\s*```.*?^\s*```/m
  SKIPPED = %r{\A(?:[a-z][a-z0-9+.-]*:|#)}i

  # "path/of/file.md: target" for each broken link, files in path order.
  def self.broken(root)
    Dir.glob(File.join(root, PATTERN)).sort.flat_map do |file|
      relative = file.delete_prefix("#{root}/")
      targets(File.read(file)).filter_map do |target|
        "#{relative}: #{target}" unless File.exist?(File.expand_path(path_of(target), File.dirname(file)))
      end
    end
  end

  def self.targets(text)
    text.gsub(FENCE, "").scan(LINK).flatten.reject { |target| target.match?(SKIPPED) }
  end

  def self.path_of(target)
    target.split(/[#?]/, 2).first
  end

  private_class_method :targets, :path_of
end