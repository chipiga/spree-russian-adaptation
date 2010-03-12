begin
  RUSSIAN_CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'settings.yml'))
rescue
  RUSSIAN_CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'settings.yml.example'))
end

Time.zone = RUSSIAN_CONFIG['country']['timezone']
I18n.default_locale = :'ru-RU'
locale = File.join(File.dirname(__FILE__), '..', 'locales', RUSSIAN_CONFIG['country']['id'], 'ru-RU_extend.yml')
I18n.load_path << locale if File.exists?(locale) and !I18n.load_path.include?(locale)

if Spree::Config.instance
  Spree::Config.set(:default_locale => :'ru-RU')
  Spree::Config.set(:default_country_id => RUSSIAN_CONFIG['country']['id'])
  Spree::Config.set(:auto_capture => false)
  Spree::Config.set(:ship_form_requires_state => true)
end

# Put into initializer to avoid 'stack level to deep' problem
ActionView::Helpers::NumberHelper.module_eval do
  def number_to_currency_with_kopek(number, options = {})
    if I18n.locale == I18n.default_locale
      options.symbolize_keys!
      default = RUSSIAN_CONFIG['finance']['show_zero_kopek'] # TODO
      show_zero_kopek = options.delete(:show_zero_kopek) || default
      
      if (number - number.floor).zero? and !show_zero_kopek
        options.merge!(:precision => 0) # нет копеек
      else
        options.merge!(:format => "%n коп.", :separator => " %u ") # есть копейки
      end
    end
    number_to_currency_without_kopek(number, options) 
  end
  alias_method_chain :number_to_currency, :kopek
end

# ActiveMerchant::Billing::Base.mode = (RAILS_ENV == 'production') ? :live : :test
