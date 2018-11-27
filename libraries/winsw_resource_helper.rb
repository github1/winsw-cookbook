module WinSW
  module ResourceHelper
    def build_start_resource(name)
      service_exec = new_resource.service_exec
      execute name do
        command "set \"WINSW_SVC_EXECUTABLE=rem\" && #{service_exec} test && #{service_exec} start"
        only_if self.status_is(service_exec, :stopped)
      end
    end

    def build_stop_resource(name)
      service_exec = new_resource.service_exec
      windows_service_name = new_resource.windows_service_name
      execute name do
        command "net stop \"#{windows_service_name}\""
        only_if self.status_is(service_exec, :started)
      end
    end

    def build_restart_resource(name)
      service_exec = new_resource.service_exec
      execute name do
        command "set \"WINSW_SVC_EXECUTABLE=rem\" && #{service_exec} test && #{service_exec} restart"
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

    def hash_to_xml_s(in_value, format = false, parent_key = '', depth = -1)
      spacing_start = prepare_xml_depth(depth)
      spacing_end = prepare_xml_depth(depth, -1)
      parent_key = parent_key.to_s.gsub(/\${2}__[0-9]+/, '')
      parent_key_start = parent_key == '' ? '' : "#{spacing_start}<#{parent_key}>"
      parent_key_end = parent_key == '' ? '' : "</#{parent_key}>"
      output = ''
      if in_value.is_a?(Hash)
        attributes = in_value
                         .select { |key| key.to_s.match(/^@/) }
        self_closing = attributes.size == in_value.size
        if parent_key != ''
          output = "#{output}#{spacing_start}<#{parent_key}"
        end
        attributes.each do |key, value|
          output = "#{output} #{key.to_s.gsub(/^@/, '')}=\"#{value}\""
        end
        if self_closing
          if parent_key != ''
            output = "#{output}/>"
          end
        else
          if parent_key != ''
            output = "#{output}>"
          end
          in_value
              .select { |key| !attributes.key?(key) }
              .each do |key, value|
            rendered_value = hash_to_xml_s(value, format, key, depth + 1)
            output = "#{output}#{rendered_value}"
          end
          output = "#{output}#{spacing_end}#{parent_key_end}"
        end
      elsif in_value.is_a?(Array)
        output = "#{parent_key_start}#{in_value
                                           .map { |entry| hash_to_xml_s(entry, format, '', depth + 1) }
                                           .join(' ')}#{parent_key_end}"
      else
        output = "#{parent_key_start}#{in_value}#{parent_key_end}"
      end
      parent_key == '' ? output.strip : output
    end

    def prepare_xml_depth(depth, threshold = 0)
      spacing = ''
      while spacing.length < depth
        spacing = " #{spacing}"
      end
      spacing.length > threshold ? "\n#{spacing}" : spacing
    end

    def prepare_config_xml(service_name,
                           service_description,
                           env,
                           executable,
                           arguments,
                           log_mode,
                           custom,
                           extensions = [])
      service_element = {
          :id => service_name,
          :name => service_name,
          :description => service_description,
      }
      service_element[:executable] = executable if executable
      service_element[:arguments] = arguments unless arguments.empty?
      env.each_with_index do |(key, value), index|
        service_element["env$$__#{index}"] = {:@name => key, :@value => value}
      end
      custom_opts = custom.to_h.clone
      custom_opts[:logmode] = log_mode unless custom.key?(:log) || custom.key?(:logmode)
      custom_opts.each do |key, value|
        service_element[key] = value
      end
      extensions.each_with_index do |entry, index|
        service_element[:extensions] = {} unless service_element.key?(:extensions)
        service_element[:extensions]["extension$$__#{index}"] = entry
      end
      hash_to_xml_s({
                        :service => service_element
                    })
    end
  end
end