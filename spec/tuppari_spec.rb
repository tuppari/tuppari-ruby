# -*- encoding: utf-8 -*-

require 'tuppari'

require 'logger'
require 'ruby-debug'

describe Tuppari do

  account_name = ENV['TUPPARI_ACCOUNT_NAME']
  password = ENV['TUPPARI_PASSWORD']

=begin

  it "should create a new account" do
    tuppari = Tuppari.new()
    response = tuppari.create_account("account_name", "password")
    puts response
  end

  it "should create a new account" do
    tuppari = Tuppari.new(:account_name => account_name, :account_secret => account_secret)
    response = tuppari.delete_application("application_name")
    puts response
  end

=end

  it "should be created with account_name/account_secret" do
    tuppari = Tuppari.new(
        :account_name => account_name,
        :account_secret => Tuppari.login(account_name, password).account_secret
    )
    tuppari.is_authenticated?.should eq(true)
  end

  it "should login" do
    tuppari = Tuppari.new()
    tuppari.is_authenticated?.should eq(false)
    tuppari.login(account_name, password)
    tuppari.is_authenticated?.should eq(true)
  end

  it "should raise Tuppari::AuthenticationError when creating a new applications without authentication" do
    tuppari = Tuppari.new()
    name = Time.now.tv_sec.to_s
    begin
      tuppari.create_application(name)
      fail()
    rescue Tuppari::AuthenticationError
    end
  end

  it "should create a new application" do
    tuppari = Tuppari.new(:log_level => Logger::WARN).login(account_name, password)
    name = Time.now.tv_sec.to_s
    app = tuppari.create_application(name)
    app.name.should eq(name)
    app.id.nil?.should eq(false)
    app.access_key_id.nil?.should eq(false)
    app.access_secret_key.nil?.should eq(false)
  end

  it "should raise Tuppari::AuthenticationError when getting my application list without authentication" do
    tuppari = Tuppari.new()
    begin
      tuppari.get_application_list()
      fail()
    rescue Tuppari::AuthenticationError
    end
  end

  it "should get my application list" do
    tuppari = Tuppari.new(:log_level => Logger::WARN).login(account_name, password)
    response = tuppari.get_application_list()
    response.size.should > 0
  end

  it "should raise Tuppari::AuthenticationError when publishing messages without authentication" do
    tuppari = Tuppari.new()
    begin
      response = tuppari.publish_message(
          :application_name => 'tuppari-sample',
          :channel => 'channel_name',
          :event => 'event_name',
          :message => 'Hello, Tuppari!'
      )
      fail()
    rescue Tuppari::AuthenticationError
    end
  end


  it "should publish messages" do
    tuppari = Tuppari.new(:log_level => Logger::WARN).login(account_name, password)
    response = tuppari.publish_message(
        :application_name => 'tuppari-sample',
        :channel => 'channel_name',
        :event => 'event_name',
        :message => 'Hello, Tuppari!'
    )
    response.size.should > 0
  end

  it "should get the service info" do
    info = Tuppari.new().get_service_info()
    info['name'].should eq("gyoji")
    info['version'].nil?.should eq(false)
  end

end