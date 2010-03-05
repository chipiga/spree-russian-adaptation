begin
  RUSSIAN_CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'settings.yml'))
rescue
  RUSSIAN_CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'settings.yml.example'))
end

Time.zone = RUSSIAN_CONFIG['country']['timezone']
I18n.default_locale = :'ru-RU'

if Spree::Config.instance
  Spree::Config.set(:default_locale => :'ru-RU')
  Spree::Config.set(:default_country_id => RUSSIAN_CONFIG['country']['id'])
  Spree::Config.set(:auto_capture => false)
  Spree::Config.set(:ship_form_requires_state => true)
end
