# -*- encoding: utf-8 -*-

require 'openssl'
require 'digest'
require 'json'

module Tuppari
  module Auth

    def self.create_canonical_uri(uri)
      if %r{^http(s)*://}.match(uri)
        uri.sub(%r{^http(s)*://[^/]+/}, '/')
      elsif %r{^[^/]}.match(uri)
        "/#{uri}"
      else
        uri
      end
    end

    def self.create_canonical_query_string(query_string)
      if query_string.nil?
        ''
      else
        query_string.split("&").sort_by { |e| e.split("=").first }.join('&')
      end
    end

    def self.create_canonical_headers(headers)
      if headers.nil?
        ''
      else
        downcase_keys(headers).to_a.sort_by { |k, v| k }.map { |k, v| "#{k}:#{v}" }.join("\n")
      end
    end

    def self.create_signed_headers(headers)
      if headers.nil?
        ''
      else
        downcase_keys(headers).to_a.sort_by { |k, v| k }.map { |k, v| k }.join(';')
      end
    end

    def self.create_body_hash(body_params)
      sha256 = Digest::SHA256.new
      digest = sha256.digest(JSON.unparse(body_params))
      Digest.hexencode(digest)
    end

    def self.create_canonical_request(method, uri, query_string, headers, body_params)
      request = []
      request << method
      request << create_canonical_uri(uri)
      request << create_canonical_query_string(query_string)
      request << create_canonical_headers(headers)
      request << create_signed_headers(headers)
      request << create_body_hash(body_params)
      request.join("\n")
    end

    def self.create_string_to_sign(canonical_request, request_time)
      result = []
      result << "SHA256"
      result << request_time.gmtime.strftime("%Y%m%dT%H%M%SZ")
      sha256 = Digest::SHA256.new
      digest = sha256.digest(canonical_request)
      result << Digest.hexencode(digest)
      result.join("\n")
    end

    def self.create_signature(secret, string_to_sign, request_time, host)
      signing_key = create_hmac_hash_value(create_hmac_hash_value("TUPPARI#{secret}", request_time.gmtime.strftime("%Y%m%dT%H%M%SZ")), host)
      create_hmac_hash_value(signing_key, string_to_sign)
    end

    def self.create_authorization_header(params)
      id = params[:id]
      secret = params[:secret]
      method = params[:method] || 'POST'
      uri = params[:uri]
      host = params[:host] || 'api.tuppari.com'
      query_string = params[:query_string] || ''
      headers = params[:headers] || {}
      body_params = params[:body_params] || {}
      request_time = params[:request_time] || Time.now

      signed_headers = create_signed_headers(headers)
      canonical_request = create_canonical_request(method, uri, query_string, headers, body_params)
      string_to_sign = create_string_to_sign(canonical_request, request_time)
      signature = create_signature(secret, string_to_sign, request_time, host)
      "HMAC-SHA256 Credential=#{id},SignedHeaders=#{signed_headers},Signature=#{signature}"
    end

    protected

    def self.downcase_keys(headers)
      headers.each_with_object({}) { |(k, v), hash|
        hash[k.downcase] = v
      }
    end

    def self.create_hmac_hash_value(key, data)
      OpenSSL::HMAC.hexdigest('sha256', key, data)
    end

  end
end