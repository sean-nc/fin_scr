require 'mechanize'

module SearchService
  class << self

    def run
      @agent = Mechanize.new()
      @agent.user_agent = Mechanize::AGENT_ALIASES.to_a.sample

      term = SearchTerm.where(searched: false)
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
            google_form = page.form_with(name: 'f') || page.forms.first
            google_form.q = search_term.query
            page = @agent.submit(google_form)
          end

          loop_through_results(page, search_term)

        rescue Mechanize::ResponseCodeError
          p '503 error'
          %x[rake heroku_restart]
          return
        end
      end
    end

    def loop_through_results(page, search_term)
      @page = page
      @url = ''

      for i in 0..10
        p 'Sleeping...'
        r_num = rand(5..10)
        sleep r_num
        p i

        @agent.user_agent = Mechanize::AGENT_ALIASES.to_a.sample

        titles = []
        emails = []

        @page.search('.r').each do |title|
          title = title.text.split(' | ')[0]
          titles.push(title)
        end

        @page.search('.st').each do |el|
          el = el.text.downcase.gsub(/\n/,'')
          email = el.match(/[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+/)
          emails.push(email)
        end

        data = (merge_data(titles,emails))
        save_data(data)

        url = get_url
        page_number = get_page_number(url)
        add_bookmark(search_term)

        next_link = @page.link_with(:text => 'Next') || @page.link_with(:text => "#{page_number + 1}")

        unless next_link
          search_term.searched = true
          search_term.save
          break
        end

        p "NEXT LINK: "
        p next_link
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

    def add_bookmark(search_term)
      url = get_url
      page = get_page_number(url)

      if search_term.bookmark.blank?
        search_term.create_bookmark(page_number: page,
                                    url: url)

      else
        search_term.bookmark.update_attributes(page_number: page,
                                               url: url)
      end
    end

    def get_url
      @agent.current_page.uri.to_s
    end

    def get_page_number(url)
      match = url.match(/start=(\d*)/)
      match = match.to_a[1].to_i
      page = match/10 + 1
      page ||= 1
    end
  end
end
