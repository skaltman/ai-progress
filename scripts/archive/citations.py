import scholarly
import pyarrow.parquet as pq
import pandas as pd
from os import path

# Parameters
path_data = "data/papers.parquet"
path_out = "data/papers_scholar.parquet"
dir_out = "data"
columns = ['id_scholar', 
           'title',
           'author',
           'citations', 
           'journal', 
           'year', 
           'unique']

# ==============================================================================

titles = pq.read_table(path_data, columns  = ['id', 'title', 'authors']).to_pandas()
titles = titles[0:10]
papers_scholar = pd.DataFrame(columns = columns, index = titles['id'])

def get_scholar_data(title):
  result = list(scholarly.search_pubs_query(title))
  first_result = result[0].fill()
  bib_info = first_result.bib
  
  paper_dict = {
    "id_scholar": bib_info.get('ID'),
    "title": bib_info.get('title'),
    "author": bib_info.get('author'),
    "citations": first_result.citedby,
    "journal": bib_info.get('journal'),
    "year": bib_info.get('year'),
    "unique": len(result) == 1
  }
  
  
  
  papers_scholar[id] = pd.Series(paper_dict)
  
  return paper_dict


papers_scholar_dict = {
  id:get_scholar_data(title) for id, title in zip(titles['id'], titles['title'])
}

papers_scholar = pd.DataFrame.from_dict(papers_scholar_dict, orient = 'index')
papers_scholar.index.name = 'id'

papers_scholar.to_parquet(path_out)
