# Tuppari client for Ruby

## About Tuppari

[Tuppari](http://hakobera.github.com/tuppari/) is an experimental implementation of unbreakable message broadcasting system using WebSocket and Amazon Web Services by [@hakobera](https://github.com/hakobera).

https://github.com/hakobera/tuppari

https://github.com/hakobera/tuppari-servers


## Tuppari for Ruby developers 

You can easily build a Tuppari application by just using Ruby API. Let's get started now!

### Gemfile

Prepare Gemfile as follows.

```ruby
source 'https://rubygems.org'

gem 'tuppari'
```

### Getting Started

And then invoke `bundle console` to try Tuppari.

```ruby
require 'tuppari'

Tuppari.create_account(YOUR_ID, PASSWORD)

tuppari = Tuppari.login(YOUR_ID, PASSWORD)

application = tuppari.create_application('first-tuppari')

open('tuppari.html', 'w') do |f|
  html = <<"EOF"
<html>
  <head>
  <script src="http://cdn.tuppari.com/0.2.0/tuppari.min.js"></script>
  <script>
    var client, channel;
    client = tuppari.createClient({applicationId: '#{application.id}'});
    channel = client.subscribe('ch');
    channel.bind('update', function (msg) {
      console.log(msg);
    });
  </script>
  </head>
  <body>Check JavaScript console.</body>
</html>
EOF
  f.write(html)
end

#
# [notice] Please open this 'tuppari.html' file in browser.
#

tuppari.application = application # or tuppari.load_application_by_name('first-tuppari') 

tuppari.publish_message(
  :channel => 'ch',
  :event => 'update',
  :message => "Hello, Tuppari! (#{Time.now})"
)
```

### Publishing messages without account authentication

Tuppari account authentication is not needed for publishing messages. And following values for the target application are required.

- application_id
- access_key_id (for the application)
- access_secret_key (for the application)

```ruby
application = Tuppari::Application.new(
  :id                => '4032236d-699a-4599-9405-xxxxxxxxxxxx', 
  :access_key_id     => 'b49049f9-e055-4fa5-925b-xxxxxxxxxxxx', 
  :access_secret_key => 'c01a3a31-92cd-4bf9-a238-xxxxxxxxxxxx'
) # or application = tuppari.get_application('first-tuppari') 

Tuppari.publish_message(
  :application => application,
  :channel => 'ch',
  :event => 'update',
  :message => "Hello, Tuppari! (#{Time.now})"
)
```

