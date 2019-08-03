module RedisConfig
  extend self

  def init
    @config = YAML.load(ERB.new(File.read(Rails.root.join('config', 'redis.yml'))).result)[Rails.env]
  end

  def config
    @config
  end

  def config_for(service)
    init unless @config
    @config.merge(@config[:services][service] || {})
  end
end
