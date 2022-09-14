# frozen_string_literal: true

require "addressable/uri"

module HTMLProofer
  # Represents the element currently being processed
  class Element
    include HTMLProofer::Utils

    attr_reader :node, :url, :base_url, :line, :content

    def initialize(runner, node, base_url: nil)
      @runner = runner
      @node = node

      swap_attributes!

      @base_url = base_url
      @url = Attribute::Url.new(runner, link_attribute, base_url: base_url)

      @line = node.line
      @content = node.content
    end

    def link_attribute
      meta_content || src || srcset || href
    end

    def meta_content
      return nil unless meta_tag?

      @node["content"]
    end

    def meta_tag?
      @node.name == "meta"
    end

    def src
      return nil if !img_tag? && !script_tag? && !source_tag?

      @node["src"]
    end

    def img_tag?
      @node.name == "img"
    end

    def script_tag?
      @node.name == "script"
    end

    def srcset
      return nil if !img_tag? && !source_tag?

      @node["srcset"]
    end

    def source_tag?
      @node.name == "source"
    end

    def href
      return nil if !a_tag? && !link_tag?

      @node["href"]
    end

    def a_tag?
      @node.name == "a"
    end

    def link_tag?
      @node.name == "link"
    end

    def aria_hidden?
      @node.attributes["aria-hidden"]&.value == "true"
    end

    def multiple_srcsets?
      !blank?(srcset) && srcset.split(",").size > 1
    end

    def srcsets
      return nil if blank?(srcset)

      srcset.split(",").map(&:strip)
    end

    def multiple_sizes?
      return false if blank?(srcsets)

      srcsets.any? do |srcset|
        !blank?(srcset) && srcset.split(" ").size > 1
      end
    end

    def srcsets_wo_sizes
      return nil if blank?(srcsets)

      srcsets.map do |srcset|
        srcset.split(" ").first
      end
    end

    def ignore?
      return true if @node.attributes["data-proofer-ignore"]
      return true if ancestors_ignorable?

      return true if url&.ignore?

      false
    end

    private def attribute_swapped?
      return false if blank?(@runner.options[:swap_attributes])

      attrs = @runner.options[:swap_attributes][@node.name]

      return true unless blank?(attrs)
    end

    private def swap_attributes!
      return unless attribute_swapped?

      attr_swaps = @runner.options[:swap_attributes][@node.name]

      attr_swaps.flatten.each_slice(2) do |(old_attr, new_attr)|
        next if blank?(node[old_attr])

        node[new_attr] = node[old_attr]
        node.delete(old_attr)
      end
    end

    private def ancestors_ignorable?
      ancestors_attributes = @node.ancestors.map { |a| a.respond_to?(:attributes) && a.attributes }
      ancestors_attributes.pop # remove document at the end
      ancestors_attributes.any? { |a| !a["data-proofer-ignore"].nil? }
    end
  end
end
