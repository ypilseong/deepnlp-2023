# filename: scrape_speeches.py

import requests
from bs4 import BeautifulSoup

# Initialize an empty list to store the speeches
speeches = []

# Iterate through pages 1 to 10
for page in range(1, 11):
    # Navigate to the URL of the Central bankers' speeches page
    url = f"https://www.bis.org/cbspeeches/index.htm?m=256&cbspeeches_page={page}"
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')

    # Locate the table with class="documentList"
    document_list = soup.find('table', {'class': 'documentList'})

    # If the table is not found, skip this page
    if document_list is None:
        print(f"Could not find the document list on page {page}. Skipping this page.")
        continue

    # Find all occurrences of the div with class title
    titles = document_list.find_all('div', {'class': 'title'})

    # For each occurrence of the title div, extract the text and the href attribute
    for title in titles:
        # Ensure that no more than 100 entries are collected
        if len(speeches) >= 100:
            break

        # Extract the text as the title of the speech
        speech_title = title.text.strip()

        # Extract the href attribute as the URL of the speech
        speech_url = title.find('a')['href']

        # Store the title and URL in a structured format
        speeches.append({
            'title': speech_title,
            'url': f"https://www.bis.org{speech_url}"
        })

    # If we've collected 100 entries, break the loop
    if len(speeches) >= 100:
        break

# Print the collected data to the screen
for speech in speeches:
    print(f"Title: {speech['title']}\nURL: {speech['url']}\n")