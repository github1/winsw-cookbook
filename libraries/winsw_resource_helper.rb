module WinSW
  module ResourceHelper
    def build_start_resource(name)
      service_exec = new_resource.service_exec
      execute name do
        command "#{service_exec} start"
        only_if self.status_is(service_exec, :stopped)
      end
    end
    def build_stop_resource(name)
      service_exec = new_resource.service_exec
      windows_service_name = new_resource.windows_service_name
      execute name do
        command "net stop \"#{windows_service_name}\" stop"
        only_if self.status_is(service_exec, :started)
      end
    end
    def build_restart_resource(name)
      service_exec = new_resource.service_exec
      execute name do
        command "#{service_exec} restart"
        not_if self.status_is(service_exec, :non_existent)
      end
    end
    def status_is(service_exec, status)
      status_text = case status
                      when :non_existent then
                        'NonExistent'
                      when :stopped then
                        'Stopped'
                      when :started then
                        'Started'
                      else
                        status.to_s
                    end
      "#{service_exec} status | %systemroot%\\system32\\find.exe /i \"#{status_text}\""
    end
  end
end