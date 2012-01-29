#
# Copyright (C) 2011 Onyx Point, Inc. <http://onyxpoint.com/>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include Puppet::Util::Diff

Puppet::Type.newtype(:concat_fragment) do
  @doc = "Create a concat fragment"

  newproperty(:content) do

    def retrieve
      return resource[:content]
    end

    def insync?(is)
      group = @resource[:name].split('+').first
      fragment = @resource[:name].split('+')[1..-1].join('+')
      frag_file = "/var/lib/puppet/concat/fragments/#{group}/#{fragment}"

      if File.exist?(frag_file)
        data = File.read(frag_file)
        if data == @resource[:content] then
          debug "Disk contents differ from resource content for #{@resource[:name]}"
          return true
        end
      else
        return false
      end
    end

    def sync
      provider.create
    end

    def change_to_s(currentvalue, newvalue)
      "executed successfully"
    end
  end

  newparam(:name) do
    isnamevar
    validate do |value|
      fail Puppet::Error, "name is missing group or name. Name format must be 'group+fragment_name'" if value !~ /.+\+.+/
      fail Puppet::Error, "name cannot include '../'!" if value =~ /\.\.\//
    end
  end

  # This is only here because, at this point, we can be sure that the catalog
  # has been compiled. This checks to see if we have a concat_build specified
  # for our particular concat_fragment group.
  autorequire(:file) do
    if catalog.resources.find_all { |r| r.is_a?(Puppet::Type.type(:concat_build)) and r[:name] == self[:name].split('+').first }.empty? then
      err "No 'concat_build' specified for group #{self[:name].split('+').first}!"
    end
    ""
  end

  validate do
    fail Puppet::Error, "You must specify content" unless self[:content]
  end
end
