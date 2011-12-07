#
# Author:: Steven Danna (<steve@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Knife::CookbookSiteInstall do
  before(:each) do
    require 'chef/knife/core/cookbook_scm_repo'
    @knife = Chef::Knife::CookbookSiteInstall.new
    @knife.config = {}
    @install_path = "/var/tmp/chef"
    @knife.config[:cookbook_path] = [ @install_path ]

    @stdout = StringIO.new
    @stderr = StringIO.new
    @knife.stub!(:stderr).and_return(@stdout)
    @knife.stub!(:stdout).and_return(@stdout)

    #Assume all external commands would have succeed. :(
    @knife.stub!(:shell_out!).and_return(true)

    #CookbookSiteDownload Stup
    @downloader = {}
    @knife.stub!(:download_cookbook_to).and_return(@downloader)
    @downloader.stub!(:version).and_return do
      if @knife.name_args.size == 2
        @knife.name_args[1]
      else
        "0.3.0"
      end
    end

    #Stubs for CookbookSCMRepo
    @repo = {}
    Chef::Knife::CookbookSCMRepo.stub!(:new).and_return(@repo)
    @repo.stub!(:sanity_check).and_return(true)
    @repo.stub!(:reset_to_default_state).and_return(true)
    @repo.stub!(:prepare_to_import).and_return(true)
    @repo.stub!(:finalize_updates_to).and_return(true)
    @repo.stub!(:merge_updates_from).and_return(true)
  end


  describe "run" do

    it "should return an error if a cookbook name is not provided" do
      @knife.name_args = []

      @knife.ui.should_receive(:error).with("Please specify a cookbook to download and install.")
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    it "should return an error if more than two arguments are given" do
      @knife.name_args = ["foo", "bar", "baz"]
      @knife.ui.should_receive(:error).with("Installing multiple cookbooks at once is not supported.")
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    it "should return an error if the second argument is not a version" do
      @knife.name_args = ["getting-started", "1pass"]
      @knife.ui.should_receive(:error).with("Installing multiple cookbooks at once is not supported.")
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    it "should install the specified version if a specific version is given" do
      @knife.name_args = ["getting-started", "0.1.0"]
      @knife.config[:no_deps] = true
      upstream_file = File.join(@install_path, "getting-started.tar.gz")
      @knife.should_receive(:download_cookbook_to).with(upstream_file)
      @knife.should_receive(:extract_cookbook).with(upstream_file, "0.1.0")
      @knife.should_receive(:clear_existing_files).with(File.join(@install_path, "getting-started"))
      @repo.should_receive(:merge_updates_from).with("getting-started", "0.1.0")
      @knife.run
    end

    it "should install the latest version if only a cookbook name is given" do
      @knife.name_args = ["getting-started"]
      @knife.config[:no_deps] = true
      upstream_file = File.join(@install_path, "getting-started.tar.gz")
      @knife.should_receive(:download_cookbook_to).with(upstream_file)
      @knife.should_receive(:extract_cookbook).with(upstream_file, "0.3.0")
      @knife.should_receive(:clear_existing_files).with(File.join(@install_path, "getting-started"))
      @repo.should_receive(:merge_updates_from).with("getting-started", "0.3.0")
      @knife.run
    end
  end
end
