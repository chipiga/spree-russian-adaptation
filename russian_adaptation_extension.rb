# encoding: utf-8
# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class RussianAdaptationExtension < Spree::Extension
  version "1.0"
  description "Adapts Spree to the Russian reality."
  url "http://github.com/romul/spree-russian-adaptation"

  # Please use russian_adaptation/config/routes.rb instead for extension routes.

  def self.require_gems(config)
    config.gem 'russian', :lib => 'russian', :source => 'http://gemcutter.org'
    config.gem 'prawn'
  end

  def activate
    
    Time::DATE_FORMATS[:date_time24] = "%d.%m.%Y - %H:%M"
    Time::DATE_FORMATS[:short_date] = "%d.%m.%Y"
        
    # replace .to_url method provided by stringx gem by .parameterize provided by russian gem
    String.class_eval do
      def to_url
        self.parameterize
      end
   	end

    [PaymentMethod::Cash, PaymentMethod::Bank, Billing::RoboKassa].each {|m| m.register}
    
    # TODO remove this brutal hack
    # Gateway.class_eval do
    #   def self.current
    #     new
    #   end
    # end
    
    Checkout.class_eval do
      validation_group :address, :fields=> [
      "ship_address.firstname", "ship_address.lastname", "ship_address.phone", 
      "ship_address.zipcode", "ship_address.state", "ship_address.lastname", 
      "ship_address.address1", "ship_address.city", "ship_address.statename", 
      "ship_address.zipcode", "ship_address.secondname"]
  
      def bill_address
        ship_address || Address.default
      end
    end
        
    Admin::BaseHelper.module_eval do 
      def text_area(object_name, method, options = {})
        begin
          ckeditor_textarea(object_name, method, :width => '100%', :height => '350px')
        rescue
          super
        end
      end      
    end

    OrdersController.class_eval do
      def receipt
        render :layout => false
      end
      def invoice
        render :layout => false
      end
    end
    
    Admin::OrdersController.class_eval do
      def waybill
        load_object
      end
      def cash_memo
        load_object
      end
    end

    # TODO Contribute and delete
    Admin::PaymentsController.class_eval do
      def build_object
        @object = model.new(object_params)
        @object.payable = parent_object.checkout
        @payment = @object
        if current_gateway and current_gateway.payment_profiles_supported? and params[:card].present? and params[:card] != 'new'
          @object.source = Creditcard.find_by_id(params[:card])
        end
        @object
      end
    end
    
    # TODO Contribute and delete
    CheckoutsController.class_eval do
      def object_params
        # For payment step, filter checkout parameters to produce the expected nested attributes for a single payment and its source, discarding attributes for payment methods other than the one selected
        if object.payment?
          if params.has_key?(:payment_source) and source_params = params.delete(:payment_source)[params[:checkout][:payments_attributes].first[:payment_method_id].underscore]
            params[:checkout][:payments_attributes].first[:source_attributes] = source_params
          end
          params[:checkout][:payments_attributes].first[:amount] = @order.total
        end
        params[:checkout]
      end
    end

  end
end

