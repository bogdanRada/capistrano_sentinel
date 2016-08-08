# frozen_string_literal: true
module CapistranoSentinel
  # helper used to determine gem versions
  class GemFinder
    class << self
      def gem_searcher
        if Gem::Specification.respond_to? :find
          # ruby 2.0
          Gem::Specification
        elsif Gem.respond_to? :searcher
          # ruby 1.8/1.9
          Gem.searcher.init_gemspecs
        end
      end

      def search_find_gemspec(searcher)
        return if searcher.nil?
        searcher.find do |specification|
          File.fnmatch(File.join(specification.full_gem_path, '*'), __FILE__)
        end
      end

      def fetch_current_gem_name
        searcher = gem_searcher
        spec = search_find_gemspec(searcher)
        spec.name unless value_blank?(spec)
      end

      def capistrano_version_2?
        cap_version = fetch_gem_version('capistrano')
        value_blank?(cap_version) ? false : verify_gem_version(cap_version, '3.0', operator: '<')
      end

      def value_blank?(value)
        value.nil? || value_empty?(value) || (value.is_a?(String) && /\A[[:space:]]*\z/.match(value))
      end

      def value_empty?(value)
        value.respond_to?(:empty?) ? value.empty? : !value
      end

      def find_loaded_gem(name, property = nil)
        gem_spec = Gem.loaded_specs.values.find { |repo| repo.name == name }
        return if value_blank?(gem_spec)
        value_blank?(property) ? gem_spec : gem_spec.send(property)
      end

      def find_loaded_gem_property(gem_name, property = 'version')
        find_loaded_gem(gem_name, property)
      end

      def fetch_gem_version(gem_name)
        version = find_loaded_gem_property(gem_name)
        value_blank?(version) ? nil : get_parsed_version(version)
      end

      def get_parsed_version(version)
        return 0 if value_blank?(version)
        version = version.to_s.split('.')
        version = format_gem_version(version)
        version.join('.').to_f
      end

      def format_gem_version(version)
        return version if version.size <= 2
        version.pop until version.size == 2
        version
      end

      def verify_gem_version(gem_version, version, options = {})
        version = get_parsed_version(version)
        get_parsed_version(gem_version).send(options.fetch('operator', '<='), version)
      end
    end
  end
end
