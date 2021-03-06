Pod::Spec.new do |s|
  s.name                  = "DPFileDownloader"
  s.version               = "1.0.3"
  s.summary               = "iOS 7-9, OSX 10.9-10.11 Compatible NSURLSession File Downloader"
  s.author                = { "Yusuke SUGAMIYA" => "yusuke.dnpp@gmail.com" }
  s.homepage              = "https://github.com/dnpp73/DPFileDownloader"
  s.source                = { :git => "https://github.com/dnpp73/DPFileDownloader.git", :tag => "#{s.version}" }
  s.ios.source_files      = 'DPDiskUtil/**/*.{h,m}', 'DPFileDownloader/**/*.{h,m}', 'DPFileExplorer/**/*.{h,m}'
  s.osx.source_files      = 'DPDiskUtil/**/*.{h,m}', 'DPFileDownloader/**/*.{h,m}'
  s.ios.resources         = 'DPFileExplorer/**/*.{xib,storyboard}'
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'
  s.requires_arc          = true

  s.dependency 'DPUTIUtil'

  s.license = {
   :type => 'MIT',
   :text => <<-LICENSE
   Copyright (c) 2015 dnpp.org

   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
   LICENSE
  }
end
