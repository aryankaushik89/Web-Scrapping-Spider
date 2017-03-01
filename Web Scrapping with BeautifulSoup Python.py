
import urllib
from bs4 import BeautifulSoup
from urllib.parse import urlparse
import mechanize #upto python 2.7 only




# Set website to be scrapped
	
url = "http://github.com"
# set the a mechanize browser object
br = mechanize.Browser()
	

# create lists for the urls in que and visited urls
urls = [url]
visited = [url]
	

	
while len(urls)>0:
    try:
        br.open(urls[0])
        urls.pop(0)
        for link in br.links():
            newurl =  urlparse.urljoin(link.base_url,link.url)
            #print newurl
            if newurl not in visited and url in newurl:
                visited.append(newurl)
                urls.append(newurl)
                print (newurl)
    except:
        print ("error")
        urls.pop(0)
       
print (visited)


