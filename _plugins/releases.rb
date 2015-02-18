# This file is licensed under the MIT License (MIT) available on
# http://opensource.org/licenses/MIT.

#releases.rb generates release pages using files in _releases
#and assign them the 'release' category.

#This is later used to loop through site.pages in order
#to display the release's list in version order, both
#on the "Version history" page and RSS file.

# This plugin also finds the highest required_sort_order_version of
# Bitcoin Core and populates the Download page with variables set in
# that release file

require 'yaml'

module Jekyll

  class ReleasePage < Page

    def initialize(site, base, lang, srcdir, src, output_directory)
      @site = site
      @base = base
      @dir = '/' + output_directory

      ## Read in the file's YAML header
      self.read_yaml(File.join(base, srcdir), src)

      ## Die if required_ variables aren't set
      if self.data['required_version']
        version = self.data['required_version']
      else
        abort("Error: Variable required_version not set when processing " + src)
      end

      if self.data['required_title']
        self.data['required_title'].gsub!('%v', version)
      else
        abort("Error: Variable required_title not set when processing " + src)
      end

      if self.data['required_sort_order_version']
        self.data['required_sort_order_version'].gsub!('%v', version)
      else
        abort("Error: Variable required_sort_order_version not set when processing " + src)
      end

      ## Output file is v<version>.md (converted later to HTML)
      output_file = "v" + version + ".md"
      @name = output_file
      self.process(output_file)

      ## Title required for <title></title> in _layouts/base.html
      self.data['title'] = self.data['required_title']

      ## For translation, but currently always set to "en"
      self.data['lang'] = lang

      ## Only processes numeric version numbers with up to five decimals
      self.data['versionint'] = versiontoint(self.data['required_sort_order_version'])

      self.data['layout'] = 'release'
      self.data['category'] = 'release'

      ## If this is the highest version we've seen so far...
      if !site.config.has_key?('DOWNLOAD_VERSION') or site.config['DOWNLOAD_VERSIONINT'] < self.data['versionint']
        site.config['DOWNLOAD_VERSIONINT'] = self.data['versionint']
        site.config['DOWNLOAD_VERSION'] = self.data['required_version']

        ## Download URLs, with %v in URL replaced with the current version string
        site.config['url_sha256sums'] = self.data['required_sha256sums'] ? self.data['required_sha256sums'].gsub('%v', version) : nil
        site.config['url_torrent']   = self.data['optional_torrent']   ? self.data['optional_torrent'  ].gsub('%v', version) : nil
        site.config['url_sourcetar'] = self.data['optional_sourcetar'] ? self.data['optional_sourcetar'].gsub('%v', version) : nil
        site.config['url_win32zip']  = self.data['optional_win32zip']  ? self.data['optional_win32zip' ].gsub('%v', version) : nil
        site.config['url_win64zip']  = self.data['optional_win64zip']  ? self.data['optional_win64zip' ].gsub('%v', version) : nil
        site.config['url_win32exe']  = self.data['optional_win32exe']  ? self.data['optional_win32exe' ].gsub('%v', version) : nil
        site.config['url_win64exe']  = self.data['optional_win64exe']  ? self.data['optional_win64exe' ].gsub('%v', version) : nil
        site.config['url_macdmg']    = self.data['optional_macdmg']    ? self.data['optional_macdmg'   ].gsub('%v', version) : nil
        site.config['url_mactar']    = self.data['optional_mactar']    ? self.data['optional_mactar'   ].gsub('%v', version) : nil
        site.config['url_lin32']     = self.data['optional_lin32']     ? self.data['optional_lin32'    ].gsub('%v', version) : nil
        site.config['url_lin64']     = self.data['optional_lin64']     ? self.data['optional_lin64'    ].gsub('%v', version) : nil

        ## No %v => version substition on magnet URL
        site.config['url_magnetlink'] = self.data['optional_magnetlink'] ? self.data['optional_magnetlink'] : nil

      end
    end

    def versiontoint(v)
      x = 0
      ar = v.split('.').map{|s| s.to_i}
      ar.each_index do |k|
        x += ar[k] * (1000 ** (5 - k))
      end
      return x
    end

  end

  class ReleasePageGenerator < Generator
    def generate(site)

      #Do nothing if plugin is disabled
      if !ENV['ENABLED_PLUGINS'].nil? and ENV['ENABLED_PLUGINS'].index('releases').nil?
        print 'Releases disabled' + "\n"
        return
      end

      #generate each release based on templates
      Dir.foreach('_releases') do |file|
        next if file == '.' or file == '..'
        lang = 'en'
        src = file
        srcdir = '_releases'
        output_directory = lang + '/release'
        site.pages << ReleasePage.new(site, site.source, lang, '_releases', src, output_directory)
      end
      #TODO releases are only generated for english language,
      #but they could also be translated at some point. They would however
      #need to fallback to english when no translation is available.
    end
  end

end
