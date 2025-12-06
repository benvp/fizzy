module Fizzy
  class << self
    def saas?
      return @saas if defined?(@saas)
      @saas = !!(((ENV["SAAS"] || File.exist?(File.expand_path("../tmp/saas.txt", __dir__))) && ENV["SAAS"] != "false"))
    end

    def db_adapter
      @db_adapter ||= DbAdapter.new ENV.fetch("DATABASE_ADAPTER", saas? ? "mysql" : "sqlite")
    end

    def signup_domain_restricted?
      allowed_signup_domains.any?
    end

    def allowed_signup_domains
      return @allowed_signup_domains if defined?(@allowed_signup_domains)
      domains_str = ENV["ALLOWED_SIGNUP_DOMAINS"] || ""
      @allowed_signup_domains = domains_str.split(",").map(&:strip).reject(&:empty?)
    end

    def configure_bundle
      if saas?
        ENV["BUNDLE_GEMFILE"] = "Gemfile.saas"
      end
    end
  end

  class DbAdapter
    def initialize(name)
      @name = name.to_s
    end

    def to_s
      @name
    end

    # Not using inquiry so that it works before Rails env loads.
    def sqlite?
      @name == "sqlite"
    end
  end
end
