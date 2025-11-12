module BrandingHelper
  def app_name(case_type = :default)
    base_name = ENV.fetch('APP_NAME', 'Chatwoot')

    case case_type.to_sym
    when :uppercase, :upcase, :caps
      base_name.upcase
    when :lowercase, :downcase
      base_name.downcase
    when :titlecase, :title
      base_name.titlecase
    when :capitalize, :cap
      base_name.capitalize
    else
      base_name
    end
  end

  # Convenience methods for common cases
  def app_name_upcase
    app_name(:uppercase)
  end

  def app_name_downcase
    app_name(:lowercase)
  end

  def app_name_titlecase
    app_name(:titlecase)
  end

  def app_name_capitalize
    app_name(:capitalize)
  end
end
