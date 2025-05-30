# Whoop Agentic Analytics Demo -- Builder Keynote Summit 2025

1. Run setup/01_db_setup.sql in a [worksheet](https://app.snowflake.com/_deeplink/worksheets?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote){:target="_blank"} 
2. [Upload](https://app.snowflake.com/_deeplink/#/data/add-data?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote){:target="_blank"}  all PDF files inside data/ to WHOOP.PUBLIC.PDFS stage.
3. [Upload](https://app.snowflake.com/_deeplink/#/data/add-data?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote){:target="_blank"}  data/locker_data.csv to WHOOP.PUBLIC.RAW_DATA stage
4. [Upload](https://app.snowflake.com/_deeplink/#/data/add-data?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote){:target="_blank"}  sample_semantic_model.yaml to WHOOP.PUBLIC.SEMANTIC_MODELS stage
5. Run setup/02_load_data_setup_services.sql in a [worksheet](https://app.snowflake.com/_deeplink/worksheets?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote){:target="_blank"} 
6. Create a [new streamlit app](https://app.snowflake.com/_deeplink/#/streamlit-apps?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote){:target="_blank"}  inside WHOOP.PUBLIC. You can use the default warehouse. 