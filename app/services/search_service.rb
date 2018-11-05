require 'mechanize'


module SearchService
  class << self

    def run
      @agent = Mechanize.new()
      @agent.user_agent = Mechanize::AGENT_ALIASES.to_a.sample

      term = SearchTerm.all.where(searched: false)
      # order terms?

      term.each do |url|
        if url.searched
          next
        end

        begin
          page = @agent.get('https://google.ca/')
          google_form = page.form_with(name: 'f') || page.form_with(name: 'q')
          google_form.q = url.query
          page = @agent.submit(google_form)

          unless url.bookmark.blank? || url.bookmark.page_number == 1
            page_number = url.bookmark.page_number
            bookmark = page.link_with(text: "#{page_number}")

            if bookmark.blank?
              # url.searched = true
              # url.save
            else
              page = bookmark.click
              p "going to page #{page_number}"
            end
          end

          loop_through_results(page, url)

        rescue Mechanize::ResponseCodeError
          p '503 error'
          system("heroku restart")
        rescue
          next
        end
      end
    end

    def loop_through_results(page, search_term)
      @page = page
      @url = ''

      for i in 0..2
        p 'Sleeping...'
        r_num = rand(3..6)
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

        page_number = @page.search('.cur').text.strip.to_i
        add_bookmark(page_number, search_term)


        break if !@page.link_with(:text => 'Next')
        p "NEXT LINK: "
        p @page.link_with(:text => 'Next')
        @page = @page.link_with(:text => 'Next').click
      end
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

    def add_bookmark(current_page, search_term)
      if search_term.bookmark.blank?
        page_number = current_page + 1
        # add check if page number == 1 then 2
        search_term.create_bookmark(page_number: page_number)
      elsif search_term.bookmark.page_number >= 10
        search_term.searched = true
        search_term.save
      else
        page_number = search_term.bookmark.page_number + 1
        search_term.bookmark.update_attributes(page_number: page_number)
      end
    end
  end
end
