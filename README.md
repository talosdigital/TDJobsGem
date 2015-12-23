# TDJobsGem
#### *A Ruby wrapper for TDJobs.*

This ruby gem wraps the [TDJobs] functionality, making its usage easier. You can improve your
development performance by using this gem, because you will only have to handle with friendly
methods that will do the hard work for you!

## Dependencies
*TDJobsGem* has the following dependencies:
-  [httparty] 0.13.5
-  [activesupport] 4.2.3

## Including it in your project

In order to use this gem in your application, add the following lines to your Gemfile:

```ruby
gem 'td-jobs', git: 'https://github.com/talosdigital/TDJobsGem.git'
```

And then execute:

    $ bundle

## Setup

You are almost ready to use the gem. Before using any *TDJobsGem* method you should perform some
configurations as follows:

- **base_url**: Base URL where your [TDJobs] server is running.
- **application_secret**: Your [TDJobs] application secret (you can set it in the [TDJobs] server
  configuration)

*Example:* ``my_app/config/initializers/td_jobs_gem_config.rb``
```ruby
TD::Jobs.configure do |config|
  config.base_url               = 'http://192.168.59.103:3000/api/v1'
  config.application_secret     = '0m6_7h15_15_v3ry_53cr37'
end
```
## Usage examples
For instance, if you want to create a **Job**, you could use the following methods:

```ruby
job = TD::Jobs::Job.new(name: "My job",
                        description: "My job description",
                        owner_id: 51,
                        invitation_only: true)
job.create
```
The above command lines are equivalent to:
```ruby
TD::Jobs::Job.create(name: "My job",
                     description: "My job description",
                     owner_id: 51,
                     invitation_only: true)
```

There are multiple methods that could be used with an instance besides the class, for example,
the *create* method for **Invitation**, **Job**, and **Offer**

You can also run all methods using the *Ruby* console or by executing `bin/console`.

## Documentation

To see a list and descriptions of every method you have to generate the documentation by running
 `$ yardoc server`. Then use your favorite browser to access and read it. Every method specifies
 its parameters and the return values.

[TDJobs]: https://github.com/talosdigital/TDJobs
[httparty]: https://github.com/jnunemaker/httparty
[activesupport]: https://rubygems.org/gems/activesupport/versions/4.2.3
