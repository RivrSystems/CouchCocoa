Pod::Spec.new do |s|
version = '2.0.3'

s.name     = 'CouchCocoa'
s.version  = version
s.license  = { :type => 'Apache', :text => 'Released under the Apache license, version 2.0.' }
s.summary  = 'Objective-C API for CouchDB on iOS and Mac OS.'
s.homepage = 'https://github.com/couchbaselabs/CouchCocoa'
s.author   = { 'Jens Alfke' => 'jens@couchbase.com' }


s.platform = :ios

s.source   = { :git => 'https://github.com/RivrSystems/CouchCocoa.git', :tag => "v#{version}" }

s.source_files = 'Couch/**/*.*', 'Model', 'REST/**/*', 'UI/iOS', 'Vendor/**/*.{h,m}'
s.compiler_flags = '-DCOUCHCOCOA_IMPL'
end
