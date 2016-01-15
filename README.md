# winsw-cookbook
The winsw-cookbook is a library cookbook which provides an LWRP that configures [kohsuke/winsw][winsw]; a wrapper executable that can be used to host any executable as an Windows service.

## <a name="usage"></a> Usage

    winsw 'my_winsw_service' do
      executable 'java'
      args [ '-jar', 'C:\\my_service.jar' ]
    end

## <a name="development"></a> Development

* Source hosted at [GitHub][repo]
* Report issues/Questions/Feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make.

## <a name="license"></a> License and Author

Author:: github1[github1] (<github1@github.com>)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

[github1]:      https://github.com/github1
[repo]:         https://github.com/github1/winsw-cookbook
[issues]:       https://github.com/github1/winsw-cookbook/issues
[winsw]:        https://github.com/kohsuke/winsw
