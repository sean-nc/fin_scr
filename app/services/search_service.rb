require 'mechanize'

module SearchService
  class << self

    def run
      @agent = Mechanize.new()
      @agent.user_agent = Mechanize::AGENT_ALIASES.to_a.sample

      term = SearchTerm.all

      term.each do |url|
        next if url.searched
        page = @agent.get('https://google.ca/')
        google_form = page.form('f')
        google_form.q = url.query
        page = @agent.submit(google_form)

        profile_count = Profile.count

        loop_through_results(page)

        if Profile.count > profile_count
          url.update(searched: true)
        end
      end

    end

    def loop_through_results(page)
      @page = page
      @url = ''

      for i in 0..10
        p 'Sleeping...'
        r_num = rand(20..40)
        sleep r_num
        p i

        @agent.user_agent = Mechanize::AGENT_ALIASES.to_a.sample

        titles = []
        emails = []

        r_num2 = rand(0..2)
        r_num3 = rand(0..2)

        @page.search('.r').each do |title|
          title = title.text.split(' | ')[0]
          titles.push(title)
          sleep r_num2
        end
        @page.search('.st').each do |el|
          el = el.text.downcase.gsub(/\n/,'')
          email = el.match(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+/)
          emails.push(email)
          sleep r_num3
        end

        data = (merge_data(titles,emails))
        save_data(data)

        begin
          next_button = @page.link_with(:text => 'Next')

          if next_button == true
            @page = @page.link_with(:text => 'Next').click
          else
            break
          end

        rescue
          break
        end
      end
      data
    end

    def merge_data(titles,emails)
      data = []
      titles.each_with_index do |title,index|
        h = {}
        email = emails[index] || '---'
        h[:email] = email[0]
        h[:title] = title
        data.push(h)
        p h
      end
      data
    end

    def save_data(data)
      data.each do |entry|
        if entry[:email].match(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+/)
          Profile.create(email: entry[:email],
                         title: entry[:title])
        end
      end
    end
  end
end


# module SearchService
#   class << self

#     def run
#       options = Selenium::WebDriver::Chrome::Options.new
#       options.add_argument('--headless')
#       driver = Selenium::WebDriver.for :chrome, options: options

      # term = SearchTerm.all

      # term.each do |url|
      #   next if url.searched
      #   driver.navigate.to "https://google.ca/"
      #   element = driver.find_element(name: 'q')
      #   element.send_keys url.query
      #   element.submit

      #   profile_count = Profiles.count

      #   get_page_results(driver)

      #   if Profile.count > profile_count
      #     url.update(searched: true)
      #   end
      # end

#       driver.quit
#     end

#     def get_page_results(driver)
#       p "starting get_page_results for #{driver.current_url}"

#       for i in 0..10
#         p i

#         page_source = Nokogiri::HTML.parse(driver.page_source)

#         r_num = rand(10..30)

#         sleep r_num

#         titles = []
#         emails = []

#         r_num2 = rand(0..2)
#         r_num3 = rand(0..2)

#         page_source.search('.r').each do |title|
#           title = title.text.split(' | ')[0]
#           titles.push(title)
#           sleep r_num2
#         end

#         page_source.search('.st').each do |el|
#           el = el.text.downcase.gsub(/\n/,'')
#           email = el.match(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+/)
#           emails.push(email)
#           sleep r_num3
#         end

#         p "starting merge_data"

#         data = (merge_data(titles,emails))

#         p "starting save_data"

#         save_data(data)

#         begin
#           next_button = driver.find_element(id: 'pnnext')

#           if next_button == true
#             driver.find_element(id: 'pnnext').click
#           else
#             break
#           end

#         rescue
#           break
#         end
#       end
#     end


#     def merge_data(titles,emails)
#       data = []
#       titles.each_with_index do |title,index|
#         h = {}
#         email = emails[index] || '---'
#         h[:email] = email[0]
#         h[:title] = title
#         data.push(h)
#         p h
#       end
#       data
#     end

#     def save_data(data)
#       data.each do |entry|
#         if entry[:email].match(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+/)
#           Profile.create(email: entry[:email],
#                          title: entry[:title])
#         end
#       end
#     end
#   end
# end
