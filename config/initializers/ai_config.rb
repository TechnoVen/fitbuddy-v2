module AIConfig
  def self.load_config
    @config ||= begin
      path = Rails.root.join('config', 'ai.yml')
      if File.exist?(path)
        # Enable aliases to allow YAML anchors (used for default values)
        YAML.load_file(path, aliases: true)[Rails.env] || {}
      else
        {}
      end
    end
  end

  def self.system_prompt
    load_config && (@config['system_prompt'] || @config[:system_prompt])
  end
end
