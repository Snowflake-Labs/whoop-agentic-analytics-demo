# Import python packages
import streamlit as st
import json
import _snowflake 
from datetime import datetime
from snowflake.snowpark.context import get_active_session

session = get_active_session()


def llm_agent(PROMPT, MODEL='claude-3-5-sonnet'):

    payload = {
        "model": MODEL,
        "response_instruction": "You will always maintain a friendly tone and provide a concise response. Use text to sql first where possible.",
        "experimental": {},
        "tools": [
            
          {
            "tool_spec": {
                "name": "pdf_search",
                "type": "cortex_search"
            }
        }, 
          {
            "tool_spec": {
                "name": "locker_search",
                "type": "cortex_search"
            }
        }, 
          {
             "tool_spec": {
                 "name": "user_analytics",
                 "type": "cortex_analyst_text_to_sql"
             } 
          }
        ],
        "tool_resources": {
          
            "pdf_search":{
                "name": "WHOOP.DOCUMENTS.PDF_SEARCH",
                "id_column": "relative_path",
                "scoring_config": {"reranker": "none"}
            }, 
            "locker_search":{
                "name": "WHOOP.DOCUMENTS.LOCKER_SEARCH",
                "id_column": "publication_id",
                "filter": {
                    "@and": [
                        { "@gte": { "publication_date": "2022-01-01" } },
                        { "@lte": { "publication_date": str(datetime.today().strftime('%Y-%m-%d')) } }
                    ]
                }
            },
            "user_analytics": {
                "semantic_model_file": "@WHOOP.USERS.STAGE/sample_semantic_view.yaml"
            }
        },
        "tool_choice": {
            "type": "auto"
        },
        "messages": [
            {
                "role": "user",
                "content": [
                {
                    "type": "text",
                    "text": PROMPT
                }
                ]
            }
            ]
        }
    
    return payload

def api_call(PAYLOAD, API_ENDPOINT):
    
    response = _snowflake.send_snow_api_request(
            "POST",  # method
            API_ENDPOINT,  # path
            {},  # headers
            {},  # params
            PAYLOAD,  # body
            None,  # request_guid
            1000,  # timeout in milliseconds,
        )
        
    return response

def process_sse_response(response):
    """Process SSE response"""
    text = ""
    sql = ""
    citations = []
    tools_used = []
    tool_name = ""
    
    if not response:
        return text, sql, citations, tools_used
    if isinstance(response, str):
        return text, sql, citations, tools_used
    try:
        for event in response:
            if event.get('event') == "message.delta":
                data = event.get('data', {})
                delta = data.get('delta', {})
                
                for content_item in delta.get('content', []):
                    content_type = content_item.get('type')
                    if content_type == "tool_use":
                        tool_name = content_item["tool_use"]["name"]
                        tools_used.append(tool_name)
                    if content_type == "tool_results":
                        tool_results = content_item.get('tool_results', {})
                        if 'content' in tool_results:
                            for result in tool_results['content']:
                                if result.get('type') == 'json':
                                    text += result.get('json', {}).get('text', '')
                                    search_results = result.get('json', {}).get('searchResults', [])
                                    for search_result in search_results:
                                        citations.append({'source_id':search_result.get('source_id',''), 'doc_id':search_result.get('doc_id', '')})
                                    sql = result.get('json', {}).get('sql', '')
                    if content_type == 'text':
                        text += content_item.get('text', '')
                        
        
                            
    except json.JSONDecodeError as e:
        st.error(f"Error processing events: {str(e)}")
                
    except Exception as e:
        st.error(f"Error processing events: {str(e)}")
        
    return text, sql, citations, tools_used

def run_snowflake_query(query):

    try:
        df = session.sql(query.replace(';',''))
        
        return df

    except Exception as e:
        st.error(f"Error executing SQL: {str(e)}")
        return None, None

def new_conversation(model_choice):
     st.session_state.messages = [{"role": "assistant", "content": "Hi. I'm a Knowledge Agent with access to public data about Whoop. I'm using `"+model_choice+"`. Ask me anything!"}]
     st.rerun()

def display_sidebar():

    # Sidebar for new chat
    with st.sidebar:

        st.title("Agentic Analytics @ Whoop")
        
        
        st.session_state.model_choice = st.selectbox(
            "What LLM would you like to use?",
            ('claude-3-5-sonnet', 'mistral-large2', 'llama3.3-70b','llama3.1-70b'),
            index=0,
            placeholder='claude-3-5-sonnet'
        )

        st.caption('Select a model then click the button below to start a new conversation with your model choice.')

        if st.button("Start a new conversation", key="new_chat"):
            new_conversation(st.session_state.model_choice)   

        st.session_state.debug_mode = st.checkbox("Debug Mode")

        st.subheader("About")
        st.caption('This is a sample app built by [Snowflake](https://snowflake.com/) in partnership with [Whoop](https://www.whoop.com/) to demonstrate how customers leverage [Snowflake Agents REST API](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-rest-api).')

def main():

    display_sidebar()
    
    icons = {
        "assistant": "https://raw.githubusercontent.com/streamlit/snowflake-arctic-st-demo/refs/heads/main/Snowflake_Logomark_blue.svg",
        "user": "⛷️"
    }
    
    # Initialize session state
    if 'messages' not in st.session_state:
        st.session_state.messages = [{"role": "assistant", "content": "Hi. I'm a Knowledge Agent with access to public data about Whoop. . I'm using `"+st.session_state.model_choice+"`. Ask me anything!"}]

    for message in st.session_state.messages:
        with st.chat_message(message['role'], avatar=icons[message["role"]]):
            st.write(message['content'])

    if query := st.chat_input("Would you like to learn?"):
        # Add user message to chat
        with st.chat_message("user", avatar=icons['user']):
            st.markdown(query)
        st.session_state.messages.append({"role": "user", "content": query})
        
        # Get response from API
        with st.spinner("Thinking..."):
            payload = llm_agent(query, st.session_state.model_choice)
            response = api_call(payload,'/api/v2/cortex/agent:run')

        with st.spinner("Parsing..."):
            #st.write(response)
            #st.json(response['content'])
            try: 
                if response['content']:
                    text, sql, citations, tools_used = process_sse_response(json.loads(response['content']))  
            except:
                skip
                
            # Add assistant response to chat                
            with st.chat_message("assistant", avatar=icons['assistant']):

                if "【†" in text and citations:
                    citation_title = "\n\n **Citations:** \n\n"
                    text += citation_title
                    for citation in citations:
                        doc_id = citation['doc_id']
                        source_id = citation['source_id']
                        citation_text = '- [' + str(source_id) + '] '+ str(doc_id) + '\n'
                        text += citation_text

                if text:
                    text = text.replace("【†", "[")
                    text = text.replace("†】", "]")

                st.markdown(text)

                st.session_state.messages.append({"role": "assistant", "content": text})

                
                #Display and execute SQL if present
                if sql:
                    st.code(sql, language="sql")                            
                    st.session_state.messages.append({"role": "assistant", "content": sql})
                    results = run_snowflake_query(sql)
                    if results:
                        st.write(results)
        
            if st.session_state.debug_mode: 
                if len(tools_used)>0:
                    st.info('Tools used: `' + str(tools_used) + '`', icon=':material/info:')
                else:  
                    st.info('Tools used: `' + st.session_state.model_choice+ '`', icon=':material/info:')

            
if __name__ == "__main__":
    main()
