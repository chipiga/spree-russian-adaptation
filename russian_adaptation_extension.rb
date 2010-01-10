# encoding: utf-8
# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class RussianAdaptationExtension < Spree::Extension
  version "0.1"
  description "Adapts Spree to the Russian reality."
  url "http://github.com/romul/spree-russian-adaptation"

  # Please use russian_adaptation/config/routes.rb instead for extension routes.

  def self.require_gems(config)
    config.gem 'yaroslav-russian', :lib => 'russian', :source => 'http://gems.github.com'
  end

  def activate
    
    Time::DATE_FORMATS[:date_time24] = "%d.%m.%Y - %H:%M"
    Time::DATE_FORMATS[:short_date] = "%d.%m.%Y"
    
    require "active_merchant/billing/gateways/robo_kassa"
    Gateway::RoboKassa.register
    
    # replace .to_url method provided by stringx gem by .parameterize provided by russian gem
    String.class_eval do
      def to_url
        self.parameterize
      end
   	end


    OrdersController.class_eval do
      def sberbank_billing
        if (@order.shipping_method.name =~ /предопл/ && can_access?)
          render :layout => false
        else
          flash[:notice] = 'Счёт не найден.'
          redirect_to root_path
        end
      end     
    end

    Gateway.class_eval do
      def self.current
        self.first :conditions => ["environment = ? AND active = ?", RAILS_ENV, true]
      end
    end

    Checkout.class_eval do
      validation_group :address, :fields=> [
      "shipment.address.firstname", "shipment.address.lastname", "shipment.address.phone", 
      "shipment.address.zipcode", "shipment.address.state", "shipment.address.lastname", 
      "shipment.address.address1", "shipment.address.city", "shipment.address.statename", 
      "shipment.address.zipcode", "shipment.address.secondname"]
  
      def bill_address
        shipment ? shipment.address : Address.default
      end
    end
    
    Checkout.state_machines[:state] =
        StateMachine::Machine.new(Checkout, :initial => 'address') do
          after_transition :to => 'complete', :do => :complete_order   
          event :next do
            transition :to => 'delivery', :from  => 'address'
            transition :to => 'complete', :from => 'delivery'
          end
        end

    Spree::BaseHelper.module_eval do
      def number_to_currency(number, options = {})
        rub = number.to_i
        kop = ((number - rub)*100).round.to_i
        if (kop > 0)
          "#{rub}&nbsp;p.&nbsp;#{'%.2d' % kop}&nbsp;коп.".mb_chars
        else
          "#{rub}&nbsp;p.".mb_chars
        end
      end
    end
    
    Admin::BaseHelper.module_eval do 
      def text_area(object_name, method, options = {})
        begin
          fckeditor_textarea(object_name, method,
            :toolbarSet => 'Spree', :width => '100%', :height => '350px')
        rescue
          super
        end
      end      
    end

    # admin.tabs.add "Russian Adaptation", "/admin/russian_adaptation", :after => "Layouts", :visibility => [:all]
  end
end

