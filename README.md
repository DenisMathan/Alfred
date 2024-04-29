# Alfred

## Chatbot
- grabs embeddings stored in ChromaDB
- implements it into the Prompt
- the Chatbot answers with the Answer you want already in the Prompt


## Perception (not finished)
- REads data From data.json
- Scrapes the URLS Defined
- clusters the String into smaller parts
- stores the parts into chromaDB

## Setup
- Download your llm as a .gguf and store it in the folder llms
- insert your llm-path in alfred.py
- Adjust the Prompt in alfred.py if necessary
- setup the data.json
- run Perception.py
- run alfred.py
- Now you can let alfred correct things you input as strings
