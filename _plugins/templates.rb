# frozen_string_literal: false

# This file is licensed under the MIT License (MIT) available on
# http://opensource.org/licenses/MIT.

# templates.rb generates all translated pages using templates in
# _templates. The final file name of each page is defined in
# the url section of each translations in _translations.

require 'yaml'
require 'cgi'

module Jekyll
  class TranslatePage < Page
    def initialize(site, base, lang, srcdir, src, dstdir, dst)
      @site = site
      @base = base
      @dir = '/' + dstdir
      @name = dst
      process(dst)
      read_yaml(File.join(base, srcdir), src)
      data['lang'] = lang
    end
  end
  class TranslatePageGenerator < Generator
    def generate(site)
      # load translations files
      locs = {}
      enabled = ENV['ENABLED_LANGS']
      enabled = enabled.split(' ') unless enabled.nil?
      Dir.foreach('_translations') do |file|
        next if (file == '.') || (file == '..') || (file == 'COPYING')

        lang = file.split('.')[0]
        # Ignore lang if disabled
        if (lang != 'en') && !enabled.nil? && !enabled.include?(lang)
          print 'Lang ' + lang + ' disabled' + "\n"
          next
        end
        locs[lang] = YAML.load_file('_translations/' + file)[lang]
      end
      # Generate each translated page based on templates
      Dir.mkdir(site.dest) unless File.directory?(site.dest)
      locs.each do |lang, _value|
        Dir.foreach('_templates') do |file|
          next if (file == '.') || (file == '..')

          id = file.split('.')[0]
          dst = locs[lang]['url'][id]
          next if dst.nil? || (dst == '')

          src = file
          ## For files ending in a slash, such as path/to/dir/, give them
          ## the index.html file name
          dst.gsub!(%r{/$}, '/index')

          dst += '.html'
          site.pages << TranslatePage.new(site, site.source, lang, '_templates', src, lang, dst)
        end
        site.pages << TranslatePage.new(site, site.source, lang, '_templates', 'index.html', lang, 'index.html')
      end
    end
  end
end
