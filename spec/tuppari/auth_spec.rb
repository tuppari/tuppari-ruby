# -*- encoding: utf-8 -*-

require 'tuppari'

describe Tuppari::Auth do

  it "should have correct #create_canonical_uri" do
    Tuppari::Auth.create_canonical_uri('foo/bar').should eq('/foo/bar')
    Tuppari::Auth.create_canonical_uri('/foo/bar').should eq('/foo/bar')
    Tuppari::Auth.create_canonical_uri('http://www.google.com/foo/bar').should eq('/foo/bar')
  end

  it "should have correct #create_canonical_query_string" do
    Tuppari::Auth.create_canonical_query_string(nil).should eq('')
    Tuppari::Auth.create_canonical_query_string('').should eq('')
    Tuppari::Auth.create_canonical_query_string('a=b').should eq('a=b')
    Tuppari::Auth.create_canonical_query_string('a=b&c=d').should eq('a=b&c=d')
    Tuppari::Auth.create_canonical_query_string('c=d&a=b').should eq('a=b&c=d')
    Tuppari::Auth.create_canonical_query_string('c=d&a=b&c=e').should eq('a=b&c=d&c=e')
  end

  it "should have correct #create_canonical_headers" do
    Tuppari::Auth.create_canonical_headers(nil).should eq('')
    Tuppari::Auth.create_canonical_headers({}).should eq('')

    headers = {
        'X-Tuppari-Operation' => 'CreateApplication',
        'Content-type' => 'application/json',
        'Host' => 'api.tuppari.com'
    }
    Tuppari::Auth.create_canonical_headers(headers).should eq("content-type:application/json\nhost:api.tuppari.com\nx-tuppari-operation:CreateApplication")
  end

  it "should have correct #create_signed_headers" do
    Tuppari::Auth.create_signed_headers(nil).should eq('')
    Tuppari::Auth.create_signed_headers({}).should eq('')

    headers = {
        'X-Tuppari-Operation' => 'CreateApplication',
        'Content-type' => 'application/json',
        'Host' => 'api.tuppari.com'
    }
    Tuppari::Auth.create_signed_headers(headers).should eq('content-type;host;x-tuppari-operation')
  end

  it 'should have correct #create_body_hash' do
    Tuppari::Auth.create_body_hash({'a' => 'b', 'c' => 'd'}).should eq('b85c7da93e8790518898c280e15e3f1af5d46bf4aaa4407690f0f0a3b0316478')
  end

  it 'should have correct #create_canonical_request' do
    headers = {
        'X-Tuppari-Operation' => 'CreateApplication',
        'Content-type' => 'application/json',
        'Host' => 'api.tuppari.com'
    }
    body_params = {'applicationName' => 'example1'}
    request = Tuppari::Auth.create_canonical_request('POST', '/test', 'b=v2&a=v1', headers, body_params)

    request.should eq("POST\n" +
                          "/test\n" +
                          "a=v1&b=v2\n" +
                          "content-type:application/json\n" +
                          "host:api.tuppari.com\n" +
                          "x-tuppari-operation:CreateApplication\n" +
                          "content-type;host;x-tuppari-operation\n" +
                          "8f2d5fe4a93000d3546e578d265fc936806f6ef6dc6f7ee87715e1a5c514c168")
  end

  it 'should have correct #create_string_to_sign' do
    request = "POST\n" +
        "/test\n" +
        "a=v1&b=v2\n" +
        "content-type:application/json\n" +
        "host:api.tuppari.com\n" +
        "x-tuppari-operation:CreateApplication\n" +
        "content-type;host;x-tuppari-operation\n" +
        "8f2d5fe4a93000d3546e578d265fc936806f6ef6dc6f7ee87715e1a5c514c168"
    Tuppari::Auth.create_string_to_sign(request, Time.new(2011, 2, 3, 4, 5, 6)).should(
        eq("SHA256\n" +"20110202T190506Z\n" +"152176000cc08c7d9d0558bc3a50368aa38619a695ad20f50bec1344429cb315"))

  end

  it 'should have correct #create_signature' do
    secret = 'secretKey1'
    string_to_sign = "SHA256\n" +
        "19700101T000000Z\n" +
        "152176000cc08c7d9d0558bc3a50368aa38619a695ad20f50bec1344429cb315"
    time = Time.new(1970, 1, 1, 0, 0, 0, "+00:00")
    host = 'api.tuppari.com'
    expected_signature = '4815ff1681a278e7c852902ea3604f17831a80a78dc0ff82f5142598a034509b'
    (1...1000).each do |i|
      signature = Tuppari::Auth.create_signature(secret, string_to_sign, time, host)
      signature.should eq(expected_signature)
    end

    secret2 = 'secretKey2'
    signature1 = Tuppari::Auth.create_signature(secret, string_to_sign, time, host)
    signature2 = Tuppari::Auth.create_signature(secret2, string_to_sign, time, host)
    signature2.should_not eq(signature1)
  end

  it 'should have correct #create_authorization_header' do
    header = Tuppari::Auth.create_authorization_header(
        :id => 'accessKeyId',
        :secret => 'accessSecretKey',
        :method => 'POST',
        :host => 'api.tuppari.com',
        :uri => '/test',
        :query_string => 'a=v1&b=v2',
        :headers => {
            'Host' => 'api.tuppari.com',
            'Content-Type' => 'application/json',
            'X-Tuppari-Operation' => 'CreateApplication'
        },
        :body_params => {
            'applicationName' => 'example1'
        },
        :request_time => Time.new(1970, 1, 1, 0, 0, 0, "+00:00")
    )
    header.should eq("HMAC-SHA256 Credential=accessKeyId,SignedHeaders=content-type;host;x-tuppari-operation,Signature=050f8711271747d4f63a3caa3ffb420e4cd5a0e9d9dda8ba7e4faad6794c40d0")
  end

  it 'should have correct #create_hmac_hash_value' do
    result = Tuppari::Auth.create_hmac_hash_value('123', 'abc')
    result.should eq('8f16771f9f8851b26f4d460fa17de93e2711c7e51337cb8a608a0f81e1c1b6ae')
  end

end