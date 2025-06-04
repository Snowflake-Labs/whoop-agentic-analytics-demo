# Whoop Agentic Analytics Demo -- Builder Keynote Summit 2025

1. Run `setup/01_db_setup.sql` in a <a href="https://app.snowflake.com/_deeplink/worksheets?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote" target="_blank">worksheet</a> 
2. <a href="https://app.snowflake.com/_deeplink/#/data/add-data?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote" target="_blank">Upload</a> all PDF files inside the `data/` folder to `WHOOP.PUBLIC.PDFS` stage.
3. <a href="https://app.snowflake.com/_deeplink/#/data/add-data?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote" target="_blank">Upload all CSVs in</a> `data/` to `WHOOP.PUBLIC.RAW_DATA` stage
4. <a href="https://app.snowflake.com/_deeplink/#/data/add-data?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote" target="_blank">Upload</a> `sample_semantic_model.yaml` to `WHOOP.PUBLIC.SEMANTIC_MODELS` stage
5. Run `setup/02_load_data_setup_services.sql` in a <a href="https://app.snowflake.com/_deeplink/worksheets?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote" target="_blank">worksheet</a> 
6. Create a <a href="https://app.snowflake.com/_deeplink/#/streamlit-apps?utm_source=snowflake&utm_medium=github&utm_campaign=summit25builderkeynote" target="_blank">new streamlit app</a> inside `WHOOP.PUBLIC` and paste in the contents of the entire `sis_app.py` file. Use the `SNOWFLAKE_LEARNING_WH` when creating your Streamlit app.


Prompts to try out: 
* What is HRV?
* Does Whoop use rMSSD or SDNN for HRV calculations?
* How does Whoop track sleep?
* Are supplements correlated with higher energy levels?
* Which is more predictive of high energy levels: caffeine use or morning sunlight?

# License
Copyright (c) Snowflake Inc.  
This project's codebase is licensed under the Apache License 2.0. You can find the full text of this license in the LICENSE file at the root of this repository.

Copyright (c) WHOOP INC.  
The data located in the data/ directory is separately licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0) License. The complete terms of this license are available in the LICENSE-DATA file.
