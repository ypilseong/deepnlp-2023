import autogen

# config_list = autogen.config_list_from_dotenv(
#     # dotenv_file_path="examples/autogen/config.env"
# )
config_list = [
    {
        "model": "mistralai/Mistral-7B-Instruct-v0.1", #the name of your running model
        "api_base": "http://localhost:18881/v1", #the local address of the api
        "api_type": "open_ai",
        "api_key": "NULL", # just a placeholder
    }
]
print("models to use: ", [config_list[i]["model"] for i in range(len(config_list))])

llm_config = {
    "request_timeout": 600,
    "seed": 123,  # for caching and reproducibility
    "config_list": config_list,  # which models to use
    "temperature": 0,  # 0 means no randomness, higher values introduce more randomness
}

agent_assistant = autogen.AssistantAgent(
    name="agent_assistant",
    llm_config=llm_config,
)

agent_proxy = autogen.UserProxyAgent(
    name="agent_proxy",
    human_input_mode="NEVER",  # NEVER, TERMINATE, or ALWAYS
    # TERMINATE - human input needed when assistant sends TERMINATE
    max_consecutive_auto_reply=10,
    is_termination_msg=lambda x: x.get("content", "").rstrip().endswith("TERMINATE"),
    code_execution_config={
        "work_dir": "agent_output",  # path for file output of program
        "use_docker": False,  # True or image name like "python:3" to use docker image
    },
    llm_config=llm_config,
    system_message="""Reply TERMINATE if the task has been solved at full satisfaction.
                      Otherwise, reply CONTINUE, or the reason why the task is not solved yet.""",
)

agent_proxy.initiate_chat(
    agent_assistant,
    message="""I need you to write a python script that will do the following (use requeset and BeautifulSoup):
    Task 1: Navigate to the URL of the [Central bankers' speeches](https://www.bis.org/cbspeeches/index.htm?m=256&cbspeeches_page=1) page.
    Task 2: Initiate a loop to iterate through pages 1 to 10.
    Task 3: On each page, locate the table with class="documentList". Within this table, find all occurrences of the div with class title.
    Task 4: For each occurrence of the title div, extract the text as the title of the speech, and the href attribute as the URL of the speech.
    Task 5: Store the title and URL in a structured format, like a list of dictionaries.
    Task 6: Ensure that no more than 100 entries are collected.
    Task 7: Print the collected data to the screen, displaying the title and URL of each speech.
    """,
)
