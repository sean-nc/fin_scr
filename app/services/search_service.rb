require 'mechanize'

module SearchService
  class << self

    def run
      @agent = Mechanize.new()
      @agent.user_agent = Mechanize::AGENT_ALIASES.to_a.sample

      term = SearchTerm.all.where(searched: false)
      # order terms?

      term.each do |search_term|
        if search_term.searched
          next
        end

        begin
          if search_term.bookmark && search_term.bookmark.url
            page = @agent.get(search_term.bookmark.url)
          else
            page = @agent.get('https://google.ca/')
            google_form = page.form_with(name: 'f') || page.form_with(name: 'q')
            google_form.q = search_term.query
            page = @agent.submit(google_form)
          end

          # delete below?

          # unless search_term.bookmark.blank? || search_term.bookmark.page_number == 1
          #   page_number = search_term.bookmark.page_number
          #   page_link = page.link_with(text: "#{page_number}")

          #   if page_link.blank?
          #     url.searched = true
          #     url.save
          #   else
          #     page = page_link.click
          #     p "going to page #{page_number}"
          #   end
          # end

          # delete above?

          loop_through_results(page, search_term)

        rescue Mechanize::ResponseCodeError
          p '503 error'
          %x[rake heroku_restart]
          return
        rescue
          next
        end
      end
    end

    def loop_through_results(page, search_term)
      @page = page
      @url = ''

      for i in 0..10
        p 'Sleeping...'
        r_num = rand(1..2)
        sleep r_num
        p i

        @agent.user_agent = Mechanize::AGENT_ALIASES.to_a.sample

        titles = []
        emails = []

        r_num2 = rand(0..1)
        r_num3 = rand(0..1)

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

        next_link = @page.link_with(:text => 'Next') || @page.link_with(id: 'pnnext')

        unless next_link
          search_term.searched = true
          search_term.save
          break
        end

        p "NEXT LINK: "
        p @page.link_with(:text => 'Next')
        @page = next_link.click
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
      url = @agent.current_page.uri.to_s

      if search_term.bookmark.blank?
        page_number = current_page + 1
        page_number += 1 if page_number == 1
        search_term.create_bookmark(page_number: page_number,
                                    url: url)

      else
        page_number = search_term.bookmark.page_number + 1
        search_term.bookmark.update_attributes(page_number: page_number,
                                               url: url)
      end
    end
  end
end
