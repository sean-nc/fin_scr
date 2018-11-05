search = SearchTerm.create(query: '""@outlook.com"" ""MBA Intern""  ""toronto""-intitle:""profiles""
                           -inurl:""dir/ "" site:linkedin.com/in/ OR site:linkedin.com/pub/ -inurl:jobs""')
search.create_bookmark(page_number: 10)
