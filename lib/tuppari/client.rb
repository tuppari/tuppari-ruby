# -*- encoding: utf-8 -*-

require 'logger'
require 'time'
require 'json'
require 'rest_client'

require 'tuppari'

module Tuppari
  class Client

    attr_accessor :account_name, :account_secret, :application, :log

    def initialize(params = {})
      @log = Logger.new(params[:log_output] || STDOUT)
      @log.level = params[:log_level] || Logger::INFO
      @account_name = params[:account_name]
      @account_secret = params[:account_secret]
      setup_application(params)
    end

    def load_application_by_name(application_name)
      setup_application({:application_name => application_name})
      self
    end

    def create_account(account_name, password)
      body = JSON.unparse({"accountName" => account_name, "password" => password})
      begin
        RestClient.post(Tuppari::ServerURL::ACCOUNTS_REGISTER, body, :content_type => :json)
      rescue RestClient::Exception => e
        @log.warn("Failed to create a new Tuppari account (#{e}, #{e.http_body})")
        raise e
      rescue Exception => e
        @log.warn("Failed to create a new Tuppari account (#{e})")
        raise e
      end
    end

    def login(account_name, password)
      body = JSON.unparse({:accountName => account_name, :password => password})
      begin
        body = RestClient.post(Tuppari::ServerURL::ACCOUNTS_AUTH, body, :content_type => :json)
        credentials = JSON.parse(body)['credentials']
        @account_name = credentials['id']
        @account_secret = credentials['secret']
        @log.debug {
          "Authenticated tuppari user (account_name:#{@account_name}, account_secret:#{@account_secret})"
        }
      rescue RestClient::Exception => e
        @log.warn("Failed to authenticate your Tuppari account (#{e}, #{e.http_body})")
        raise e
      rescue Exception => e
        @log.warn("Failed to authenticate your Tuppari account (#{e})")
        raise e
      end
      self
    end

    def is_authenticated?
      !@account_name.nil? && !@account_secret.nil?
    end

    def create_application(application_name)
      unless is_authenticated?
        raise Tuppari::AuthenticationError.new("Call #authenticate(account_name, password) before.")
      end

      time = Time.now
      headers = headers('CreateApplication', time)
      body_params = {:applicationName => application_name.to_s}
      auth_header = Tuppari::Auth.create_authorization_header(
          :id => @account_name,
          :secret => @account_secret,
          :method => 'POST',
          :uri => Tuppari::ServerURL::APPLICATIONS,
          :host => 'api.tuppari.com',
          :query_string => '',
          :headers => headers,
          :body_params => body_params,
          :request_time => time
      )
      begin
        body = RestClient.post(Tuppari::ServerURL::APPLICATIONS,
                               JSON.unparse(body_params),
                               headers.merge(:authorization => auth_header))
        @log.debug {
          "create_application response: #{body}"
        }
        @log.info {
          "Tuppari application is created. (#{application_name})"
        }
        response = JSON.parse(body)
        Tuppari::Application.new(
            :name => response['applicationName'],
            :id => response['applicationId'],
            :access_key_id => response['accessKeyId'],
            :access_secret_key => response['accessSecretKey']
        )
      rescue RestClient::Exception => e
        @log.warn("Failed to create a new Tuppari application (#{e}, #{e.http_body})")
        raise e
      rescue Exception => e
        @log.warn("Failed to create a new Tuppari application (#{e})")
        raise e
      end
    end

    def delete_application(application_name)
      unless is_authenticated?
        raise Tuppari::AuthenticationError.new("Call #authenticate(account_name, password) before.")
      end

      time = Time.now
      headers = headers('DeleteApplication', time)
      body_params = {:applicationName => application_name}
      auth_header = Tuppari::Auth.create_authorization_header(
          :id => @account_name,
          :secret => @account_secret,
          :method => 'POST',
          :uri => Tuppari::ServerURL::APPLICATIONS,
          :host => 'api.tuppari.com',
          :query_string => '',
          :headers => headers,
          :body_params => body_params,
          :request_time => time
      )
      begin
        RestClient.post(Tuppari::ServerURL::APPLICATIONS,
                        JSON.unparse(body_params),
                        headers.merge(:authorization => auth_header))
        @log.info {
          "Tuppari application is deleted. (#{application_name})"
        }
      rescue RestClient::Exception => e
        @log.warn("Failed to delete a Tuppari application (#{e}, #{e.http_body})")
        raise e
      rescue Exception => e
        @log.warn("Failed to delete a Tuppari application (#{e})")
        raise e
      end
      nil
    end

    def get_application(application_name)
      get_application_list().find { |app| app.name == application_name }
    end

    def get_application_list()
      unless is_authenticated?
        raise Tuppari::AuthenticationError.new("Call #authenticate(account_name, password) before.")
      end

      time = Time.now
      headers = headers('ListApplication', time)
      body_params = {}
      auth_header = Tuppari::Auth.create_authorization_header(
          :id => @account_name,
          :secret => @account_secret,
          :method => 'POST',
          :uri => Tuppari::ServerURL::APPLICATIONS,
          :host => 'api.tuppari.com',
          :query_string => '',
          :headers => headers,
          :body_params => body_params,
          :request_time => time
      )
      begin
        body = RestClient.post(Tuppari::ServerURL::APPLICATIONS,
                               JSON.unparse(body_params),
                               headers.merge(:authorization => auth_header))
        @log.debug {
          "get_application_list response: #{response}"
        }
        JSON.parse(body).to_a.map { |name, app|
          Tuppari::Application.new(
              :name => app['name'],
              :id => app['applicationId'],
              :access_key_id => app['accessKeyId'],
              :access_secret_key => app['accessSecretKey']
          )
        }
      rescue RestClient::Exception => e
        @log.warn("Failed to get the Tuppari application list (#{e}, #{e.http_body})")
        raise e
      rescue Exception => e
        @log.warn("Failed to get the Tuppari application list (#{e})")
        raise e
      end
    end

    def publish_message(params)

      setup_application(params)
      if @application.nil?
        raise Tuppari::ClientError.new("Specify Tuppari application to publish messages.")
      end

      channel = params[:channel]
      event = params[:event]
      message = params[:message]

      time = Time.now
      headers = headers('PublishMessage', time)
      body_params = {
          :applicationId => @application.id,
          :channel => channel,
          :event => event,
          :message => message
      }
      auth_header = Tuppari::Auth.create_authorization_header(
          :id => @application.access_key_id,
          :secret => @application.access_secret_key,
          :method => 'POST',
          :uri => Tuppari::ServerURL::MESSAGES,
          :host => 'api.tuppari.com',
          :query_string => '',
          :headers => headers,
          :body_params => body_params,
          :request_time => time
      )
      begin
        body = RestClient.post(Tuppari::ServerURL::MESSAGES,
                               JSON.unparse(body_params),
                               headers.merge(:authorization => auth_header))
        @log.debug {
          "Tuppari message has been sent. (#{@application.id},#{channel},#{event},#{message})"
        }
        JSON.parse(body)
      rescue RestClient::Exception => e
        @log.warn {
          "Failed to publish a Tuppari message (#{e}, #{e.http_body}, application_id:#{@application.id}, " +
              "channel:#{channel}, event:#{event}, message:#{message})"
        }
        raise e
      rescue Exception => e
        @log.warn {
          "Failed to publish a Tuppari message (#{e}, application_id:#{@application.id}, " +
              "channel:#{channel}, event:#{event}, message:#{message})"
        }
        raise e
      end
    end

    def get_service_info()
      begin
        body = RestClient.get(Tuppari::ServerURL::INFO, 'Content-type' => 'application/json')
        JSON.parse(body)
      rescue RestClient::Exception => e
        @log.warn("Failed to get the Tuppari service info (#{e}, #{e.http_body})")
        raise e
      rescue Exception => e
        @log.warn("Failed to get the Tuppari service info (#{e})")
        raise e
      end
    end

    protected

    def setup_application(params)
      if !params[:application].nil?
        app = params[:application]
        if app.is_a? Tuppari::Application
          @application = app
        else
          raise Tuppari::ClientError.new("application should be a Tuppari::Application object.")
        end
      elsif !params[:application_name].nil?
        application_name = params[:application_name]
        application = get_application_list().find { |app| app.name == application_name }
        if application.nil?
          raise Tuppari::ClientError.new("Application is not found (application_name: #{application_name})")
        else
          @application = application
        end
      end
    end

    def headers(operation, time)
      {
          'Host' => 'api.tuppari.com',
          'Content-type' => 'application/json',
          'X-Tuppari-Date' => time.gmtime.rfc2822,
          'X-Tuppari-Operation' => operation
      }
    end

  end
end