module GHI
  module Commands
    class Show < Command
      attr_accessor :patch, :web

      def options
        OptionParser.new do |opts|
          opts.banner = 'usage: ghi show <issueno>'
          opts.separator ''
          opts.on('-p', '--patch') { self.patch = true }
          opts.on('-w', '--web') { self.web = true }
        end
      end

      def execute
        require_issue
        require_repo
        options.parse! args
        patch_path = "pull/#{issue}.patch" if patch # URI also in API...
        if web
          Web.new(repo).open patch_path || "issues/#{issue}"
        else
          if patch_path
            i = throb { Web.new(repo).curl patch_path }
            page do
              puts i
              break
            end
          else
            i = throb { api.get "/repos/#{repo}/issues/#{issue}" }.body
            page do
              puts format_issue(i)
              n = i['comments']
              if n > 0
                puts "#{n} comment#{'s' unless n == 1}:\n\n"
                Comment.execute %W(-l #{issue} -- #{repo})
              end
              break
            end
          end
        end
      end
    end
  end
end
