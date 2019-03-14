import urllib3
from bs4 import BeautifulSoup

url = 'https://en.wikipedia.org/wiki/Of_Human_Bondage'
http = urllib3.PoolManager()
response = http.request('GET', url)
soup = BeautifulSoup(response.data, 'html.parser')
bodyText = soup.find('div', {'id' : 'bodyContent'}).text
words = bodyText.split(' ')
wordCount = {}
for word in words:
    word = word.lower()
    word = word.strip(',')
    word = word.strip('\"')
    if word in wordCount:
        wordCount[word] += 1
    else:
        wordCount[word] = 1

for key, value in sorted(wordCount.items(), key=lambda kv: kv[1]):
    print(key + ' : ', value)