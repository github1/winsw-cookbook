# winsw-cookbook
Provides a 'winsw' resource capable of configuring [kohsuke/winsw][winsw]; a wrapper executable that can be used to host any executable as an Windows service.

## <a name="usage"></a> Usage

    winsw 'my_winsw_service' do
      executable 'java'
      args [ '-jar', 'C:\\my_service.jar' ]
    end

## <a name="development"></a> Development

* Source hosted at [GitHub][repo]
* Report issues/Questions/Feature requests on [GitHub Issues][issues]

[github1]:      https://github.com/github1
[repo]:         https://github.com/github1/winsw-cookbook
[issues]:       https://github.com/github1/winsw-cookbook/issues
[winsw]:        https://github.com/kohsuke/winsw
