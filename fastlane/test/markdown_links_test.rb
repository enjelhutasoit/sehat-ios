# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require "markdown_links"

class MarkdownLinksTest < Minitest::Test
  def test_reports_nothing_when_all_relative_links_exist
    in_repo("README.md" => "[a](docs/a.md) and ![img](docs/pic.png)", "docs/a.md" => "x", "docs/pic.png" => "x") do |root|
      assert_equal [], MarkdownLinks.broken(root)
    end
  end

  def test_reports_a_missing_target_with_the_file_that_contains_the_link
    in_repo("README.md" => "[gone](docs/missing.md)") do |root|
      assert_equal ["README.md: docs/missing.md"], MarkdownLinks.broken(root)
    end
  end

  def test_resolves_links_relative_to_the_file_that_contains_them
    in_repo("README.md" => "x", "docs/adr/one.md" => "[up](../../README.md) [bad](../nope.md)") do |root|
      assert_equal ["docs/adr/one.md: ../nope.md"], MarkdownLinks.broken(root)
    end
  end

  def test_ignores_external_links_mail_links_and_anchors
    text = "[w](https://example.com/x) [h](http://example.com) [m](mailto:a@b.c) [a](#section)"
    in_repo("README.md" => text) do |root|
      assert_equal [], MarkdownLinks.broken(root)
    end
  end

  def test_strips_fragments_and_queries_before_checking_the_file
    in_repo("README.md" => "[s](docs/a.md#intro) [q](docs/a.md?x=1)", "docs/a.md" => "x") do |root|
      assert_equal [], MarkdownLinks.broken(root)
    end
  end

  def test_ignores_links_inside_fenced_code_blocks
    text = "```\n[example](does/not/exist.md)\n```\n[real](docs/a.md)"
    in_repo("README.md" => text, "docs/a.md" => "x") do |root|
      assert_equal [], MarkdownLinks.broken(root)
    end
  end

  def test_checks_only_readme_and_docs_markdown_files
    in_repo("README.md" => "x", "notes/other.md" => "[bad](nope.md)", "docs/a.txt" => "[bad](nope.md)") do |root|
      assert_equal [], MarkdownLinks.broken(root)
    end
  end

  def test_reports_each_broken_link_once_per_occurrence_in_a_stable_order
    in_repo("README.md" => "[b](b.md) [a](a.md)", "docs/z.md" => "[c](c.md)") do |root|
      assert_equal ["README.md: b.md", "README.md: a.md", "docs/z.md: c.md"], MarkdownLinks.broken(root)
    end
  end

  private

  def in_repo(files)
    Dir.mktmpdir do |root|
      files.each do |path, content|
        full = File.join(root, path)
        FileUtils.mkdir_p(File.dirname(full))
        File.write(full, content)
      end
      yield root
    end
  end
end